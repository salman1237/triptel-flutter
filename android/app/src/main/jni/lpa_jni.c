/*
 * FR-L914: this app's own JNI glue -- implements lpac's
 * `struct euicc_apdu_interface` (euicc/interface.h, LGPL-2.1-only,
 * vendored unmodified under third_party/lpac-euicc/) by calling back
 * up into the Kotlin `co.triptel.app.lpa.LpaBridge` class, which
 * itself drives the already device-verified `CcidTransceiver`/
 * `ApduChannel` (FR-L912/FR-L913). This file is Triptel's own code,
 * not vendored -- see third_party/lpac-euicc/VENDORED.md.
 *
 * Design confirmed against two independent sources before writing a
 * byte of glue code (the FR's own required "interface spike" step):
 *  - euicc/interface.h and euicc/euicc.c (this repo's own vendored
 *    copy) for the real struct shape and what euicc_init()/
 *    euicc_apdu_transmit() actually expect from each callback.
 *  - gitea.angry.im/jmp-sim/jmp-sim-manager's
 *    libs/lpac-jni/src/main/jni/lpac-jni/interface-wrapper.c, a real
 *    shipping JNI bridge to the same euicc/interface.h, independently
 *    confirming the same method shapes (logicalChannelOpen(aid): Int,
 *    logicalChannelClose(channel), transmit(channel, tx): ByteArray).
 */

#include <jni.h>
#include <stdlib.h>
#include <string.h>

#include <cjson-ext/cJSON_ex.h>
#include <cjson/cJSON.h>
#include <euicc/es10c.h>
#include <euicc/es10c_ex.h>
#include <euicc/euicc.h>

static JavaVM *g_vm = NULL;
static jclass g_bridge_class = NULL;
static jmethodID g_method_connect = NULL;
static jmethodID g_method_disconnect = NULL;
static jmethodID g_method_logical_channel_open = NULL;
static jmethodID g_method_logical_channel_close = NULL;
static jmethodID g_method_transmit = NULL;

/* lpac calls back on whatever thread called euicc_init()/es10x
 * commands; that thread already attached to the JVM (it's the one
 * that invoked our own native entry point), so plain GetEnv is enough
 * -- no AttachCurrentThread dance needed here. */
static JNIEnv *get_env(void) {
    JNIEnv *env = NULL;
    (*g_vm)->GetEnv(g_vm, (void **)&env, JNI_VERSION_1_6);
    return env;
}

static void cache_methods_if_needed(JNIEnv *env, jobject bridge) {
    if (g_bridge_class != NULL) return;
    jclass local_class = (*env)->GetObjectClass(env, bridge);
    g_bridge_class = (*env)->NewGlobalRef(env, local_class);
    g_method_connect = (*env)->GetMethodID(env, g_bridge_class, "connect", "()V");
    g_method_disconnect = (*env)->GetMethodID(env, g_bridge_class, "disconnect", "()V");
    g_method_logical_channel_open =
        (*env)->GetMethodID(env, g_bridge_class, "logicalChannelOpen", "([B)I");
    g_method_logical_channel_close =
        (*env)->GetMethodID(env, g_bridge_class, "logicalChannelClose", "(I)V");
    g_method_transmit =
        (*env)->GetMethodID(env, g_bridge_class, "transmit", "(I[B)[B");
}

/* The one open session at a time this app supports (docs/Rules.md:
 * "one card, one in-flight APDU exchange at a time"). */
static jobject g_bridge = NULL;
static int g_current_channel = 0;

static int apdu_connect(struct euicc_ctx *ctx) {
    (void)ctx;
    JNIEnv *env = get_env();
    (*env)->CallVoidMethod(env, g_bridge, g_method_connect);
    if ((*env)->ExceptionCheck(env)) {
        (*env)->ExceptionClear(env);
        return -1;
    }
    return 0;
}

static void apdu_disconnect(struct euicc_ctx *ctx) {
    (void)ctx;
    JNIEnv *env = get_env();
    (*env)->CallVoidMethod(env, g_bridge, g_method_disconnect);
    (*env)->ExceptionClear(env);
}

static int apdu_logic_channel_open(struct euicc_ctx *ctx, const uint8_t *aid, uint8_t aid_len) {
    (void)ctx;
    JNIEnv *env = get_env();
    jbyteArray aid_arr = (*env)->NewByteArray(env, aid_len);
    (*env)->SetByteArrayRegion(env, aid_arr, 0, aid_len, (const jbyte *)aid);
    jint channel = (*env)->CallIntMethod(env, g_bridge, g_method_logical_channel_open, aid_arr);
    (*env)->DeleteLocalRef(env, aid_arr);
    if ((*env)->ExceptionCheck(env)) {
        (*env)->ExceptionClear(env);
        return -1;
    }
    g_current_channel = channel;
    return channel;
}

static void apdu_logic_channel_close(struct euicc_ctx *ctx, uint8_t channel) {
    (void)ctx;
    JNIEnv *env = get_env();
    (*env)->CallVoidMethod(env, g_bridge, g_method_logical_channel_close, (jint)channel);
    (*env)->ExceptionClear(env);
}

static int apdu_transmit(struct euicc_ctx *ctx, uint8_t **rx, uint32_t *rx_len, const uint8_t *tx,
                         uint32_t tx_len) {
    (void)ctx;
    JNIEnv *env = get_env();
    jbyteArray tx_arr = (*env)->NewByteArray(env, (jsize)tx_len);
    (*env)->SetByteArrayRegion(env, tx_arr, 0, (jsize)tx_len, (const jbyte *)tx);
    jbyteArray rx_arr = (jbyteArray)(*env)->CallObjectMethod(
        env, g_bridge, g_method_transmit, (jint)g_current_channel, tx_arr);
    (*env)->DeleteLocalRef(env, tx_arr);
    if ((*env)->ExceptionCheck(env) || rx_arr == NULL) {
        (*env)->ExceptionClear(env);
        return -1;
    }
    jsize len = (*env)->GetArrayLength(env, rx_arr);
    if (len < 2) {
        /* Not even room for SW1SW2 -- euicc_apdu_transmit (interface.c)
         * requires at least 2 bytes; let it reject this explicitly
         * rather than returning a buffer it would misparse. */
        (*env)->DeleteLocalRef(env, rx_arr);
        *rx = NULL;
        *rx_len = 0;
        return 0;
    }
    *rx = (uint8_t *)calloc((size_t)len, 1);
    (*env)->GetByteArrayRegion(env, rx_arr, 0, len, (jbyte *)*rx);
    *rx_len = (uint32_t)len;
    (*env)->DeleteLocalRef(env, rx_arr);
    return 0;
}

static struct euicc_apdu_interface g_apdu_interface = {
    .connect = &apdu_connect,
    .disconnect = &apdu_disconnect,
    .logic_channel_open = &apdu_logic_channel_open,
    .logic_channel_close = &apdu_logic_channel_close,
    .transmit = &apdu_transmit,
    .userdata = NULL,
};

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)reserved;
    g_vm = vm;
    return JNI_VERSION_1_6;
}

/*
 * FR-L914 spike: the done-criterion the FR itself names -- "a real
 * EID read from a real card." Builds a euicc_ctx backed by this
 * file's apdu_interface (which calls back into [bridge]), runs
 * euicc_init() (MANAGE CHANNEL open + SELECT ISD-R, per euicc.c) then
 * es10c_get_eid(), then euicc_fini(). Returns the real EID string, or
 * NULL on any failure (never throws back to Kotlin).
 */
JNIEXPORT jstring JNICALL Java_co_triptel_app_lpa_LpaBridge_nativeReadEid(JNIEnv *env, jobject thiz) {
    cache_methods_if_needed(env, thiz);
    g_bridge = (*env)->NewGlobalRef(env, thiz);

    struct euicc_ctx ctx;
    memset(&ctx, 0, sizeof(ctx));
    ctx.apdu.interface = &g_apdu_interface;

    jstring result = NULL;
    if (euicc_init(&ctx) == 0) {
        char *eid = NULL;
        if (es10c_get_eid(&ctx, &eid) == 0 && eid != NULL) {
            result = (*env)->NewStringUTF(env, eid);
            free(eid);
        }
        euicc_fini(&ctx);
    }

    (*env)->DeleteGlobalRef(env, g_bridge);
    g_bridge = NULL;
    return result;
}

/*
 * FR-L915: the chip-info summary the FR asks for (free memory, SGP.22
 * version) -- SGP.22's `svn` field (es10c_ex_euiccinfo2.svn) *is* the
 * spec version number, per euicc/es10c_ex.c's own comment on tag 0x82.
 * Returned as a small JSON string (cJSON is already linked in via
 * lpac-cjson, see Android.mk) rather than inventing a second ad-hoc
 * serialization just for this one call; Kotlin/Dart parse it.
 * NULL on any failure (device unplugged mid-read included -- the
 * caller distinguishes that from other failures by re-checking
 * UsbManager.deviceList, not from anything this function reports).
 */
JNIEXPORT jstring JNICALL Java_co_triptel_app_lpa_LpaBridge_nativeReadEuiccInfo2(JNIEnv *env, jobject thiz) {
    cache_methods_if_needed(env, thiz);
    g_bridge = (*env)->NewGlobalRef(env, thiz);

    struct euicc_ctx ctx;
    memset(&ctx, 0, sizeof(ctx));
    ctx.apdu.interface = &g_apdu_interface;

    jstring result = NULL;
    if (euicc_init(&ctx) == 0) {
        struct es10c_ex_euiccinfo2 info;
        if (es10c_ex_get_euiccinfo2(&ctx, &info) == 0) {
            cJSON *json = cJSON_CreateObject();
            cJSON_AddStringOrNullToObject(json, "svn", info.svn);
            cJSON_AddNumberToObject(json, "freeNonVolatileMemory",
                                     info.extCardResource.freeNonVolatileMemory);
            cJSON_AddNumberToObject(json, "freeVolatileMemory",
                                     info.extCardResource.freeVolatileMemory);
            char *printed = cJSON_PrintUnformatted(json);
            if (printed != NULL) {
                result = (*env)->NewStringUTF(env, printed);
                free(printed);
            }
            cJSON_Delete(json);
            es10c_ex_euiccinfo2_free(&info);
        }
        euicc_fini(&ctx);
    }

    (*env)->DeleteGlobalRef(env, g_bridge);
    g_bridge = NULL;
    return result;
}

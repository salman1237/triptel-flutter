package co.triptel.app.lpa

import co.triptel.app.ccid.ApduChannel
import co.triptel.app.ccid.ApduResult
import co.triptel.app.ccid.CcidTransceiver

/**
 * FR-L914: the Kotlin side of the JNI bridge to lpac's `euicc/`
 * (LGPL-2.1-only, vendored unmodified under `third_party/lpac-euicc/`,
 * see its `VENDORED.md`). `lpa_jni.c`'s `struct euicc_apdu_interface`
 * calls back into the five methods below on this exact object (the
 * `jobject thiz` the native entry point was invoked on) -- their
 * names/signatures are load-bearing, not just convention; changing
 * them requires changing `lpa_jni.c`'s cached `jmethodID`s too.
 *
 * Every method here runs the real APDU exchange on
 * [transceiver]'s own worker thread via `executor.submit(...).get()`
 * -- blocking the calling (native) thread until it completes, which
 * is safe because the native entry point ([nativeReadEid]) is itself
 * only ever invoked from a background thread (never the Flutter
 * main-thread MethodChannel handler directly -- see the Dart-facing
 * caller), per `docs/Rules.md`'s "one card, one in-flight APDU
 * exchange at a time."
 */
class LpaBridge(private val transceiver: CcidTransceiver) {
    fun connect() {
        // The USB session is already open via UsbCcidReaders.openSession()
        // by the time this bridge exists; nothing further to do.
    }

    fun disconnect() {
        // Session lifetime is owned by UsbCcidReaders, not euicc_fini();
        // nothing to do here either.
    }

    fun logicalChannelOpen(aid: ByteArray): Int = transceiver.executor.submit<Int> {
        val openResult = transceiver.sendApduOnWorker(0, ApduChannel.buildManageChannelOpen())
        val channel = (openResult as? ApduResult.Response)
            ?.takeIf { it.isSuccess && it.data.size == 1 }
            ?.data
            ?.get(0)
            ?.toInt()
            ?.and(0xFF)
            ?: return@submit -1
        val selectResult =
            transceiver.sendApduOnWorker(channel, ApduChannel.buildSelectByAid(channel, aid))
        if (selectResult is ApduResult.Response && selectResult.isSuccess) channel else -1
    }.get()

    fun logicalChannelClose(channel: Int) {
        transceiver.executor.submit {
            transceiver.sendApduOnWorker(channel, ApduChannel.buildManageChannelClose(channel))
        }.get()
    }

    /** [tx] already carries the right channel-encoded CLA (`euicc.c`
     * patches it in before calling this) -- [channel] is passed
     * alongside purely so this method's own `transceiveApdu`-driven
     * chaining (FR-L913, `61xx`/`6Cxx`) builds its GET RESPONSE/resend
     * commands against the same channel. The returned bytes include
     * the trailing SW1SW2 (`euicc_apdu_transmit` in `interface.c`
     * slices them off itself), appended here since
     * [CcidTransceiver.sendApduOnWorker] already splits them out. */
    fun transmit(channel: Int, tx: ByteArray): ByteArray = transceiver.executor.submit<ByteArray> {
        when (val result = transceiver.sendApduOnWorker(channel, tx)) {
            is ApduResult.Response -> result.data + byteArrayOf(result.sw1.toByte(), result.sw2.toByte())
            is ApduResult.Failed -> ByteArray(0)
        }
    }.get()

    /** FR-L914's own "done" criterion: a real EID read from a real
     * card, driven entirely through lpac's `euicc_init()` +
     * `es10c_get_eid()` + `euicc_fini()` (native, `lpa_jni.c`) calling
     * back into the methods above. `null` on any failure -- never
     * throws. */
    external fun nativeReadEid(): String?

    /** FR-L915's chip-info summary: SGP.22 spec version + free memory,
     * via lpac's `es10c_ex_get_euiccinfo2()` (native, `lpa_jni.c`),
     * returned as a small JSON string (`{"svn":..,
     * "freeNonVolatileMemory":..,"freeVolatileMemory":..}`). `null` on
     * any failure -- never throws. */
    external fun nativeReadEuiccInfo2(): String?

    /** FR-L916: lists profiles on the card via lpac's
     * `es10c_get_profiles_info()` (native, `lpa_jni.c`), returned as a
     * JSON array string (one object per profile: `iccid`,
     * `serviceProviderName`, `profileName`, `profileNickname`,
     * `state` ("enabled"|"disabled"|"undefined"), `profileClass`
     * ("test"|"provisioning"|"operational"|"undefined")). `null` on
     * any failure -- never throws. */
    external fun nativeListProfiles(): String?

    companion object {
        init {
            System.loadLibrary("triptel-lpa-jni")
        }
    }
}

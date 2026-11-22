LOCAL_PATH := $(call my-dir)

# FR-L914: build file shape (ndk-build, not CMake) confirmed against a
# real, independently-verified reference implementation
# (gitea.angry.im/jmp-sim/jmp-sim-manager's libs/lpac-jni/src/main/jni,
# see DECISIONS.md 2026-11-19 and third_party/lpac-euicc/VENDORED.md).

define all-c-files-under
$(patsubst $(LOCAL_PATH)/%,%, \
  $(wildcard $(LOCAL_PATH)/$(strip $(1))/*.c) \
 )
endef

LPAC_EUICC_DIR := ../../../../../third_party/lpac-euicc

include $(CLEAR_VARS)
# cJSON + lpac's own small extension to it -- a build-time dependency
# of euicc/es9p.c, MIT-licensed (third_party/lpac-euicc/VENDORED.md),
# even though this app doesn't call the ES9+/HTTP code paths yet.
LOCAL_MODULE := lpac-cjson
LOCAL_C_INCLUDES := \
	$(LOCAL_PATH)/$(LPAC_EUICC_DIR) \
	$(LOCAL_PATH)/$(LPAC_EUICC_DIR)/cjson \
	$(LOCAL_PATH)/$(LPAC_EUICC_DIR)/cjson-ext
LOCAL_SRC_FILES := \
	$(call all-c-files-under, $(LPAC_EUICC_DIR)/cjson) \
	$(call all-c-files-under, $(LPAC_EUICC_DIR)/cjson-ext)
include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)
# lpac's euicc/ (LGPL-2.1-only) -- the actual SGP.22 LPA core, vendored
# unmodified (third_party/lpac-euicc/VENDORED.md). Never the AGPL
# src/driver/ code from the same upstream repo.
LOCAL_MODULE := lpac-euicc
LOCAL_STATIC_LIBRARIES := lpac-cjson
LOCAL_C_INCLUDES := \
	$(LOCAL_PATH)/$(LPAC_EUICC_DIR) \
	$(LOCAL_PATH)/$(LPAC_EUICC_DIR)/cjson \
	$(LOCAL_PATH)/$(LPAC_EUICC_DIR)/cjson-ext
LOCAL_SRC_FILES := \
	$(call all-c-files-under, $(LPAC_EUICC_DIR)/euicc)
include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)
# This app's own JNI glue (not vendored) -- implements
# euicc_apdu_interface by calling back into the already
# device-verified Kotlin CcidTransceiver/ApduChannel (FR-L912/L913).
LOCAL_MODULE := triptel-lpa-jni
LOCAL_STATIC_LIBRARIES := lpac-euicc
LOCAL_C_INCLUDES := \
	$(LOCAL_PATH)/$(LPAC_EUICC_DIR)
LOCAL_SRC_FILES := \
	$(call all-c-files-under, .)
include $(BUILD_SHARED_LIBRARY)

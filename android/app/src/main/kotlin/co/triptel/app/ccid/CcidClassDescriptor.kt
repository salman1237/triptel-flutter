package co.triptel.app.ccid

/**
 * FR-L912's "TPDU-mode quirk list": rather than a hand-maintained
 * per-reader guess table, this decodes the reader's own USB-CCID class
 * descriptor (bDescriptorType 0x21, bLength 0x36/54) out of
 * `UsbDeviceConnection.getRawDescriptors()` to find out, from the
 * reader itself, what exchange level it actually operates at --
 * character, TPDU, or (short/extended) APDU. Pure byte-level parsing,
 * no USB I/O, so it's JVM-unit-testable with a real captured descriptor.
 *
 * `dwFeatures` bit meanings cited from a real, checked source (the
 * Linux kernel's own CCID USB gadget driver header, which defines the
 * same USB-CCID-spec bitfield a reader's descriptor uses):
 * https://android.googlesource.com/kernel/msm/+/android-msm-marlin-3.18-nougat-dr1/drivers/usb/gadget/f_ccid.h
 * -- `CCID_FEATURES_EXC_TPDU = 0x00010000`, `CCID_FEATURES_EXC_SAPDU =
 * 0x00020000`, `CCID_FEATURES_EXC_APDU = 0x00040000`; none of those
 * three bits set means character-level exchange (the header has no
 * separate "character level" constant -- it's the absence of the
 * other three).
 */
enum class CcidExchangeLevel {
    CHARACTER,
    TPDU,
    SHORT_APDU,
    SHORT_AND_EXTENDED_APDU,
}

data class CcidClassDescriptor(
    val bMaxSlotIndex: Int,
    val dwFeatures: Long,
    val dwMaxCCIDMessageLength: Long,
    val exchangeLevel: CcidExchangeLevel,
) {
    companion object {
        private const val DESCRIPTOR_LENGTH = 0x36
        private const val DESCRIPTOR_TYPE = 0x21
        private const val FEATURE_EXC_TPDU = 0x00010000L
        private const val FEATURE_EXC_SAPDU = 0x00020000L
        private const val FEATURE_EXC_APDU = 0x00040000L

        /**
         * Scans a USB configuration descriptor's raw bytes for the
         * first CCID class descriptor. `null` if none is present (not
         * a CCID device, or a malformed descriptor set).
         */
        fun parse(rawDescriptors: ByteArray): CcidClassDescriptor? {
            var offset = 0
            while (offset + 1 < rawDescriptors.size) {
                val length = rawDescriptors[offset].toInt() and 0xFF
                if (length <= 0) break
                val type = rawDescriptors[offset + 1].toInt() and 0xFF
                if (type == DESCRIPTOR_TYPE && length == DESCRIPTOR_LENGTH &&
                    offset + DESCRIPTOR_LENGTH <= rawDescriptors.size
                ) {
                    return parseBlock(rawDescriptors, offset)
                }
                offset += length
            }
            return null
        }

        private fun parseBlock(bytes: ByteArray, start: Int): CcidClassDescriptor {
            fun u8(o: Int) = bytes[start + o].toInt() and 0xFF
            fun u32(o: Int): Long =
                (u8(o).toLong()) or (u8(o + 1).toLong() shl 8) or
                    (u8(o + 2).toLong() shl 16) or (u8(o + 3).toLong() shl 24)

            val bMaxSlotIndex = u8(4)
            val dwFeatures = u32(40)
            val dwMaxCCIDMessageLength = u32(44)
            val exchangeLevel = when {
                (dwFeatures and FEATURE_EXC_APDU) != 0L -> CcidExchangeLevel.SHORT_AND_EXTENDED_APDU
                (dwFeatures and FEATURE_EXC_SAPDU) != 0L -> CcidExchangeLevel.SHORT_APDU
                (dwFeatures and FEATURE_EXC_TPDU) != 0L -> CcidExchangeLevel.TPDU
                else -> CcidExchangeLevel.CHARACTER
            }
            return CcidClassDescriptor(
                bMaxSlotIndex = bMaxSlotIndex,
                dwFeatures = dwFeatures,
                dwMaxCCIDMessageLength = dwMaxCCIDMessageLength,
                exchangeLevel = exchangeLevel,
            )
        }
    }
}

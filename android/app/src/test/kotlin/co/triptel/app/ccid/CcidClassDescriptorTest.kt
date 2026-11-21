package co.triptel.app.ccid

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * FR-L912: JVM unit tests for the CCID class descriptor parser. The
 * fixture is the real USB configuration descriptor captured live
 * 2026-11-22 from the connected reader ("EMV Smartcard Reader") via
 * `UsbDeviceConnection.getRawDescriptors()`, logged by
 * `UsbCcidReaders.openSession()` (`docs/Rules.md`: real recorded
 * transcripts, never invented byte sequences presented as real).
 */
class CcidClassDescriptorTest {
    // Captured live 2026-11-22 -- the full configuration descriptor
    // (device descriptor + config + interfaces + the CCID class
    // descriptor at its real offset + endpoints), exactly as the OS
    // reported it for this reader.
    private val realRawDescriptors = hexToBytes(
        "1201010200000008E32C639520010102000109025D00010100A0" +
            "1909040000030B00000036211001000703000000A00F0000E02E" +
            "000003012A00002C800A005FFE0000000700000000000000BE04" +
            "040010010000FFFF00000001070581030400010705020210000" +
            "007058302100000",
    )

    @Test
    fun `finds and parses the real CCID class descriptor out of the full configuration descriptor`() {
        val descriptor = CcidClassDescriptor.parse(realRawDescriptors)
        assertEquals(0, descriptor?.bMaxSlotIndex)
    }

    @Test
    fun `the real descriptor's dwFeatures decodes to Short-and-Extended APDU exchange level`() {
        // Real dwFeatures = 0x000404BE: bit18 (0x00040000, "Short and
        // Extended APDU level exchange") is set -- this reader does
        // APDU-level exchange, not raw TPDU/character level, so
        // FR-L913's APDU layer can hand it full APDUs directly.
        val descriptor = CcidClassDescriptor.parse(realRawDescriptors)
        assertEquals(0x000404BEL, descriptor?.dwFeatures)
        assertEquals(CcidExchangeLevel.SHORT_AND_EXTENDED_APDU, descriptor?.exchangeLevel)
    }

    @Test
    fun `the real descriptor's dwMaxCCIDMessageLength is a sane, non-zero bound`() {
        val descriptor = CcidClassDescriptor.parse(realRawDescriptors)
        assertEquals(0x110L, descriptor?.dwMaxCCIDMessageLength) // 272 bytes
    }

    @Test
    fun `a device with no CCID descriptor at all returns null, not a crash`() {
        // A minimal, structurally-valid-but-unrelated descriptor set
        // (just a device descriptor, no CCID class descriptor) --
        // constructed to exercise the not-found path, not a live
        // capture of any particular device.
        val noCcid = hexToBytes("120101020000000800000000000000000102")
        assertNull(CcidClassDescriptor.parse(noCcid))
    }

    @Test
    fun `an empty byte array returns null, not a crash`() {
        assertNull(CcidClassDescriptor.parse(ByteArray(0)))
    }

    @Test
    fun `dwFeatures with none of the exchange-level bits set decodes to character level`() {
        // A synthetic 54-byte CCID descriptor block with dwFeatures=0
        // -- exercising the "none of the known bits" fallback per the
        // cited source (f_ccid.h): no TPDU/SAPDU/APDU bit means
        // character-level exchange. Not a live capture.
        val block = ByteArray(54)
        block[0] = 0x36
        block[1] = 0x21
        val descriptor = CcidClassDescriptor.parse(block)
        assertEquals(CcidExchangeLevel.CHARACTER, descriptor?.exchangeLevel)
    }

    @Test
    fun `dwFeatures with only the TPDU bit set decodes to TPDU exchange level`() {
        // Synthetic: dwFeatures = 0x00010000 at its real offset (40).
        val block = ByteArray(54)
        block[0] = 0x36
        block[1] = 0x21
        block[40] = 0x00
        block[41] = 0x00
        block[42] = 0x01
        block[43] = 0x00
        val descriptor = CcidClassDescriptor.parse(block)
        assertEquals(CcidExchangeLevel.TPDU, descriptor?.exchangeLevel)
    }
}

private fun hexToBytes(hex: String): ByteArray {
    val clean = hex.replace("\n", "").replace(" ", "")
    return ByteArray(clean.length / 2) { i ->
        clean.substring(i * 2, i * 2 + 2).toInt(16).toByte()
    }
}

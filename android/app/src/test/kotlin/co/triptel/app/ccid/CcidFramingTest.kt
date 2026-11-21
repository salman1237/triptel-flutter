package co.triptel.app.ccid

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** FR-L912: JVM unit tests for USB-CCID (rev 1.1) bulk-message framing. */
class CcidFramingTest {
    @Test
    fun `buildIccPowerOn produces the documented 10-byte header shape`() {
        val message = buildIccPowerOn(slot = 0, seq = 5, powerSelect = CcidPowerSelect.V5_0)
        assertEquals(10, message.size)
        assertEquals(CcidMessageType.PC_TO_RDR_ICC_POWER_ON, message[0].toInt() and 0xFF)
        // dwLength = 0 (no abData for IccPowerOn).
        assertArrayEquals(byteArrayOf(0, 0, 0, 0), message.copyOfRange(1, 5))
        assertEquals(0, message[5].toInt()) // bSlot
        assertEquals(5, message[6].toInt()) // bSeq
        assertEquals(CcidPowerSelect.V5_0.value, message[7].toInt() and 0xFF)
    }

    @Test
    fun `buildXfrBlock appends the APDU after the 10-byte header with the real dwLength`() {
        val apdu = byteArrayOf(0x00, 0xA4.toByte(), 0x04, 0x00)
        val message = buildXfrBlock(slot = 0, seq = 2, data = apdu)
        assertEquals(14, message.size)
        assertEquals(CcidMessageType.PC_TO_RDR_XFR_BLOCK, message[0].toInt() and 0xFF)
        assertArrayEquals(byteArrayOf(4, 0, 0, 0), message.copyOfRange(1, 5))
        assertArrayEquals(apdu, message.copyOfRange(10, 14))
    }

    @Test
    fun `buildSetParameters carries the protocol number and the parameter bytes`() {
        val params = byteArrayOf(0x11, 0x00, 0x0A, 0x00, 0x00) // T=0 default-ish shape
        val message = buildSetParameters(slot = 0, seq = 1, protocol = 0, data = params)
        assertEquals(CcidMessageType.PC_TO_RDR_SET_PARAMETERS, message[0].toInt() and 0xFF)
        assertEquals(0, message[7].toInt()) // bProtocolNum
        assertArrayEquals(params, message.copyOfRange(10, 15))
    }

    @Test
    fun `sequence numbers and slots round-trip through a parsed response`() {
        // A hand-built RDR_to_PC_DataBlock: slot 0, seq 7, status 0x00
        // (present+active, no error), error 0x00, chain 0x00, 2 bytes
        // of data (0x90 0x00 -- a plain OK status word, cited as an
        // ISO 7816-4 example, not claimed as a live capture).
        val raw = byteArrayOf(
            CcidMessageType.RDR_TO_PC_DATA_BLOCK.toByte(),
            2, 0, 0, 0,
            0, 7,
            0x00, 0x00, 0x00,
            0x90.toByte(), 0x00,
        )
        val result = parseCcidResponse(raw)
        assertTrue(result is CcidParseResult.Parsed)
        val response = (result as CcidParseResult.Parsed).response
        assertEquals(0, response.slot)
        assertEquals(7, response.seq)
        assertEquals(CcidIccStatus.PRESENT_ACTIVE, response.iccStatus)
        assertEquals(CcidCommandStatus.OK, response.commandStatus)
        assertArrayEquals(byteArrayOf(0x90.toByte(), 0x00), response.data)
    }

    @Test
    fun `a failed command status surfaces the real bError code`() {
        val raw = byteArrayOf(
            CcidMessageType.RDR_TO_PC_SLOT_STATUS.toByte(),
            0, 0, 0, 0,
            0, 1,
            // bmICCStatus=10 (not present) << 6, bmCommandStatus=01 (failed)
            (0b10_000001).toByte(),
            0xFE.toByte(), // ICC_MUTE
            0,
        )
        val response = (parseCcidResponse(raw) as CcidParseResult.Parsed).response
        assertEquals(CcidIccStatus.NOT_PRESENT, response.iccStatus)
        assertEquals(CcidCommandStatus.FAILED, response.commandStatus)
        assertEquals(0xFE, response.error)
        assertTrue(ccidErrorMessage(response.error).contains("ICC_MUTE"))
    }

    @Test
    fun `a response shorter than the 10-byte header is rejected, not crashed`() {
        assertEquals(
            CcidParseResult.Invalid("too_short"),
            parseCcidResponse(ByteArray(5)),
        )
    }

    @Test
    fun `a response whose declared dwLength exceeds the actual bytes is rejected`() {
        val raw = byteArrayOf(
            CcidMessageType.RDR_TO_PC_DATA_BLOCK.toByte(),
            100, 0, 0, 0, // claims 100 bytes of data that aren't there
            0, 0, 0, 0, 0,
        )
        assertEquals(CcidParseResult.Invalid("truncated"), parseCcidResponse(raw))
    }

    @Test
    fun `ccidErrorMessage maps a documented command-error offset (0x00-0x7F)`() {
        val message = ccidErrorMessage(0x33)
        assertTrue(message.contains("51")) // 0x33 == 51 decimal
    }

    @Test
    fun `ccidErrorMessage surfaces a raw unrecognized code rather than guessing`() {
        // 0x90 is outside the documented 0x00-0x7F command-error range
        // and isn't one of the named codes -- must fall through to the
        // honest "unrecognized" branch, not silently misclassify.
        val message = ccidErrorMessage(0x90)
        assertTrue(message.contains("90"))
    }

    @Test
    fun `toHex matches the real captured ATR's own hex rendering`() {
        val bytes = byteArrayOf(0x3B, 0x9F.toByte(), 0x96.toByte())
        assertEquals("3B9F96", bytes.toHex())
    }
}

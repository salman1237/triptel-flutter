package co.triptel.app.ccid

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * FR-L913: JVM unit tests for the APDU request-building and T=0
 * response-chaining logic -- no device needed. The chaining tests use
 * a scripted fake transport exercising ISO/IEC 7816-3 §10.2's own
 * documented `61xx`/`6Cxx` procedure-byte rules; byte sequences here
 * are constructed to match those rules, not claimed as a live capture
 * (the real captured SELECT ISD-R transcript is exercised on-device,
 * see `claude-progress.md`/`DECISIONS.md`).
 */
class ApduChannelTest {
    @Test
    fun `buildManageChannelOpen is the documented 5-byte open-channel APDU`() {
        assertArrayEquals(
            byteArrayOf(0x00, 0x70, 0x00, 0x00, 0x01),
            ApduChannel.buildManageChannelOpen(),
        )
    }

    @Test
    fun `buildManageChannelClose encodes the channel in both CLA and P2`() {
        val apdu = ApduChannel.buildManageChannelClose(2)
        assertArrayEquals(byteArrayOf(0x02, 0x70, 0x80.toByte(), 0x02), apdu)
    }

    @Test
    fun `buildManageChannelClose uses the extended CLA form for channels 4-19`() {
        // Channel 5 -> CLA = 0x40 | (5-4) = 0x41 (ISO/IEC 7816-4 §5.1.2).
        val apdu = ApduChannel.buildManageChannelClose(5)
        assertEquals(0x41, apdu[0].toInt() and 0xFF)
        assertEquals(5, apdu[3].toInt())
    }

    @Test(expected = IllegalArgumentException::class)
    fun `an out-of-range channel is rejected, not silently miscoded`() {
        ApduChannel.buildManageChannelClose(20)
    }

    @Test
    fun `buildSelectByAid carries the real ISD-R AID length and bytes`() {
        val apdu = ApduChannel.buildSelectByAid(1, ApduChannel.ISD_R_AID)
        assertEquals(0x01, apdu[0].toInt()) // CLA = channel 1
        assertEquals(0xA4.toByte(), apdu[1]) // INS = SELECT
        assertEquals(0x04, apdu[2].toInt()) // P1 = select by DF name
        assertEquals(0x00, apdu[3].toInt()) // P2
        assertEquals(ApduChannel.ISD_R_AID.size, apdu[4].toInt()) // Lc
        assertArrayEquals(
            ApduChannel.ISD_R_AID,
            apdu.copyOfRange(5, 5 + ApduChannel.ISD_R_AID.size),
        )
        assertEquals(0x00, apdu.last().toInt()) // Le
    }

    @Test
    fun `buildGetResponse requests exactly the Le the card just announced`() {
        val apdu = ApduChannel.buildGetResponse(0, 0x1A)
        assertArrayEquals(byteArrayOf(0x00, 0xC0.toByte(), 0x00, 0x00, 0x1A), apdu)
    }

    @Test
    fun `buildTerminalCapabilities uses SGP22's proprietary 0x80 class`() {
        val apdu = ApduChannel.buildTerminalCapabilities()
        assertEquals(0x80.toByte(), apdu[0])
        assertEquals(0xAA.toByte(), apdu[1])
    }

    @Test
    fun `a plain 9000 response needs no chaining`() {
        val result = transceiveApdu(0, byteArrayOf(0x00, 0xA4.toByte(), 0x04, 0x00, 0x00), send = {
            byteArrayOf(0x12, 0x34, 0x90.toByte(), 0x00)
        })
        val response = result as ApduResult.Response
        assertArrayEquals(byteArrayOf(0x12, 0x34), response.data)
        assertTrue(response.isSuccess)
        assertEquals(0x9000, response.sw)
    }

    @Test
    fun `61xx triggers a GET RESPONSE and appends its data to the final result`() {
        var call = 0
        val sentCommands = mutableListOf<ByteArray>()
        val result = transceiveApdu(0, byteArrayOf(0x00, 0xA4.toByte(), 0x04, 0x00, 0x00), send = { cmd ->
            sentCommands.add(cmd)
            call++
            if (call == 1) {
                // First response: no data yet, "26 more bytes ready".
                byteArrayOf(0x61, 0x1A)
            } else {
                // GET RESPONSE's own reply: the real FCI bytes + 9000.
                byteArrayOf(0xAA.toByte(), 0xBB.toByte(), 0x90.toByte(), 0x00)
            }
        })
        val response = result as ApduResult.Response
        assertArrayEquals(byteArrayOf(0xAA.toByte(), 0xBB.toByte()), response.data)
        assertTrue(response.isSuccess)
        // The second command sent must be GET RESPONSE with Le=0x1A.
        assertArrayEquals(
            byteArrayOf(0x00, 0xC0.toByte(), 0x00, 0x00, 0x1A),
            sentCommands[1],
        )
    }

    @Test
    fun `6Cxx resends the ORIGINAL command with Le corrected, not GET RESPONSE`() {
        var call = 0
        val sentCommands = mutableListOf<ByteArray>()
        val original = byteArrayOf(0x00, 0xA4.toByte(), 0x04, 0x00, 0x00)
        val result = transceiveApdu(0, original, send = { cmd ->
            sentCommands.add(cmd)
            call++
            if (call == 1) {
                byteArrayOf(0x6C, 0x10) // "wrong Le, try again with 0x10"
            } else {
                byteArrayOf(0xCC.toByte(), 0x90.toByte(), 0x00)
            }
        })
        val response = result as ApduResult.Response
        assertArrayEquals(byteArrayOf(0xCC.toByte()), response.data)
        // Resent command is the ORIGINAL header, Le replaced with 0x10.
        assertArrayEquals(
            byteArrayOf(0x00, 0xA4.toByte(), 0x04, 0x00, 0x10),
            sentCommands[1],
        )
    }

    @Test
    fun `a non-success status word that isn't 61xx or 6Cxx is the final result as-is`() {
        val result = transceiveApdu(0, byteArrayOf(0x00, 0xA4.toByte(), 0x04, 0x00, 0x00), send = {
            byteArrayOf(0x6A, 0x82.toByte()) // "file/application not found"
        })
        val response = result as ApduResult.Response
        assertFalse(response.isSuccess)
        assertEquals(0x6A82, response.sw)
    }

    @Test
    fun `a null response from the transport is a typed failure, not a crash`() {
        val result = transceiveApdu(0, byteArrayOf(0x00), send = { null })
        assertEquals(ApduResult.Failed("no_response"), result)
    }

    @Test
    fun `a response shorter than 2 bytes (no room for SW1SW2) is a typed failure`() {
        val result = transceiveApdu(0, byteArrayOf(0x00), send = { byteArrayOf(0x90.toByte()) })
        assertEquals(ApduResult.Failed("short_response:1"), result)
    }

    @Test
    fun `a chain that never resolves is bounded, not an infinite loop`() {
        val result = transceiveApdu(0, byteArrayOf(0x00), send = { byteArrayOf(0x61, 0x01) })
        assertEquals(ApduResult.Failed("chain_too_long"), result)
    }
}

package co.triptel.app.ccid

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * FR-L912: JVM unit tests for the ISO/IEC 7816-3 ATR parser -- no
 * device needed. The primary fixture is a real ATR captured live
 * 2026-11-22 from the connected USB CCID reader ("EMV Smartcard
 * Reader", vendor 0x2CE3/11491, product 0x9563/38243) via the app's
 * own "Power on" diagnostic (`docs/Rules.md`: real recorded
 * transcripts, never invented byte sequences presented as real).
 */
class AtrTest {
    // Captured live 2026-11-22: 3B 9F 96 80 3F C7 82 80 31 E0 73 FE 21
    // 1B 57 AA 86 60 F0 02 00 08 F4
    private val realAtr = hexToBytes("3B9F96803FC7828031E073FE211B57AA8660F0020008F4")

    @Test
    fun `parses the real captured ATR's TS and protocol set`() {
        val result = parseAtr(realAtr)
        assertTrue(result is AtrParseResult.Parsed)
        val atr = (result as AtrParseResult.Parsed).atr

        // TD2's protocol nibble was 0xF (15) -- ISO/IEC 7816-3's "global
        // interface bytes follow" marker, not a real protocol -- so the
        // only real protocol this card offers is T=0.
        assertEquals(setOf(0), atr.protocols)
        assertEquals(0, atr.preferredProtocol())
    }

    @Test
    fun `the real captured ATR's checksum is present and valid`() {
        val result = parseAtr(realAtr) as AtrParseResult.Parsed
        assertTrue(result.atr.hasChecksum)
        assertTrue(result.atr.checksumValid)
    }

    @Test
    fun `the real captured ATR's TA1 decodes to Fi 512, Di 32`() {
        // TA1 = 0x96: high nibble 0x9 -> Fi 512 (ISO 7816-3 Table 7),
        // low nibble 0x6 -> Di 32 (Table 8) -- not the spec's default
        // row (0x11 -> 372/1), confirmed against the real byte.
        val result = parseAtr(realAtr) as AtrParseResult.Parsed
        val ta1 = result.atr.ta1
        assertEquals(0x96, ta1)
        assertEquals(512, ta1?.let(::fiFromTa1))
        assertEquals(32, ta1?.let(::diFromTa1))
    }

    @Test
    fun `the real captured ATR has 15 historical bytes, matching T0's K nibble`() {
        val result = parseAtr(realAtr) as AtrParseResult.Parsed
        assertEquals(15, result.atr.historicalBytes.size)
    }

    @Test
    fun `rejects an empty byte array`() {
        assertTrue(parseAtr(ByteArray(0)) is AtrParseResult.Invalid)
    }

    @Test
    fun `rejects a TS byte that isn't 0x3B or 0x3F`() {
        val result = parseAtr(byteArrayOf(0x00, 0x00))
        assertEquals(AtrParseResult.Invalid("bad_ts"), result)
    }

    @Test
    fun `accepts the inverse-convention TS byte 0x3F`() {
        // Minimal synthetic ATR constructed per ISO/IEC 7816-3's own
        // structural rule (TS=0x3F, T0 with Y1=0 so no interface bytes,
        // K=0 so no historical bytes) -- not a live capture, just
        // exercising the inverse-convention TS path the real capture
        // above doesn't happen to cover.
        val result = parseAtr(byteArrayOf(0x3F, 0x00))
        assertTrue(result is AtrParseResult.Parsed)
    }

    @Test
    fun `no TD byte at all means T=0 is implicit, per ISO 7816-3, and no checksum`() {
        // T0 = 0x00 -> Y1=0 (no TA1/TB1/TC1/TD1), K=0 (no historical
        // bytes). Structurally minimal, not a live capture.
        val result = parseAtr(byteArrayOf(0x3B, 0x00)) as AtrParseResult.Parsed
        assertEquals(setOf(0), result.atr.protocols)
        assertFalse(result.atr.hasChecksum)
        assertNull(result.atr.ta1)
    }

    @Test
    fun `an explicit T=1 offer requires and validates a checksum`() {
        // TS=0x3B, T0=0x80 (Y1=1000 -> TD1 present, K=0), TD1=0x01
        // (protocol T=1, no further chain), then TCK making the XOR of
        // T0..TCK equal 0 (0x80 ^ 0x01 ^ TCK = 0 -> TCK = 0x81).
        // Structurally built from the spec's own checksum rule (XOR of
        // T0 through TCK must be 0), not a live capture.
        val bytes = byteArrayOf(0x3B, 0x80.toByte(), 0x01, 0x81.toByte())
        val result = parseAtr(bytes) as AtrParseResult.Parsed
        assertEquals(setOf(1), result.atr.protocols)
        assertEquals(1, result.atr.preferredProtocol())
        assertTrue(result.atr.hasChecksum)
        assertTrue(result.atr.checksumValid)
    }

    @Test
    fun `an invalid checksum is reported, not silently accepted`() {
        val bytes = byteArrayOf(0x3B, 0x80.toByte(), 0x01, 0x00)
        val result = parseAtr(bytes) as AtrParseResult.Parsed
        assertFalse(result.atr.checksumValid)
    }

    @Test
    fun `a truncated ATR (TA1 announced but missing) is rejected, not crashed`() {
        val result = parseAtr(byteArrayOf(0x3B, 0x10))
        assertEquals(AtrParseResult.Invalid("truncated_ta"), result)
    }

    @Test
    fun `fiFromTa1 and diFromTa1 decode ISO 7816-3 Table 7-8's documented values`() {
        // TA1 = 0x11 -> Fi index 0x1 (372), Di index 0x1 (1) -- the
        // spec's own default row.
        assertEquals(372, fiFromTa1(0x11))
        assertEquals(1, diFromTa1(0x11))
        // TA1 = 0x93 -> Fi index 0x9 (512), Di index 0x3 (4).
        assertEquals(512, fiFromTa1(0x93))
        assertEquals(4, diFromTa1(0x93))
    }
}

private fun hexToBytes(hex: String): ByteArray =
    ByteArray(hex.length / 2) { i ->
        hex.substring(i * 2, i * 2 + 2).toInt(16).toByte()
    }

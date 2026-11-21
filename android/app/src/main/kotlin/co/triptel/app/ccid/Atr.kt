package co.triptel.app.ccid

/**
 * FR-L912: ISO/IEC 7816-3 Answer-To-Reset (ATR) parser -- pure byte-level
 * logic, no USB I/O, so it's JVM-unit-testable without a device
 * (`docs/Functional_Requirements.md`'s own requirement for this FR).
 *
 * Only decodes what the adapter actually needs: which protocol(s) (T=0,
 * T=1) the card offers, TA1's Fi/Di (clock-rate conversion / bit-rate
 * adjustment, needed to build a correct `PC_to_RDR_SetParameters`),
 * historical bytes, and checksum validity. TB/TC/TD(n>1) interface
 * bytes beyond TA1 are walked (to stay in sync with the byte stream)
 * but not semantically decoded -- nothing in this FR's scope needs them
 * yet.
 */
data class ParsedAtr(
    val raw: ByteArray,
    /** e.g. `{0}` for T=0 only, `{0, 1}` if the card also offers T=1. */
    val protocols: Set<Int>,
    /** TA1's raw byte, if present -- decode with [fiFromTa1]/[diFromTa1]. */
    val ta1: Int?,
    val historicalBytes: ByteArray,
    val hasChecksum: Boolean,
    val checksumValid: Boolean,
) {
    /** The protocol to actually use: prefers T=1 (what SGP.22 eUICCs
     * typically offer and the one this adapter is built around) if the
     * card offers it, else falls back to T=0. */
    fun preferredProtocol(): Int = if (1 in protocols) 1 else 0
}

sealed class AtrParseResult {
    data class Parsed(val atr: ParsedAtr) : AtrParseResult()
    data class Invalid(val reason: String) : AtrParseResult()
}

fun parseAtr(raw: ByteArray): AtrParseResult {
    if (raw.isEmpty()) return AtrParseResult.Invalid("empty")
    val ts = raw[0].toInt() and 0xFF
    // 0x3B = direct convention, 0x3F = inverse convention (ISO/IEC 7816-3 §8.1).
    if (ts != 0x3B && ts != 0x3F) return AtrParseResult.Invalid("bad_ts")
    if (raw.size < 2) return AtrParseResult.Invalid("too_short")

    var offset = 1
    val t0 = raw[offset].toInt() and 0xFF
    offset++
    val k = t0 and 0x0F
    var y = (t0 shr 4) and 0x0F

    val protocols = mutableSetOf<Int>()
    var ta1: Int? = null
    var level = 1
    // Whether any TDi's protocol nibble was non-zero, INCLUDING the
    // T=15 "global interface bytes follow" marker below -- this (not
    // just [protocols]) is what determines whether TCK is present.
    // Confirmed against a real captured ATR (2026-11-22, this reader's
    // own card): TD2's nibble was 0xF (15, not a real protocol), yet
    // TCK was genuinely present and its checksum validated -- so the
    // presence trigger is "any non-zero TDi nibble ever appeared", not
    // "a real alternate protocol was offered".
    var sawNonZeroProtocolNibble = false

    while (true) {
        val hasTA = (y and 0x01) != 0
        val hasTB = (y and 0x02) != 0
        val hasTC = (y and 0x04) != 0
        val hasTD = (y and 0x08) != 0

        if (hasTA) {
            if (offset >= raw.size) return AtrParseResult.Invalid("truncated_ta")
            if (level == 1) ta1 = raw[offset].toInt() and 0xFF
            offset++
        }
        if (hasTB) {
            if (offset >= raw.size) return AtrParseResult.Invalid("truncated_tb")
            offset++
        }
        if (hasTC) {
            if (offset >= raw.size) return AtrParseResult.Invalid("truncated_tc")
            offset++
        }
        if (hasTD) {
            if (offset >= raw.size) return AtrParseResult.Invalid("truncated_td")
            val td = raw[offset].toInt() and 0xFF
            offset++
            val protocolNibble = td and 0x0F
            if (protocolNibble != 0) sawNonZeroProtocolNibble = true
            // 15 (0xF) isn't a real transmission protocol -- ISO/IEC
            // 7816-3 §8.3 reserves it to mean "the interface bytes at
            // this level are global, not protocol-specific", so it
            // must not be offered as a selectable protocol.
            if (protocolNibble != 0x0F) protocols.add(protocolNibble)
            y = (td shr 4) and 0x0F
            level++
        } else {
            break
        }
    }
    // No TD byte ever appeared -- ISO/IEC 7816-3: T=0 is implicit.
    if (protocols.isEmpty()) protocols.add(0)

    if (offset + k > raw.size) return AtrParseResult.Invalid("truncated_historical")
    val historical = raw.copyOfRange(offset, offset + k)
    offset += k

    // TCK is present iff any TDi nibble was non-zero (ISO/IEC 7816-3
    // §8.2.5) -- including the T=15 global-bytes marker, confirmed
    // against the real captured ATR above.
    val expectChecksum = sawNonZeroProtocolNibble
    var hasChecksum = false
    var checksumValid = true
    if (expectChecksum) {
        if (offset >= raw.size) return AtrParseResult.Invalid("missing_checksum")
        hasChecksum = true
        val tck = raw[offset].toInt() and 0xFF
        var xor = 0
        for (i in 1 until offset) xor = xor xor (raw[i].toInt() and 0xFF)
        checksumValid = (xor xor tck) == 0
        offset++
    }

    return AtrParseResult.Parsed(
        ParsedAtr(
            raw = raw,
            protocols = protocols,
            ta1 = ta1,
            historicalBytes = historical,
            hasChecksum = hasChecksum,
            checksumValid = checksumValid,
        ),
    )
}

/**
 * ISO/IEC 7816-3 Table 7 (Fi, clock rate conversion integer) decoded
 * from TA1's high nibble. `null` means RFU in the spec's own table.
 */
fun fiFromTa1(ta1: Int): Int? = when ((ta1 shr 4) and 0x0F) {
    0x0 -> 372
    0x1 -> 372
    0x2 -> 558
    0x3 -> 744
    0x4 -> 1116
    0x5 -> 1488
    0x6 -> 1860
    0x9 -> 512
    0xA -> 768
    0xB -> 1024
    0xC -> 1536
    0xD -> 2048
    else -> null
}

/**
 * ISO/IEC 7816-3 Table 8 (Di, bit rate adjustment integer) decoded from
 * TA1's low nibble. `null` means RFU in the spec's own table.
 */
fun diFromTa1(ta1: Int): Int? = when (ta1 and 0x0F) {
    0x1 -> 1
    0x2 -> 2
    0x3 -> 4
    0x4 -> 8
    0x5 -> 16
    0x6 -> 32
    0x8 -> 12
    0x9 -> 20
    else -> null
}

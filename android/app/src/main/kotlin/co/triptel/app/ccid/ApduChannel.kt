package co.triptel.app.ccid

/**
 * FR-L913: the ISO/IEC 7816-4 APDU layer built on top of FR-L912's CCID
 * transceiver -- MANAGE CHANNEL, SELECT by AID, Terminal Capabilities,
 * and T=0's response-chaining rules (`61xx` -> `GET RESPONSE`, `6Cxx`
 * -> resend with the corrected `Le`). Pure request-building and
 * response-chaining logic lives here, JVM-testable with recorded/cited
 * transcripts; the actual byte transport is [CcidTransceiver].
 */
object ApduChannel {
    /** SGP.22's fixed ISD-R (Issuer Security Domain Root) AID -- every
     * eUICC profile-management operation goes through it. Same AID
     * `OmapiProbe.kt` (FR-L905) uses for its OMAPI channel. */
    val ISD_R_AID = byteArrayOf(
        0xA0.toByte(), 0x00, 0x00, 0x05, 0x59, 0x10, 0x10,
        0xFF.toByte(), 0xFF.toByte(), 0xFF.toByte(), 0xFF.toByte(),
        0x89.toByte(), 0x00, 0x00, 0x01, 0x00,
    )

    /** `MANAGE CHANNEL` / open (ISO/IEC 7816-4 §11.1.17): CLA=0x00,
     * INS=0x70, P1=0x00 (open), P2=0x00, Le=0x01 (card assigns and
     * returns one channel number byte). */
    fun buildManageChannelOpen(): ByteArray =
        byteArrayOf(0x00, 0x70, 0x00, 0x00, 0x01)

    /** `MANAGE CHANNEL` / close: CLA carries the channel to close,
     * INS=0x70, P1=0x80 (close), P2=the channel number. */
    fun buildManageChannelClose(channel: Int): ByteArray =
        byteArrayOf(classByte(channel), 0x70, 0x80.toByte(), channel.toByte())

    /** `SELECT` by AID (ISO/IEC 7816-4 §11.1.1): P1=0x04 (select by
     * DF name), P2=0x00 (first/only occurrence, return FCI), Lc=AID
     * length, data=AID, Le=0x00 (expect whatever the card sends back). */
    fun buildSelectByAid(channel: Int, aid: ByteArray): ByteArray =
        byteArrayOf(classByte(channel), 0xA4.toByte(), 0x04, 0x00, aid.size.toByte()) +
            aid + byteArrayOf(0x00)

    /** `GET RESPONSE` (ISO/IEC 7816-4 §7.6.1, the T=0 procedure byte
     * `61xx` tells the terminal to issue this): INS=0xC0, Le=the exact
     * byte count the card just said it has ready (`SW2`). */
    fun buildGetResponse(channel: Int, le: Int): ByteArray =
        byteArrayOf(classByte(channel), 0xC0.toByte(), 0x00, 0x00, le.toByte())

    /** SGP.22's Terminal Capabilities APDU (ES10b `GetEuiccChallenge`'s
     * sibling command the LPA sends before profile operations):
     * CLA=0x80 (SGP.22-defined proprietary class, not ISO's 0x00),
     * INS=0xAA, no data for the minimal "no extra capability" form. */
    fun buildTerminalCapabilities(): ByteArray =
        byteArrayOf(0x80.toByte(), 0xAA.toByte(), 0x00, 0x00, 0x00)

    /** T=0 logical-channel class byte encoding (ISO/IEC 7816-4 §5.1.2):
     * channels 0-3 use CLA bits 1-0 directly; channels 4-19 use the
     * extended form (CLA bits 3-0 = channel-4, bit 6 set). Channel 0
     * is the basic/default channel some commands target directly. */
    private fun classByte(channel: Int): Byte = when {
        channel in 0..3 -> channel.toByte()
        channel in 4..19 -> (0x40 or (channel - 4)).toByte()
        else -> throw IllegalArgumentException("channel $channel out of range 0-19")
    }
}

/** The real outcome of sending one APDU and following T=0's chaining
 * rules to completion -- always the card's real, final response. */
sealed class ApduResult {
    data class Response(val data: ByteArray, val sw1: Int, val sw2: Int) : ApduResult() {
        val sw: Int get() = (sw1 shl 8) or sw2
        val isSuccess: Boolean get() = sw1 == 0x90 && sw2 == 0x00
    }

    data class Failed(val reason: String) : ApduResult()
}

/**
 * Sends [capdu] via [send] and follows T=0's response-chaining rules
 * to a final result: `61xx` -> issue `GET RESPONSE` for `xx` more
 * bytes and append; `6Cxx` -> resend the *original* command with `Le`
 * corrected to `xx`. [send] is the actual transport (a CCID
 * `XfrBlock` round trip in production); this function is pure given
 * [send], so it's JVM-testable with a scripted fake transport and
 * cited/recorded byte transcripts -- no device needed to test the
 * chaining logic itself.
 */
fun transceiveApdu(
    channel: Int,
    capdu: ByteArray,
    send: (ByteArray) -> ByteArray?,
    maxChainedCalls: Int = 8,
): ApduResult {
    var command = capdu
    val collected = mutableListOf<Byte>()
    repeat(maxChainedCalls) {
        val raw = send(command) ?: return ApduResult.Failed("no_response")
        if (raw.size < 2) return ApduResult.Failed("short_response:${raw.size}")
        val sw1 = raw[raw.size - 2].toInt() and 0xFF
        val sw2 = raw[raw.size - 1].toInt() and 0xFF
        val data = raw.copyOfRange(0, raw.size - 2)
        when (sw1) {
            0x61 -> {
                collected.addAll(data.toList())
                command = ApduChannel.buildGetResponse(channel, sw2)
            }
            0x6C -> {
                // Resend the ORIGINAL command (not GET RESPONSE) with
                // Le corrected -- the card hasn't produced any data
                // yet for this attempt, so nothing to collect here.
                command = capdu.copyOf(capdu.size - 1) + sw2.toByte()
            }
            else -> {
                collected.addAll(data.toList())
                return ApduResult.Response(collected.toByteArray(), sw1, sw2)
            }
        }
    }
    return ApduResult.Failed("chain_too_long")
}

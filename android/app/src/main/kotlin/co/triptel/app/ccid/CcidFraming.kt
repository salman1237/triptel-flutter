package co.triptel.app.ccid

/**
 * FR-L912: USB-CCID (rev 1.1) bulk-message framing -- pure byte-level
 * build/parse logic, no USB I/O, so it's JVM-unit-testable without a
 * device. The actual bulk transfer lives in `CcidTransceiver.kt`.
 */
object CcidMessageType {
    const val PC_TO_RDR_ICC_POWER_ON: Int = 0x62
    const val PC_TO_RDR_ICC_POWER_OFF: Int = 0x63
    const val PC_TO_RDR_GET_SLOT_STATUS: Int = 0x65
    const val PC_TO_RDR_XFR_BLOCK: Int = 0x6F
    const val PC_TO_RDR_SET_PARAMETERS: Int = 0x61
    const val RDR_TO_PC_DATA_BLOCK: Int = 0x80
    const val RDR_TO_PC_SLOT_STATUS: Int = 0x81
    const val RDR_TO_PC_PARAMETERS: Int = 0x82
}

enum class CcidPowerSelect(val value: Int) {
    AUTO(0x00),
    V5_0(0x01),
    V3_0(0x02),
    V1_8(0x03),
}

/** `bmICCStatus` (bits 7:6 of `bStatus`). */
enum class CcidIccStatus {
    PRESENT_ACTIVE,
    PRESENT_INACTIVE,
    NOT_PRESENT,
    UNKNOWN,
}

/** `bmCommandStatus` (bits 1:0 of `bStatus`). */
enum class CcidCommandStatus {
    OK,
    FAILED,
    TIME_EXTENSION,
    UNKNOWN,
}

data class CcidResponse(
    val messageType: Int,
    val slot: Int,
    val seq: Int,
    val iccStatus: CcidIccStatus,
    val commandStatus: CcidCommandStatus,
    /** Meaningful only when [commandStatus] is [CcidCommandStatus.FAILED]. */
    val error: Int,
    val data: ByteArray,
)

sealed class CcidParseResult {
    data class Parsed(val response: CcidResponse) : CcidParseResult()
    data class Invalid(val reason: String) : CcidParseResult()
}

fun buildIccPowerOn(slot: Int, seq: Int, powerSelect: CcidPowerSelect): ByteArray =
    buildHeader(
        messageType = CcidMessageType.PC_TO_RDR_ICC_POWER_ON,
        length = 0,
        slot = slot,
        seq = seq,
        param0 = powerSelect.value,
    )

fun buildIccPowerOff(slot: Int, seq: Int): ByteArray =
    buildHeader(
        messageType = CcidMessageType.PC_TO_RDR_ICC_POWER_OFF,
        length = 0,
        slot = slot,
        seq = seq,
    )

fun buildGetSlotStatus(slot: Int, seq: Int): ByteArray =
    buildHeader(
        messageType = CcidMessageType.PC_TO_RDR_GET_SLOT_STATUS,
        length = 0,
        slot = slot,
        seq = seq,
    )

/** [data] here is T=0/T=1 protocol-specific parameters (5 or 7 bytes). */
fun buildSetParameters(slot: Int, seq: Int, protocol: Int, data: ByteArray): ByteArray =
    buildHeader(
        messageType = CcidMessageType.PC_TO_RDR_SET_PARAMETERS,
        length = data.size,
        slot = slot,
        seq = seq,
        param0 = protocol,
    ) + data

fun buildXfrBlock(slot: Int, seq: Int, data: ByteArray, bwi: Int = 0): ByteArray =
    buildHeader(
        messageType = CcidMessageType.PC_TO_RDR_XFR_BLOCK,
        length = data.size,
        slot = slot,
        seq = seq,
        param0 = bwi,
    ) + data

private fun buildHeader(
    messageType: Int,
    length: Int,
    slot: Int,
    seq: Int,
    param0: Int = 0,
    param1: Int = 0,
    param2: Int = 0,
): ByteArray {
    val buf = ByteArray(10)
    buf[0] = messageType.toByte()
    buf[1] = (length and 0xFF).toByte()
    buf[2] = ((length shr 8) and 0xFF).toByte()
    buf[3] = ((length shr 16) and 0xFF).toByte()
    buf[4] = ((length shr 24) and 0xFF).toByte()
    buf[5] = slot.toByte()
    buf[6] = seq.toByte()
    buf[7] = param0.toByte()
    buf[8] = param1.toByte()
    buf[9] = param2.toByte()
    return buf
}

/** Parses any `RDR_to_PC_*` response (DataBlock/SlotStatus/Parameters
 * all share the same 10-byte header shape). */
fun parseCcidResponse(raw: ByteArray): CcidParseResult {
    if (raw.size < 10) return CcidParseResult.Invalid("too_short")
    val messageType = raw[0].toInt() and 0xFF
    val length = (raw[1].toInt() and 0xFF) or
        ((raw[2].toInt() and 0xFF) shl 8) or
        ((raw[3].toInt() and 0xFF) shl 16) or
        ((raw[4].toInt() and 0xFF) shl 24)
    val slot = raw[5].toInt() and 0xFF
    val seq = raw[6].toInt() and 0xFF
    val bStatus = raw[7].toInt() and 0xFF
    val bError = raw[8].toInt() and 0xFF
    if (length < 0 || raw.size < 10 + length) return CcidParseResult.Invalid("truncated")

    val iccStatus = when ((bStatus shr 6) and 0x03) {
        0 -> CcidIccStatus.PRESENT_ACTIVE
        1 -> CcidIccStatus.PRESENT_INACTIVE
        2 -> CcidIccStatus.NOT_PRESENT
        else -> CcidIccStatus.UNKNOWN
    }
    val commandStatus = when (bStatus and 0x03) {
        0 -> CcidCommandStatus.OK
        1 -> CcidCommandStatus.FAILED
        2 -> CcidCommandStatus.TIME_EXTENSION
        else -> CcidCommandStatus.UNKNOWN
    }
    return CcidParseResult.Parsed(
        CcidResponse(
            messageType = messageType,
            slot = slot,
            seq = seq,
            iccStatus = iccStatus,
            commandStatus = commandStatus,
            error = bError,
            data = raw.copyOfRange(10, 10 + length),
        ),
    )
}

/** Hex-encodes a byte array for display/logging (e.g. a raw ATR). */
fun ByteArray.toHex(): String = joinToString("") { "%02X".format(it) }

/**
 * `bError` meanings for a failed command (CCID rev 1.1 §6.2.6, the
 * common/documented subset -- an unrecognized code still surfaces the
 * raw value rather than guessing).
 */
fun ccidErrorMessage(error: Int): String = when (error) {
    0xFE -> "ICC_MUTE: no response from the card (not inserted, or dead)"
    0xFF -> "CMD_ABORTED: the host aborted this command"
    0xFD -> "XFR_PARITY_ERROR: parity error on the card's response"
    0xFC -> "XFR_OVERRUN: the card sent more data than expected"
    0xFB -> "HW_ERROR: a hardware error on the reader itself"
    0xAB -> "BAD_ATR_TS: the ATR's initial byte (TS) was invalid"
    0xAC -> "BAD_ATR_TCK: the ATR's checksum (TCK) didn't match"
    0xE0 -> "SLOTNOTFOUND: no such slot on this reader"
    0xEF -> "BAD_POWERSELECT: the requested voltage isn't supported"
    in 0x00..0x7F -> "Command error at byte offset $error of the message sent"
    else -> "Unrecognized CCID error code 0x${error.toString(16).uppercase()}"
}

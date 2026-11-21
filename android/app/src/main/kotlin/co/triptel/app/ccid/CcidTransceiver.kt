package co.triptel.app.ccid

import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import java.util.concurrent.Executors

sealed class CcidPowerOnResult {
    data class Success(
        val atr: ParsedAtr,
        val rawAtr: ByteArray,
        val voltage: CcidPowerSelect,
    ) : CcidPowerOnResult()

    data class Failed(val reason: String, val lastError: Int?) : CcidPowerOnResult()
}

/**
 * FR-L912: the real USB-CCID bulk transceiver. All I/O runs on a
 * single dedicated worker thread (`docs/Rules.md`: "one card, one
 * in-flight APDU exchange at a time") -- callers must not invoke the
 * `*OnWorker` methods from the calling/main thread directly; submit
 * through [executor] (see `UsbCcidReaders.kt`'s MethodChannel glue for
 * the main-thread hand-off pattern, matching `OmapiProbe.kt`).
 */
class CcidTransceiver(
    private val connection: UsbDeviceConnection,
    private val usbInterface: UsbInterface,
    private val bulkOut: UsbEndpoint,
    private val bulkIn: UsbEndpoint,
) {
    val executor = Executors.newSingleThreadExecutor()
    private var seq = 0

    /** Captured once at session open -- doesn't change while attached. */
    val classDescriptor: CcidClassDescriptor? by lazy {
        connection.rawDescriptors?.let(CcidClassDescriptor::parse)
    }

    private fun nextSeq(): Int {
        val s = seq
        seq = (seq + 1) and 0xFF
        return s
    }

    /** Must only be called from [executor]. */
    private fun transceive(command: ByteArray, timeoutMs: Int): CcidParseResult {
        val sent = connection.bulkTransfer(bulkOut, command, command.size, timeoutMs)
        if (sent < 0) return CcidParseResult.Invalid("bulk_out_failed")
        val buffer = ByteArray(10 + MAX_RESPONSE_DATA)
        val read = connection.bulkTransfer(bulkIn, buffer, buffer.size, timeoutMs)
        if (read < 10) return CcidParseResult.Invalid("short_read:$read")
        return parseCcidResponse(buffer.copyOfRange(0, read))
    }

    /**
     * Powers on the card, falling back 5V -> 3V -> 1.8V if a voltage
     * doesn't produce a valid ATR (`docs/Functional_Requirements.md`
     * FR-L912). Must only be called from [executor].
     */
    fun powerOnOnWorker(slot: Int = 0, timeoutMs: Int = 10_000): CcidPowerOnResult {
        var lastError: Int? = null
        for (voltage in listOf(CcidPowerSelect.V5_0, CcidPowerSelect.V3_0, CcidPowerSelect.V1_8)) {
            val command = buildIccPowerOn(slot, nextSeq(), voltage)
            when (val result = transceive(command, timeoutMs)) {
                is CcidParseResult.Invalid -> continue
                is CcidParseResult.Parsed -> {
                    val response = result.response
                    if (response.commandStatus != CcidCommandStatus.OK) {
                        lastError = response.error
                        continue
                    }
                    when (val atrResult = parseAtr(response.data)) {
                        is AtrParseResult.Parsed ->
                            return CcidPowerOnResult.Success(
                                atr = atrResult.atr,
                                rawAtr = response.data,
                                voltage = voltage,
                            )
                        is AtrParseResult.Invalid -> continue
                    }
                }
            }
        }
        return CcidPowerOnResult.Failed(
            reason = lastError?.let(::ccidErrorMessage)
                ?: "No voltage level produced a valid ATR",
            lastError = lastError,
        )
    }

    /** Must only be called from [executor]. */
    fun powerOffOnWorker(slot: Int = 0, timeoutMs: Int = 5000): CcidParseResult =
        transceive(buildIccPowerOff(slot, nextSeq()), timeoutMs)

    /**
     * FR-L913: sends one (possibly chained, per T=0's `61xx`/`6Cxx`
     * rules) APDU over this session's open card, via CCID `XfrBlock`.
     * Must only be called from [executor] -- the card must already be
     * powered on ([powerOnOnWorker]) first.
     */
    fun sendApduOnWorker(channel: Int, capdu: ByteArray, slot: Int = 0, timeoutMs: Int = 10_000): ApduResult =
        transceiveApdu(channel, capdu, send = { command ->
            val xfr = buildXfrBlock(slot, nextSeq(), command)
            when (val result = transceive(xfr, timeoutMs)) {
                is CcidParseResult.Parsed ->
                    if (result.response.commandStatus == CcidCommandStatus.OK) {
                        result.response.data
                    } else {
                        null
                    }
                is CcidParseResult.Invalid -> null
            }
        })

    fun close() {
        try {
            connection.releaseInterface(usbInterface)
        } finally {
            connection.close()
            executor.shutdown()
        }
    }

    companion object {
        /** Generous upper bound for a single CCID response's `abData`
         * (an ATR is at most 33 bytes; this just guards the read
         * buffer against a pathological/corrupt length field). */
        private const val MAX_RESPONSE_DATA = 65536

        /** Finds the bulk-in/bulk-out endpoint pair on a CCID
         * interface. `null` if the interface doesn't have both
         * (malformed device). */
        fun findBulkEndpoints(usbInterface: UsbInterface): Pair<UsbEndpoint, UsbEndpoint>? {
            var bulkIn: UsbEndpoint? = null
            var bulkOut: UsbEndpoint? = null
            for (i in 0 until usbInterface.endpointCount) {
                val endpoint = usbInterface.getEndpoint(i)
                if (endpoint.type != UsbConstants.USB_ENDPOINT_XFER_BULK) continue
                if (endpoint.direction == UsbConstants.USB_DIR_IN) {
                    bulkIn = endpoint
                } else {
                    bulkOut = endpoint
                }
            }
            val inEp = bulkIn ?: return null
            val outEp = bulkOut ?: return null
            return outEp to inEp
        }
    }
}

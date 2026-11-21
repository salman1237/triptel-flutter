package co.triptel.app.ccid

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

/**
 * FR-L910: detects USB CCID (0x0B) smart-card readers -- the transport
 * for a removable eUICC adapter once FR-L905 confirmed the phone's own
 * in-tray card's ARA-M doesn't trust this app (`docs/Functional_Requirements.md`
 * section P2, `DECISIONS.md` 2026-11-19). Unprivileged `UsbManager` APIs
 * only (`docs/Rules.md`'s "never touch the phone's internal eSIM" rule) --
 * this never requests a privileged permission, only the normal per-device
 * USB host permission (FR-L911).
 *
 * Hot-plug receivers are tied to the *activity* being started/stopped
 * (`registerReceiver`/`unregisterReceiver`, called from `MainActivity`),
 * not a manifest `<intent-filter>` -- the FR is explicit this app must
 * never auto-launch when a reader is plugged in.
 */
class UsbCcidReaders(private val context: Context) : EventChannel.StreamHandler {
    private val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
    private var eventSink: EventChannel.EventSink? = null
    private var receiverRegistered = false

    /** FR-L912: open card sessions, keyed by `UsbDevice.deviceId`. Torn
     * down on detach (below) -- never held past a device's lifetime. */
    private val transceivers = mutableMapOf<Int, CcidTransceiver>()

    private val receiver =
        object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                if (intent.action == UsbManager.ACTION_USB_DEVICE_DETACHED) {
                    @Suppress("DEPRECATION")
                    val detached = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                    detached?.let { closeSession(it.deviceId) }
                }
                emitCurrentList()
            }
        }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
        emitCurrentList()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    /** Call from the activity's `onStart()`. Idempotent. */
    fun registerReceiver() {
        if (receiverRegistered) return
        val filter =
            IntentFilter().apply {
                addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
                addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
            }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(receiver, filter)
        }
        receiverRegistered = true
        emitCurrentList()
    }

    /** Call from the activity's `onStop()`. Idempotent. */
    fun unregisterReceiver() {
        if (!receiverRegistered) return
        try {
            context.unregisterReceiver(receiver)
        } catch (e: Exception) {
            Log.w(TAG, "unregisterReceiver failed", e)
        }
        receiverRegistered = false
    }

    /** One-shot: does this device even have USB host mode at all? */
    fun hasUsbHostFeature(): Boolean =
        context.packageManager.hasSystemFeature("android.hardware.usb.host")

    /**
     * FR-L911: requests the standard per-device USB permission (never a
     * privileged one -- `docs/Rules.md`). Result is always exactly one
     * of `granted` | `denied` | `detached_meanwhile`, delivered once,
     * and never throws back to Dart.
     *
     * The `PendingIntent` must be **mutable** -- the system needs to add
     * `EXTRA_PERMISSION_GRANTED`/`EXTRA_DEVICE` to it when it fires,
     * which silently fails to arrive on an immutable one (the default
     * since Android 12). This is the single most common bug in
     * `UsbManager.requestPermission` integrations.
     *
     * "Denied" and "detached meanwhile" are different real outcomes
     * (the FR's own distinction) but the system broadcast only ever
     * carries `granted=false` for both -- this re-checks whether the
     * device is still in `deviceList` at the moment the broadcast
     * arrives to tell them apart, and also listens for
     * `ACTION_USB_DEVICE_DETACHED` directly in case the system drops
     * the permission broadcast entirely when the device vanishes
     * mid-dialog (observed to vary by OEM).
     */
    fun requestPermission(deviceId: Int, result: MethodChannel.Result) {
        val device = usbManager.deviceList.values.firstOrNull { it.deviceId == deviceId }
        if (device == null) {
            result.success(mapOf("result" to "detached_meanwhile"))
            return
        }
        if (usbManager.hasPermission(device)) {
            result.success(mapOf("result" to "granted"))
            return
        }

        val mainHandler = Handler(Looper.getMainLooper())
        val resultSent = AtomicBoolean(false)
        var permissionReceiver: BroadcastReceiver? = null

        fun sendOnce(response: Map<String, Any?>) {
            if (!resultSent.compareAndSet(false, true)) return
            permissionReceiver?.let {
                try {
                    context.unregisterReceiver(it)
                } catch (e: Exception) {
                    Log.w(TAG, "unregisterReceiver (permission) failed", e)
                }
            }
            mainHandler.post { result.success(response) }
        }

        permissionReceiver =
            object : BroadcastReceiver() {
                override fun onReceive(ctx: Context, intent: Intent) {
                    when (intent.action) {
                        ACTION_USB_PERMISSION -> {
                            val granted =
                                intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                            if (granted) {
                                sendOnce(mapOf("result" to "granted"))
                                return
                            }
                            val stillPresent =
                                usbManager.deviceList.values.any { it.deviceId == deviceId }
                            sendOnce(
                                mapOf(
                                    "result" to
                                        if (stillPresent) "denied" else "detached_meanwhile",
                                ),
                            )
                        }
                        UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                            @Suppress("DEPRECATION")
                            val detached = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                            if (detached?.deviceId == deviceId) {
                                sendOnce(mapOf("result" to "detached_meanwhile"))
                            }
                        }
                    }
                }
            }

        val filter =
            IntentFilter(ACTION_USB_PERMISSION).apply {
                addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
            }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(permissionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(permissionReceiver, filter)
        }

        val permissionIntent = Intent(ACTION_USB_PERMISSION).setPackage(context.packageName)
        val pendingIntent =
            PendingIntent.getBroadcast(
                context,
                deviceId,
                permissionIntent,
                PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )

        try {
            usbManager.requestPermission(device, pendingIntent)
        } catch (e: Exception) {
            sendOnce(mapOf("result" to "exception", "error" to e.toString()))
        }
    }

    /**
     * FR-L912: opens the device, claims its CCID interface, and runs
     * `PC_to_RDR_IccPowerOn` (with voltage fallback) on
     * [CcidTransceiver]'s own worker thread -- never the calling
     * thread. Requires FR-L911's permission to already be granted.
     */
    fun powerOn(deviceId: Int, result: MethodChannel.Result) {
        val device = usbManager.deviceList.values.firstOrNull { it.deviceId == deviceId }
        if (device == null) {
            result.success(mapOf("outcome" to "detached"))
            return
        }
        if (!usbManager.hasPermission(device)) {
            result.success(mapOf("outcome" to "no_permission"))
            return
        }

        val transceiver = transceivers[deviceId] ?: run {
            val opened = openSession(device) ?: run {
                result.success(mapOf("outcome" to "open_failed"))
                return
            }
            transceivers[deviceId] = opened
            opened
        }

        val mainHandler = Handler(Looper.getMainLooper())
        transceiver.executor.execute {
            val powerOnResult = transceiver.powerOnOnWorker()
            val response =
                when (powerOnResult) {
                    is CcidPowerOnResult.Success ->
                        mapOf(
                            "outcome" to "success",
                            "atrHex" to powerOnResult.rawAtr.toHex(),
                            "protocols" to powerOnResult.atr.protocols.toList(),
                            "preferredProtocol" to powerOnResult.atr.preferredProtocol(),
                            "checksumValid" to powerOnResult.atr.checksumValid,
                            "voltage" to powerOnResult.voltage.name,
                            "exchangeLevel" to transceiver.classDescriptor?.exchangeLevel?.name,
                        )
                    is CcidPowerOnResult.Failed ->
                        mapOf(
                            "outcome" to "power_on_failed",
                            "reason" to powerOnResult.reason,
                            "error" to powerOnResult.lastError,
                        )
                }
            mainHandler.post { result.success(response) }
        }
    }

    /**
     * FR-L913: opens a logical channel (`MANAGE CHANNEL`) and selects
     * ISD-R by AID on it, following T=0's `61xx`/`6Cxx` chaining to a
     * final status word -- then closes the channel again. Requires the
     * card to already be powered on ([powerOn]).
     */
    fun selectIsdR(deviceId: Int, result: MethodChannel.Result) {
        val transceiver = transceivers[deviceId]
        if (transceiver == null) {
            result.success(mapOf("outcome" to "not_powered_on"))
            return
        }

        val mainHandler = Handler(Looper.getMainLooper())
        transceiver.executor.execute {
            val openResult = transceiver.sendApduOnWorker(0, ApduChannel.buildManageChannelOpen())
            val response: Map<String, Any?> =
                when (openResult) {
                    is ApduResult.Failed ->
                        mapOf("outcome" to "channel_open_failed", "reason" to openResult.reason)
                    is ApduResult.Response -> {
                        if (!openResult.isSuccess || openResult.data.size != 1) {
                            mapOf(
                                "outcome" to "channel_open_failed",
                                "reason" to "SW=${openResult.sw.toString(16)}",
                            )
                        } else {
                            val channel = openResult.data[0].toInt() and 0xFF
                            val selectResult = transceiver.sendApduOnWorker(
                                channel,
                                ApduChannel.buildSelectByAid(channel, ApduChannel.ISD_R_AID),
                            )
                            // Best-effort cleanup; the outcome we report
                            // is the SELECT result, not the close.
                            transceiver.sendApduOnWorker(
                                channel,
                                ApduChannel.buildManageChannelClose(channel),
                            )
                            when (selectResult) {
                                is ApduResult.Failed ->
                                    mapOf(
                                        "outcome" to "select_failed",
                                        "reason" to selectResult.reason,
                                        "channel" to channel,
                                    )
                                is ApduResult.Response ->
                                    mapOf(
                                        "outcome" to "success",
                                        "channel" to channel,
                                        "sw" to selectResult.sw.toString(16),
                                        "success" to selectResult.isSuccess,
                                        "fciHex" to selectResult.data.toHex(),
                                    )
                            }
                        }
                    }
                }
            mainHandler.post { result.success(response) }
        }
    }

    private fun openSession(device: UsbDevice): CcidTransceiver? {
        val usbInterface = (0 until device.interfaceCount)
            .map(device::getInterface)
            .firstOrNull { it.interfaceClass == UsbConstants.USB_CLASS_CSCID }
            ?: return null
        val endpoints = CcidTransceiver.findBulkEndpoints(usbInterface) ?: return null
        val connection: UsbDeviceConnection = usbManager.openDevice(device) ?: return null
        if (!connection.claimInterface(usbInterface, true)) {
            connection.close()
            return null
        }
        val (bulkOut, bulkIn) = endpoints
        val transceiver = CcidTransceiver(connection, usbInterface, bulkOut, bulkIn)
        Log.i(TAG, "raw descriptors: ${connection.rawDescriptors?.toHex()}")
        return transceiver
    }

    private fun closeSession(deviceId: Int) {
        transceivers.remove(deviceId)?.close()
    }

    private fun emitCurrentList() {
        eventSink?.success(currentReaders())
    }

    private fun currentReaders(): List<Map<String, Any?>> =
        usbManager.deviceList.values
            .filter(::isCcidDevice)
            .map { device ->
                mapOf(
                    "id" to device.deviceId,
                    "name" to (device.productName ?: device.deviceName),
                    "vendorId" to device.vendorId,
                    "productId" to device.productId,
                    "hasPermission" to usbManager.hasPermission(device),
                )
            }

    private fun isCcidDevice(device: UsbDevice): Boolean {
        for (i in 0 until device.interfaceCount) {
            if (device.getInterface(i).interfaceClass == UsbConstants.USB_CLASS_CSCID) return true
        }
        return false
    }

    companion object {
        private const val TAG = "UsbCcidReaders"
        private const val ACTION_USB_PERMISSION = "co.triptel.app.USB_PERMISSION"
    }
}

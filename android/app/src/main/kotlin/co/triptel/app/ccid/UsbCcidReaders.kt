package co.triptel.app.ccid

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
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

    private val receiver =
        object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
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

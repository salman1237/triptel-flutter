package co.triptel.app.ccid

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.EventChannel

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
    }
}

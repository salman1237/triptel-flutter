package co.triptel.app

import android.content.pm.PackageManager
import android.os.Build
import android.telephony.euicc.EuiccManager
import co.triptel.app.ccid.UsbCcidReaders
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val usbCcidReaders by lazy { UsbCcidReaders(applicationContext) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getEsimSupport" -> result.success(esimSupport())
                else -> result.notImplemented()
            }
        }
        // FR-L905: a one-shot OMAPI probe, separate channel so it doesn't
        // get mixed up with the esimSupport() signals above (different
        // concern: "can this app reach the in-tray card at all", not "does
        // the phone have its own eUICC").
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OMAPI_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "probeUiccSecureElement" -> OmapiProbe(applicationContext).probe(result)
                else -> result.notImplemented()
            }
        }
        // FR-L910: USB CCID reader detection/hot-plug. A one-shot
        // MethodChannel for the static "does this device even have USB
        // host mode" check, plus a streaming EventChannel for the live
        // reader list (attach/detach while foregrounded -- see
        // onStart()/onStop() below, never a manifest auto-launch).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CCID_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsbHostFeature" -> result.success(usbCcidReaders.hasUsbHostFeature())
                "requestPermission" -> {
                    val deviceId = call.argument<Int>("deviceId")
                    if (deviceId == null) {
                        result.error("invalid_argument", "deviceId is required", null)
                    } else {
                        usbCcidReaders.requestPermission(deviceId, result)
                    }
                }
                "powerOn" -> {
                    val deviceId = call.argument<Int>("deviceId")
                    if (deviceId == null) {
                        result.error("invalid_argument", "deviceId is required", null)
                    } else {
                        usbCcidReaders.powerOn(deviceId, result)
                    }
                }
                "selectIsdR" -> {
                    val deviceId = call.argument<Int>("deviceId")
                    if (deviceId == null) {
                        result.error("invalid_argument", "deviceId is required", null)
                    } else {
                        usbCcidReaders.selectIsdR(deviceId, result)
                    }
                }
                "readEid" -> {
                    val deviceId = call.argument<Int>("deviceId")
                    if (deviceId == null) {
                        result.error("invalid_argument", "deviceId is required", null)
                    } else {
                        usbCcidReaders.readEid(deviceId, result)
                    }
                }
                "readEuiccInfo2" -> {
                    val deviceId = call.argument<Int>("deviceId")
                    if (deviceId == null) {
                        result.error("invalid_argument", "deviceId is required", null)
                    } else {
                        usbCcidReaders.readEuiccInfo2(deviceId, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CCID_READERS_CHANNEL)
            .setStreamHandler(usbCcidReaders)
    }

    override fun onStart() {
        super.onStart()
        usbCcidReaders.registerReceiver()
    }

    override fun onStop() {
        usbCcidReaders.unregisterReceiver()
        super.onStop()
    }

    // Raw signals only; the verdict (supported / not / unknown) is decided in Dart
    // (lib/features/compatibility/data/esim_support.dart) so it is unit-testable.
    private fun esimSupport(): Map<String, Any?> {
        val sdk = Build.VERSION.SDK_INT
        var hasFeature: Boolean? = null
        var enabled: Boolean? = null
        if (sdk >= Build.VERSION_CODES.P) {
            hasFeature = packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY_EUICC)
            enabled = try {
                (getSystemService(EUICC_SERVICE) as? EuiccManager)?.isEnabled ?: false
            } catch (e: Exception) {
                null
            }
        }
        return mapOf(
            "platform" to "android",
            "osVersion" to Build.VERSION.RELEASE,
            "sdkInt" to sdk,
            "hasEuiccFeature" to hasFeature,
            "euiccEnabled" to enabled,
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
        )
    }

    companion object {
        private const val CHANNEL = "co.triptel.app/esim"
        private const val OMAPI_CHANNEL = "co.triptel.app/omapi"
        private const val CCID_CHANNEL = "co.triptel.app/ccid"
        private const val CCID_READERS_CHANNEL = "co.triptel.app/ccid/readers"
    }
}

package co.triptel.app

import android.content.pm.PackageManager
import android.os.Build
import android.telephony.euicc.EuiccManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getEsimSupport" -> result.success(esimSupport())
                else -> result.notImplemented()
            }
        }
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
    }
}

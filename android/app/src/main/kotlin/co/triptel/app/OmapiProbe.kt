package co.triptel.app

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.se.omapi.SEService
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * FR-L905: a real, on-device test of whether a removable eUICC card
 * already in the phone's SIM tray grants this app's signing certificate
 * access via OMAPI -- the gate `docs/OpenEUICC_Reference.md` section 1.2
 * says is entirely the card's own ARA-M access-control list, not
 * something this repo can configure or predict. This class only
 * observes the real outcome and reports it; it never assumes one.
 *
 * SGP.22's ISD-R (Issuer Security Domain Root) is the fixed applet AID
 * every eUICC profile-management operation goes through -- opening a
 * logical channel to it is the standard way to find out whether the
 * card's access rules let this app in at all, before any lpac/APDU work
 * is attempted (FR-L914 onward).
 *
 * **Must never block the calling thread.** Flutter dispatches
 * `MethodChannel` calls on the platform (main/UI) thread by default, and
 * `SEService`'s internal connection handshake needs that same main
 * looper free to dispatch its own callback -- blocking it with
 * `CountDownLatch.await()` (an earlier version of this class did exactly
 * that) made `bindService` succeed at the Binder level while the actual
 * `OnConnectedListener` callback could never run, producing a false
 * "timed out" on every real device. Confirmed live: logcat showed
 * `OMAPI.SEService: bindService successful` every time, while the probe
 * still reported `service_connect_timeout`.
 */
class OmapiProbe(private val context: Context) {
    private val isdRAid = byteArrayOf(
        0xA0.toByte(), 0x00, 0x00, 0x05, 0x59, 0x10, 0x10,
        0xFF.toByte(), 0xFF.toByte(), 0xFF.toByte(), 0xFF.toByte(),
        0x89.toByte(), 0x00, 0x00, 0x01, 0x00,
    )

    fun probe(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            result.success(mapOf("available" to false, "reason" to "omapi_requires_api28"))
            return
        }

        val mainHandler = Handler(Looper.getMainLooper())
        val resultSent = AtomicBoolean(false)
        var seService: SEService? = null

        fun sendOnce(response: Map<String, Any?>) {
            if (!resultSent.compareAndSet(false, true)) return
            mainHandler.post { result.success(response) }
            try {
                seService?.shutdown()
            } catch (e: Exception) {
                Log.w(TAG, "shutdown failed", e)
            }
        }

        val timeoutRunnable = Runnable {
            Log.w(TAG, "timed out waiting for SEService to connect")
            sendOnce(mapOf("available" to false, "reason" to "service_connect_timeout"))
        }
        // Generous: the real device this was built against took several
        // seconds past a naive 10s guess on a cold bind (see the class
        // doc). This is a one-shot diagnostic the user explicitly
        // triggers, not a hot path, so a longer wait is the right trade.
        mainHandler.postDelayed(timeoutRunnable, 30_000)

        try {
            seService = SEService(context, Executors.newSingleThreadExecutor()) {
                Log.i(TAG, "SEService connected")
                mainHandler.removeCallbacks(timeoutRunnable)
                val response = try {
                    doProbe(seService!!)
                } catch (e: Exception) {
                    Log.w(TAG, "probe failed", e)
                    mapOf(
                        "available" to false,
                        "reason" to "exception",
                        "error" to e.toString(),
                    )
                }
                sendOnce(response)
            }
        } catch (e: Exception) {
            mainHandler.removeCallbacks(timeoutRunnable)
            sendOnce(mapOf(
                "available" to false,
                "reason" to "se_service_init_failed",
                "error" to e.toString(),
            ))
        }
    }

    private fun doProbe(seService: SEService): Map<String, Any?> {
        val readers = seService.readers
        val readerNames = readers.map { it.name }
        val uiccReader = readers.firstOrNull { it.name.startsWith("SIM") }
            ?: return mapOf(
                "available" to false,
                "reason" to "no_uicc_reader",
                "readerNames" to readerNames,
            )

        if (!uiccReader.isSecureElementPresent) {
            return mapOf(
                "available" to false,
                "reason" to "no_se_present",
                "readerNames" to readerNames,
            )
        }

        val session = try {
            uiccReader.openSession()
        } catch (e: Exception) {
            return mapOf(
                "available" to false,
                "reason" to "open_session_failed",
                "readerNames" to readerNames,
                "error" to e.toString(),
            )
        }
        try {
            val channel = session.openLogicalChannel(isdRAid)
            val selectResponse = channel?.selectResponse
            channel?.close()
            return mapOf(
                "available" to true,
                "reason" to "channel_opened",
                "readerNames" to readerNames,
                "selectResponseHex" to selectResponse?.joinToString("") { "%02X".format(it) },
            )
        } catch (e: SecurityException) {
            // The real, expected outcome when the card's ARA-M doesn't
            // list this app's certificate hash -- not an error condition
            // for the probe itself, it's the answer.
            return mapOf(
                "available" to false,
                "reason" to "ara_m_denied",
                "readerNames" to readerNames,
                "error" to e.message,
            )
        } catch (e: Exception) {
            return mapOf(
                "available" to false,
                "reason" to "open_channel_failed",
                "readerNames" to readerNames,
                "error" to e.toString(),
            )
        } finally {
            session.close()
        }
    }

    companion object {
        private const val TAG = "OmapiProbe"
    }
}

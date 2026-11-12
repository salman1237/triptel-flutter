import CoreTelephony
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "co.triptel.app/esim", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { call, result in
        if call.method == "getEsimSupport" {
          result(AppDelegate.esimSupport())
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Same key contract as android MainActivity.kt; the verdict is decided in Dart.
  private static func esimSupport() -> [String: Any?] {
    var machine = utsname()
    uname(&machine)
    let identifier = withUnsafePointer(to: &machine.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
    }
    var embedded: Bool? = nil
    if #available(iOS 16.0, *) {
      embedded = CTCellularPlanProvisioning().supportsEmbeddedSIM
    }
    let supportsPlan = CTCellularPlanProvisioning().supportsCellularPlan()
    return [
      "platform": "ios",
      "osVersion": UIDevice.current.systemVersion,
      "supportsCellularPlan": supportsPlan,
      "supportsEmbeddedSIM": embedded,
      "manufacturer": "Apple",
      "brand": "Apple",
      "model": identifier,
      "device": UIDevice.current.model,
    ]
  }
}

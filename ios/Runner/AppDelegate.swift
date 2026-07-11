import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AiBridge") {
      AiBridge.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HealthBridge") {
      HealthBridge.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ActivityBridge") {
      ActivityBridge.register(with: registrar)
    }
    // Dart asks where the bridge lives so both sides agree the moment
    // the App Group entitlement appears (Phase 6 widgets); without it
    // this answers with the app container, same as before.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PathsBridge") {
      let channel = FlutterMethodChannel(
        name: "lifeassist/paths", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "bridgeRoot":
          result(BridgePaths.root.path)
        case "legacyBridgeRoot":
          result(BridgePaths.appContainerRoot.path)
        case "todayPublished":
          // Fresh today.json on disk — let the widgets re-read it.
          WidgetCenter.shared.reloadAllTimelines()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}

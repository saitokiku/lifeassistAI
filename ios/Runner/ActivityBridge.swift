// Focus-timer Live Activity control (Phase 6). Dart starts/stops it
// alongside the in-app timer over the `lifeassist/activity` channel;
// the LifeAssistWidgets extension renders it (FocusTimerLiveActivity).
//
// Honesty: the activity mirrors real timer state only. If Live
// Activities are off (user setting, low power) `start` reports false
// and the app carries on — the in-app timer is the source of truth.

import Flutter
import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

enum ActivityBridge {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "lifeassist/activity",
            binaryMessenger: registrar.messenger())
        channel.setMethodCallHandler { call, result in
            Task { @MainActor in
                await handle(call, result)
            }
        }
    }

    @MainActor
    private static func handle(
        _ call: FlutterMethodCall, _ result: @escaping FlutterResult
    ) async {
        #if canImport(ActivityKit)
        switch call.method {
        case "startFocusTimer":
            let args = call.arguments as? [String: Any]
            let label = args?["label"] as? String ?? "Focus"
            let startedAt = (args?["startedAtIso"] as? String)
                .flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                result(false)
                return
            }
            await endAll() // one focus block at a time
            do {
                _ = try Activity<FocusTimerAttributes>.request(
                    attributes: FocusTimerAttributes(
                        label: label, startedAt: startedAt),
                    content: .init(
                        state: FocusTimerAttributes.ContentState(),
                        staleDate: nil))
                result(true)
            } catch {
                result(false)
            }
        case "stopFocusTimer":
            await endAll()
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
        #else
        result(call.method == "startFocusTimer" ? false : nil)
        #endif
    }

    #if canImport(ActivityKit)
    @MainActor
    private static func endAll() async {
        for activity in Activity<FocusTimerAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
    #endif
}

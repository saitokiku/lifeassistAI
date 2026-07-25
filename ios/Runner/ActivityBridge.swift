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
    /// Accepts both ISO-8601 shapes Dart and Swift produce: with
    /// fractional seconds (Dart's toIso8601String) and without
    /// (Swift's default ISO8601DateFormatter). Tried in that order
    /// because a fractional-seconds parser rejects a plain timestamp.
    static func parseIso(_ raw: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime,
                                      .withFractionalSeconds]
        if let date = withFraction.date(from: raw) { return date }
        return ISO8601DateFormatter().date(from: raw)
    }

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
            // Dart's toIso8601String() ALWAYS emits fractional seconds
            // ("2026-07-25T12:00:00.000Z"), which a default-configured
            // ISO8601DateFormatter (.withInternetDateTime only) refuses.
            // Parsing returned nil, the `?? Date()` fired, and every
            // Live Activity started counting from "now" — so a timer
            // restored after a relaunch showed the wrong elapsed time.
            let startedAt = (args?["startedAtIso"] as? String)
                .flatMap(Self.parseIso) ?? Date()
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

// Phase 5 scaffold: HealthKit → auto-habits (see docs/SIRI_AI_BLUEPRINT.md).
//
// Dormant by design until two Mac-side switches flip:
//   1. Xcode → Runner target → Signing & Capabilities → add HealthKit.
//   2. Info.plist → LAHealthKitEnabled → YES.
// Until then `availability` answers "disabledInBuild" and the Dart side
// shows nothing. The flag exists because calling HealthKit APIs without
// the entitlement raises at runtime — a build without the capability
// must never reach them.
//
// Read-only. Values never leave the device; the Dart side writes plain
// source-tagged HabitLogs the user can see and delete like any other.

import Flutter
import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

enum HealthBridge {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "lifeassist/health", binaryMessenger: registrar.messenger())
        channel.setMethodCallHandler { call, result in
            Task { @MainActor in
                await handle(call, result)
            }
        }
    }

    private static var enabledInBuild: Bool {
        Bundle.main.object(forInfoDictionaryKey: "LAHealthKitEnabled")
            as? Bool ?? false
    }

    @MainActor
    private static func handle(
        _ call: FlutterMethodCall, _ result: @escaping FlutterResult
    ) async {
        #if canImport(HealthKit)
        guard enabledInBuild else {
            switch call.method {
            case "availability": result("disabledInBuild")
            default: result(nil)
            }
            return
        }
        guard HKHealthStore.isHealthDataAvailable() else {
            switch call.method {
            case "availability": result("notSupported")
            default: result(nil)
            }
            return
        }
        switch call.method {
        case "availability":
            result("ready")
        case "requestPermission":
            // HealthKit deliberately hides *read* grants: completion only
            // says the sheet ran. Absent data and denied data look the
            // same downstream — the Dart side words itself accordingly.
            do {
                try await Store.shared.store.requestAuthorization(
                    toShare: [], read: Store.readTypes)
                result(true)
            } catch {
                result(false)
            }
        case "dailySummary":
            let args = call.arguments as? [String: Any]
            let dateIso = args?["dateIso"] as? String ?? ""
            result(await Store.shared.dailySummary(dateIso: dateIso))
        default:
            result(FlutterMethodNotImplemented)
        }
        #else
        result(call.method == "availability" ? "notSupported" : nil)
        #endif
    }
}

#if canImport(HealthKit)
private final class Store {
    static let shared = Store()
    let store = HKHealthStore()

    static var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.workoutType()]
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindful)
        }
        return types
    }

    /// Steps, asleep hours, mindful minutes, and workout minutes for one
    /// local calendar day. Missing permission and missing data both come
    /// back as nulls — HealthKit does not distinguish them for reads.
    func dailySummary(dateIso: String) async -> [String: Any?] {
        var day = DateComponents()
        let parts = dateIso.split(separator: "-").compactMap { Int($0) }
        if parts.count == 3 {
            day.year = parts[0]; day.month = parts[1]; day.day = parts[2]
        }
        let calendar = Calendar.current
        guard let start = calendar.date(from: day),
              let end = calendar.date(byAdding: .day, value: 1, to: start)
        else { return ["steps": nil] }

        let dayPredicate = HKQuery.predicateForSamples(
            withStart: start, end: end, options: .strictStartDate)
        // Sleep belongs to the night that *ends* this day: 18:00
        // yesterday through 18:00 today. Consecutive days' windows are
        // disjoint and cover the clock, so a night is never counted
        // twice; sleep after 18:00 today is tomorrow's wake-up.
        let nightPredicate = HKQuery.predicateForSamples(
            withStart: calendar.date(byAdding: .hour, value: -6, to: start),
            end: calendar.date(byAdding: .hour, value: 18, to: start),
            options: [])

        async let steps = sumQuantity(.stepCount, dayPredicate, unit: .count())
        async let sleep = categoryHours(
            .sleepAnalysis, nightPredicate,
            valueFilter: { HKCategoryValueSleepAnalysis.allAsleepValues
                .map(\.rawValue).contains($0) })
        async let mindful = categoryHours(.mindfulSession, dayPredicate)
        async let workouts = workoutMinutes(dayPredicate)

        return await [
            "steps": steps.map { Int($0) },
            "sleepHours": sleep,
            "mindfulMinutes": mindful.map { $0 * 60 },
            "workoutMinutes": workouts,
        ]
    }

    private func sumQuantity(
        _ id: HKQuantityTypeIdentifier,
        _ predicate: NSPredicate,
        unit: HKUnit
    ) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: id) else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type, quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                continuation.resume(
                    returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func categoryHours(
        _ id: HKCategoryTypeIdentifier,
        _ predicate: NSPredicate,
        valueFilter: @escaping (Int) -> Bool = { _ in true }
    ) async -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: id) else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type, predicate: predicate,
                limit: HKObjectQueryNoLimit, sortDescriptors: nil
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample],
                      !samples.isEmpty
                else { return continuation.resume(returning: nil) }
                let seconds = samples
                    .filter { valueFilter($0.value) }
                    .reduce(0.0) {
                        $0 + $1.endDate.timeIntervalSince($1.startDate)
                    }
                continuation.resume(returning: seconds / 3600)
            }
            store.execute(query)
        }
    }

    private func workoutMinutes(_ predicate: NSPredicate) async -> Double? {
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(), predicate: predicate,
                limit: HKObjectQueryNoLimit, sortDescriptors: nil
            ) { _, samples, _ in
                guard let workouts = samples as? [HKWorkout],
                      !workouts.isEmpty
                else { return continuation.resume(returning: nil) }
                let seconds = workouts.reduce(0.0) { $0 + $1.duration }
                continuation.resume(returning: seconds / 60)
            }
            store.execute(query)
        }
    }
}
#endif

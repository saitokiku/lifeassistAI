// Home and lock-screen widgets, an interactive habit check, an
// iOS 18 control, and the focus-timer Live Activity UI.
//
// Everything reads the same today.json the Siri answers use — from the
// App Group container (group.com.saitokiku.lifeassist), which exists
// once that capability is added to both targets on a Mac. Without it,
// widgets honestly say to open the app instead of guessing.
//
// The habit check writes a capture-queue record exactly like Siri's
// background intents do; the app drains it into a real, source-tagged
// HabitLog on next open. Until then the widget shows the habit as
// queued — pending records are part of the truth.

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - today.json (self-contained copy of the Runner-side contract)

private struct HabitDue: Codable, Identifiable {
    let id: String
    let name: String
    let done: Bool
}

private struct TodayFeed: Codable {
    let v: Int
    let dateKey: String?
    let score: Int?
    let upNext: String?
    let habitsDueToday: [HabitDue]?
}

private enum Feed {
    static let appGroupId = "group.com.saitokiku.lifeassist"

    static var bridgeRoot: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent("lifeassist_bridge", isDirectory: true)
    }

    static func load() -> TodayFeed? {
        guard let root = bridgeRoot,
              let data = try? Data(
                contentsOf: root.appendingPathComponent("today.json")),
              let feed = try? JSONDecoder().decode(TodayFeed.self, from: data)
        else { return nil }
        return feed
    }

    static var todayKey: String {
        // Pinned Gregorian/ASCII to match Dart's dateKey on any device
        // locale or calendar setting.
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    /// Habits already checked via a widget tap but not yet drained by
    /// the app — they must render as done, not tappable again.
    static func pendingCheckedHabitIds() -> Set<String> {
        guard let root = bridgeRoot else { return [] }
        let pending = root
            .appendingPathComponent("queue", isDirectory: true)
            .appendingPathComponent("pending", isDirectory: true)
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: pending, includingPropertiesForKeys: nil) else { return [] }
        var ids = Set<String>()
        let iso = ISO8601DateFormatter()
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let record = try? JSONSerialization.jsonObject(with: data)
                    as? [String: Any],
                  record["type"] as? String == "habitLog",
                  let fields = record["fields"] as? [String: Any],
                  let habitId = fields["habitId"] as? String
            else { continue }
            // Only today's queued checks count — a record from before
            // midnight belongs to yesterday's habit, not today's.
            if let createdAt = (record["createdAt"] as? String)
                .flatMap(iso.date(from:)),
               !Calendar.current.isDateInToday(createdAt) {
                continue
            }
            ids.insert(habitId)
        }
        return ids
    }
}

// MARK: - Queue write (mirror of CaptureQueue.swift's record shape)

private enum WidgetQueue {
    static func enqueueHabitCheck(habitId: String, habitName: String) throws {
        guard let root = Feed.bridgeRoot else {
            throw CocoaError(.fileNoSuchFile)
        }
        let dir = root
            .appendingPathComponent("queue", isDirectory: true)
            .appendingPathComponent("pending", isDirectory: true)
        try FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true)
        let id = UUID().uuidString.lowercased()
        let record: [String: Any] = [
            "v": 1,
            "id": id,
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "source": "widget",
            "type": "habitLog",
            "fields": [
                "habitId": habitId,
                "habitName": habitName,
                "value": 1,
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: record)
        let epoch = Int(Date().timeIntervalSince1970 * 1000)
        let tmp = dir.appendingPathComponent("\(epoch)-\(id).tmp")
        try data.write(to: tmp, options: .atomic)
        try FileManager.default.moveItem(
            at: tmp, to: dir.appendingPathComponent("\(epoch)-\(id).json"))
    }
}

/// Interactive check straight from the widget. The record is the same
/// one Siri would write; the app applies it exactly once on next open.
struct CheckHabitFromWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Check habit"
    static let description =
        IntentDescription("Checks off a habit in Life Assist.")

    @Parameter(title: "Habit id") var habitId: String
    @Parameter(title: "Habit name") var habitName: String

    init() {}
    init(habitId: String, habitName: String) {
        self.habitId = habitId
        self.habitName = habitName
    }

    func perform() async throws -> some IntentResult {
        try WidgetQueue.enqueueHabitCheck(
            habitId: habitId, habitName: habitName)
        WidgetCenter.shared.reloadTimelines(ofKind: "LifeAssistHabits")
        return .result()
    }
}

// MARK: - Timeline

private struct Entry: TimelineEntry {
    let date: Date
    let score: Int?
    let upNext: String?
    let habits: [HabitDue]

    static func stale(_ date: Date) -> Entry {
        Entry(date: date, score: nil, upNext: nil, habits: [])
    }
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(
            date: Date(),
            score: 72,
            upNext: "Log today's step toward your goal.",
            habits: [
                HabitDue(id: "a", name: "Walk", done: true),
                HabitDue(id: "b", name: "Read", done: false),
            ])
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let refresh = Calendar.current.date(
            byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [current()], policy: .after(refresh)))
    }

    private func current() -> Entry {
        guard let feed = Feed.load(), feed.dateKey == Feed.todayKey else {
            return .stale(Date())
        }
        let pending = Feed.pendingCheckedHabitIds()
        let habits = (feed.habitsDueToday ?? []).map {
            pending.contains($0.id)
                ? HabitDue(id: $0.id, name: $0.name, done: true)
                : $0
        }
        return Entry(
            date: Date(), score: feed.score, upNext: feed.upNext,
            habits: habits)
    }
}

// MARK: - Views

private struct StaleView: View {
    var body: some View {
        Text("Open Life Assist for a fresh look.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

private struct ScoreView: View {
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            if let score = entry.score {
                Gauge(value: Double(score), in: 0...100) {
                    EmptyView()
                } currentValueLabel: {
                    Text("\(score)").font(.headline)
                }
                .gaugeStyle(.accessoryCircularCapacity)
            } else {
                StaleView()
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

private struct UpNextView: View {
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Up next")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(entry.upNext ?? "Open Life Assist for a fresh look.")
                .font(.footnote)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

private struct HabitsView: View {
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Habits")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            if entry.habits.isEmpty {
                StaleView()
            } else {
                let done = entry.habits.filter(\.done).count
                Text("\(done) of \(entry.habits.count) done")
                    .font(.footnote)
                if let next = entry.habits.first(where: { !$0.done }) {
                    Button(intent: CheckHabitFromWidgetIntent(
                        habitId: next.id, habitName: next.name)
                    ) {
                        HStack(spacing: 6) {
                            Image(systemName: "circle")
                            Text(next.name).lineLimit(1)
                        }
                        .font(.footnote.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("All done today")
                    }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widgets

struct ScoreWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LifeAssistScore", provider: Provider()) {
            ScoreView(entry: $0)
        }
        .configurationDisplayName("Today's score")
        .description("The focus score, only when it's actually today's.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

struct UpNextWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LifeAssistUpNext", provider: Provider()) {
            UpNextView(entry: $0)
        }
        .configurationDisplayName("Up next")
        .description("The one thing Life Assist would point you at now.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct HabitsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LifeAssistHabits", provider: Provider()) {
            HabitsView(entry: $0)
        }
        .configurationDisplayName("Habit check")
        .description("Check off the next habit without opening the app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Control Center (iOS 18+)

@available(iOS 18.0, *)
struct LogExpenseControlIntent: AppIntent {
    static let title: LocalizedStringResource = "Log an expense"
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(
            URL(string: "lifeassist://capture?type=expense")!))
    }
}

@available(iOS 18.0, *)
struct LogExpenseControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "LifeAssistLogExpense") {
            ControlWidgetButton(action: LogExpenseControlIntent()) {
                Label("Log expense", systemImage: "dollarsign.circle")
            }
        }
        .displayName("Log expense")
        .description("Opens Life Assist on a fresh expense entry.")
    }
}

// MARK: - Focus timer Live Activity

#if canImport(ActivityKit)
import ActivityKit

struct FocusTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerAttributes.self) { context in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.label)
                        .font(.headline)
                        .lineLimit(1)
                    Text("Focus block running")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(context.attributes.startedAt, style: .timer)
                    .font(.title2.monospacedDigit())
                    .frame(maxWidth: 90, alignment: .trailing)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.label)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.startedAt, style: .timer)
                        .font(.title3.monospacedDigit())
                        .frame(maxWidth: 80, alignment: .trailing)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text(context.attributes.startedAt, style: .timer)
                    .monospacedDigit()
                    .frame(maxWidth: 44)
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}
#endif

// MARK: - Bundle

@main
struct LifeAssistWidgetBundle: WidgetBundle {
    var body: some Widget {
        ScoreWidget()
        UpNextWidget()
        HabitsWidget()
        #if canImport(ActivityKit)
        FocusTimerLiveActivity()
        #endif
        if #available(iOS 18.0, *) {
            LogExpenseControl()
        }
    }
}

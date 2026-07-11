// Phase 6 scaffold: home/lock-screen widgets over the today.json feed.
//
// NOT part of the Runner target. These sources compile only after
// scripts/ios/add_widget_extension.rb adds the LifeAssistWidgets
// extension target (run it locally on a Mac, or dispatch the iOS
// workflow with build_widget_experiment). The widgets read the same
// today.json the Siri answers use — but from the App Group container,
// which exists once the group.com.saitokiku.lifeassist capability is
// added to both targets.
//
// Honesty contract carried over: numbers render only when the feed is
// from today; otherwise the widget says to open the app rather than
// showing stale figures.

import SwiftUI
import WidgetKit

// MARK: - today.json (self-contained copy of the Runner-side contract)

private struct TodayFeed: Codable {
    let v: Int
    let dateKey: String?
    let score: Int?
    let upNext: String?
}

private enum Feed {
    static let appGroupId = "group.com.saitokiku.lifeassist"

    static func load() -> TodayFeed? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId)
        else { return nil }
        let file = container
            .appendingPathComponent("lifeassist_bridge", isDirectory: true)
            .appendingPathComponent("today.json")
        guard let data = try? Data(contentsOf: file),
              let feed = try? JSONDecoder().decode(TodayFeed.self, from: data)
        else { return nil }
        return feed
    }

    static var todayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

// MARK: - Timeline

private struct Entry: TimelineEntry {
    let date: Date
    let score: Int?
    let upNext: String?

    /// Nil-fielded entry meaning "no fresh picture — open the app".
    static func stale(_ date: Date) -> Entry {
        Entry(date: date, score: nil, upNext: nil)
    }
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), score: 72, upNext: "Log today's step toward your goal.")
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
        return Entry(date: Date(), score: feed.score, upNext: feed.upNext)
    }
}

// MARK: - Views

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
                Text("Open Life Assist for a fresh look.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

@main
struct LifeAssistWidgetBundle: WidgetBundle {
    var body: some Widget {
        ScoreWidget()
        UpNextWidget()
    }
}

// iOS 26/27 Siri AI alignment (docs/SIRI_AI_BLUEPRINT.md Phase 3).
//
// Query intents answer questions from the `today.json` aggregates the
// Flutter shell publishes; confirmation snippets show what a capture did;
// Undo makes voice capture reversible; IndexedEntity puts the app's nouns
// into Spotlight's semantic index (with attribution) so Siri AI's
// personal context can see them.
//
// Honesty rule everywhere: numbers are spoken only when today-fresh —
// stale aggregates get "open the app", never yesterday's totals.
//
// Deliberately NOT here: @AssistantIntent/@AssistantEntity schema macros
// (adopt only after verifying the exact schema names in the shipping SDK
// docs on a Mac — wrong guesses fail the build for no user value), and
// View Annotations (Flutter-rendered UI can't adopt it).

import AppIntents
import Foundation
import SwiftUI

// MARK: - Today aggregates (published by the Flutter shell)

struct TodayMirror: Codable {
    let v: Int
    let generatedAt: String?
    let dateKey: String?
    let monthKey: String?
    let score: Int?
    let upNext: String?
    let timerStartedAt: String?
    let monthSpendCentsByCategory: [String: Int]?
}

enum TodayStore {
    static var file: URL { BridgePaths.root.appendingPathComponent("today.json") }

    static func load() -> TodayMirror? {
        guard let data = try? Data(contentsOf: file),
              let today = try? JSONDecoder().decode(TodayMirror.self, from: data)
        else { return nil }
        return today
    }

    /// Fresh means "generated today on this calendar" — the only state in
    /// which totals may be spoken.
    static func loadFresh() -> TodayMirror? {
        guard let today = load(), let key = today.dateKey else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return key == formatter.string(from: Date()) ? today : nil
    }
}

func centsLabel(_ cents: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = cents % 100 == 0 ? 0 : 2
    return formatter.string(from: NSNumber(value: Double(cents) / 100.0))
        ?? "$\(Double(cents) / 100.0)"
}

// MARK: - Last-capture memory (for voice Undo)

enum LastCapture {
    private static let idKey = "lifeassist.lastCaptureId"
    private static let summaryKey = "lifeassist.lastCaptureSummary"

    static func remember(id: String, summary: String) {
        UserDefaults.standard.set(id, forKey: idKey)
        UserDefaults.standard.set(summary, forKey: summaryKey)
    }

    static func take() -> (id: String, summary: String)? {
        guard let id = UserDefaults.standard.string(forKey: idKey) else {
            return nil
        }
        let summary =
            UserDefaults.standard.string(forKey: summaryKey) ?? "that capture"
        UserDefaults.standard.removeObject(forKey: idKey)
        UserDefaults.standard.removeObject(forKey: summaryKey)
        return (id, summary)
    }
}

// MARK: - Confirmation snippet

/// Rendered inside Siri after a background capture — the receipt.
struct CaptureSnippetView: View {
    let icon: String
    let headline: String
    let detail: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color(red: 0.31, green: 0.82, blue: 0.77))
            VStack(alignment: .leading, spacing: 2) {
                Text(headline).font(.headline)
                if let detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - Voice undo

struct UndoLastCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "Undo the last capture"
    static let description = IntentDescription(
        "Removes the most recent thing you logged by voice.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let last = LastCapture.take() else {
            return .result(dialog: "Nothing recent to undo.")
        }
        // Still waiting in the queue? Deleting the file is the whole undo.
        if CaptureQueue.removePending(id: last.id) {
            return .result(dialog: "Removed \(last.summary).")
        }
        // Already imported: a tombstone unwinds it on the next drain.
        do {
            try CaptureQueue.enqueue(
                type: "undo", fields: ["targetId": last.id])
        } catch {
            throw CaptureFailure.writeFailed
        }
        return .result(
            dialog: "Removed \(last.summary). It disappears from the app the next time it opens.")
    }
}

// MARK: - Query intents (multi-turn follow-up material)

struct GetUpNextIntent: AppIntent {
    static let title: LocalizedStringResource = "What's next"
    static let description = IntentDescription(
        "Asks Life Assist what's most worth doing right now.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let today = TodayStore.loadFresh(), let upNext = today.upNext
        else {
            return .result(
                dialog: "Open Life Assist for a fresh look — I don't have today's picture yet.")
        }
        if let score = today.score {
            return .result(
                dialog: "\(upNext) Today's score is \(score) of 100.")
        }
        return .result(dialog: "\(upNext)")
    }
}

struct GetBudgetStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "Check a budget"
    static let description = IntentDescription(
        "How a budget category stands this month.")

    @Parameter(title: "Category", requestValueDialog: "Which category?")
    var category: BudgetCategoryEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let today = TodayStore.loadFresh(),
              let spendByCategory = today.monthSpendCentsByCategory,
              let spent = spendByCategory[category.id]
        else {
            return .result(
                dialog: "I don't have fresh numbers for \(category.name) — open Life Assist to see the month.")
        }
        let target = EntityStore.load()?.budgetCategories
            .first { $0.id == category.id }?.monthlyTargetCents ?? 0
        if target > 0 {
            let flag = spent > target ? " That's over the target." : ""
            return .result(
                dialog: "\(category.name): \(centsLabel(spent)) of \(centsLabel(target)) this month.\(flag)")
        }
        return .result(
            dialog: "\(category.name): \(centsLabel(spent)) this month.")
    }
}

// MARK: - Semantic indexing (Spotlight / Siri personal context)

@available(iOS 18.0, *)
extension BudgetCategoryEntity: IndexedEntity {}

@available(iOS 18.0, *)
extension TimeBudgetEntity: IndexedEntity {}

@available(iOS 18.0, *)
extension HabitEntity: IndexedEntity {}

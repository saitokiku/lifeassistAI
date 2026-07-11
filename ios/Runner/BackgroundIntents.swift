// Background Siri capture (docs/SIRI_AI_BLUEPRINT.md Phase 2).
//
// These intents run with `openAppWhenRun = false`: iOS launches the app
// process headless (no scene → no Flutter engine), Swift writes a queue
// record inside the app's own sandbox — no App Group entitlement — and
// Siri speaks an honest confirmation with the phone still locked. The
// Dart drain imports the record on the next launch/resume, exactly once.
//
// Honesty rules: voice never invents a category (unknown → uncategorized,
// spoken name preserved); failures are spoken as failures and continue in
// the foreground app, never faked as success.

import AppIntents
import Foundation

// MARK: - Entities (resolved from the Dart-written mirror)

struct BudgetCategoryEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation =
        "Budget category"
    static let defaultQuery = BudgetCategoryQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct BudgetCategoryQuery: EntityStringQuery {
    private func all() -> [BudgetCategoryEntity] {
        (EntityStore.load()?.budgetCategories ?? []).map {
            BudgetCategoryEntity(id: $0.id, name: $0.name)
        }
    }

    func entities(for identifiers: [String]) async throws
        -> [BudgetCategoryEntity] {
        all().filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws
        -> [BudgetCategoryEntity] {
        EntityStore.match(all(), string) { $0.name }
    }

    func suggestedEntities() async throws -> [BudgetCategoryEntity] {
        all()
    }
}

struct TimeBudgetEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation =
        "Time category"
    static let defaultQuery = TimeBudgetQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct TimeBudgetQuery: EntityStringQuery {
    private func all() -> [TimeBudgetEntity] {
        (EntityStore.load()?.timeBudgets ?? []).map {
            TimeBudgetEntity(id: $0.id, name: $0.name)
        }
    }

    func entities(for identifiers: [String]) async throws -> [TimeBudgetEntity] {
        all().filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [TimeBudgetEntity] {
        EntityStore.match(all(), string) { $0.name }
    }

    func suggestedEntities() async throws -> [TimeBudgetEntity] {
        all()
    }
}

struct HabitEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Habit"
    static let defaultQuery = HabitQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct HabitQuery: EntityStringQuery {
    private func all() -> [HabitEntity] {
        (EntityStore.load()?.habits ?? []).map {
            HabitEntity(id: $0.id, name: $0.name)
        }
    }

    func entities(for identifiers: [String]) async throws -> [HabitEntity] {
        all().filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [HabitEntity] {
        EntityStore.match(all(), string) { $0.name }
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        all()
    }
}

// MARK: - Shared helpers

enum CaptureFailure: Error, CustomLocalizedStringResourceConvertible {
    case badInput(String)
    case writeFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .badInput(let message):
            return "\(message)"
        case .writeFailed:
            return "Couldn't save that. Open Life Assist and it will pick it up."
        }
    }
}

private func dollars(_ cents: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    return formatter.string(from: NSNumber(value: Double(cents) / 100.0))
        ?? "$\(Double(cents) / 100.0)"
}

// MARK: - Background capture intents

struct LogExpenseBackgroundIntent: AppIntent {
    static let title: LocalizedStringResource = "Log an expense"
    static let description = IntentDescription(
        "Saves an expense without opening the app.")

    @Parameter(title: "Amount", requestValueDialog: "How much was it?")
    var amount: Double

    @Parameter(title: "Category")
    var category: BudgetCategoryEntity?

    @Parameter(title: "What for", requestValueDialog: "What was it for?")
    var note: String?

    func perform() async throws
        -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let cents = Int((amount * 100).rounded())
        guard cents > 0, cents < 100_000_000 else {
            throw CaptureFailure.badInput("That amount didn't make sense.")
        }
        var fields: [String: Any] = ["amountCents": cents]
        if let note, !note.isEmpty { fields["text"] = note }
        if let category {
            fields["categoryId"] = category.id
            fields["categoryName"] = category.name
        }
        let id: String
        do {
            id = try CaptureQueue.enqueue(type: "expense", fields: fields)
        } catch {
            throw CaptureFailure.writeFailed
        }
        let target = category?.name ?? "uncategorized"
        LastCapture.remember(id: id, summary: "the \(dollars(cents)) expense")

        // Month-to-date context — spoken only when today-fresh, and the
        // just-captured amount is added in so the number is true.
        var detail: String?
        if let category,
           let today = TodayStore.loadFresh(),
           let spent = today.monthSpendCentsByCategory?[category.id] {
            detail =
                "\(category.name) this month: \(centsLabel(spent + cents))"
        }
        return .result(
            dialog: "Logged \(dollars(cents)) to \(target). Say 'undo that "
                + "in Life Assist' to take it back.",
            view: CaptureSnippetView(
                icon: "dollarsign.circle",
                headline: "\(dollars(cents)) · \(target)",
                detail: detail
            )
        )
    }
}

struct LogTimeBackgroundIntent: AppIntent {
    static let title: LocalizedStringResource = "Log time"
    static let description = IntentDescription(
        "Saves hours against a category without opening the app.")

    @Parameter(title: "Hours", requestValueDialog: "How many hours?")
    var hours: Double

    @Parameter(title: "Category", requestValueDialog: "Toward what?")
    var category: TimeBudgetEntity

    @Parameter(title: "Note")
    var note: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard hours > 0, hours <= 24 else {
            throw CaptureFailure.badInput("Hours need to be between 0 and 24.")
        }
        var fields: [String: Any] = [
            "hours": hours,
            "budgetId": category.id,
            "budgetName": category.name,
        ]
        if let note, !note.isEmpty { fields["note"] = note }
        let id: String
        do {
            id = try CaptureQueue.enqueue(type: "time", fields: fields)
        } catch {
            throw CaptureFailure.writeFailed
        }
        let amount = hours == 1 ? "1 hour" : "\(hours) hours"
        LastCapture.remember(id: id, summary: "the \(amount) on \(category.name)")
        return .result(dialog: "Logged \(amount) on \(category.name).")
    }
}

struct ParkIdeaBackgroundIntent: AppIntent {
    static let title: LocalizedStringResource = "Park an idea"
    static let description = IntentDescription(
        "Parks an idea in the lot without opening the app.")

    @Parameter(title: "Idea", requestValueDialog: "What's the idea?")
    var idea: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let text = idea.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw CaptureFailure.badInput("The idea came through empty.")
        }
        let id: String
        do {
            id = try CaptureQueue.enqueue(type: "idea", fields: ["text": text])
        } catch {
            throw CaptureFailure.writeFailed
        }
        LastCapture.remember(id: id, summary: "that idea")
        return .result(
            dialog: "Parked. It cools for a week before you decide.")
    }
}

struct AddReminderBackgroundIntent: AppIntent {
    static let title: LocalizedStringResource = "Add a reminder"
    static let description = IntentDescription(
        "Creates a reminder without opening the app.")

    @Parameter(title: "Remind me to", requestValueDialog: "Remind you to do what?")
    var text: String

    @Parameter(title: "When", requestValueDialog: "When should it fire?")
    var when: Date?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let title = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw CaptureFailure.badInput("The reminder came through empty.")
        }

        let calendar = Calendar.current
        let fireDate = when ?? calendar.date(
            bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        let hour = calendar.component(.hour, from: fireDate)
        let minute = calendar.component(.minute, from: fireDate)
        // A date on a future day means "once, that day"; otherwise the
        // reminder repeats daily at the given time (editable in-app).
        let isFutureDay = when != nil &&
            !calendar.isDateInToday(fireDate) && fireDate > Date()

        let armed = await CaptureQueue.armReminder(
            title: title,
            hour: hour,
            minute: minute,
            oneShotDate: isFutureDay ? fireDate : nil
        )

        var fields: [String: Any] = [
            "text": title,
            "hour": hour,
            "minute": minute,
        ]
        if isFutureDay {
            fields["oneShotDateIso"] =
                ISO8601DateFormatter().string(from: fireDate)
        }
        let id: String
        do {
            id = try CaptureQueue.enqueue(
                type: "reminder",
                fields: fields,
                notification: armed
            )
        } catch {
            throw CaptureFailure.writeFailed
        }
        LastCapture.remember(id: id, summary: "that reminder")

        let clock = String(format: "%d:%02d", hour, minute)
        let cadence = isFutureDay ? "once" : "daily"
        let suffix = armed.armed
            ? "" : " Open the app once to allow notifications."
        return .result(
            dialog: "Reminder set, \(cadence) at \(clock).\(suffix)")
    }
}

struct CheckHabitBackgroundIntent: AppIntent {
    static let title: LocalizedStringResource = "Check off a habit"
    static let description = IntentDescription(
        "Marks a habit done for today without opening the app.")

    @Parameter(title: "Habit", requestValueDialog: "Which habit?")
    var habit: HabitEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let id: String
        do {
            id = try CaptureQueue.enqueue(type: "habitLog", fields: [
                "habitId": habit.id,
                "habitName": habit.name,
                "value": 1,
            ])
        } catch {
            throw CaptureFailure.writeFailed
        }
        LastCapture.remember(id: id, summary: "the \(habit.name) check")
        return .result(dialog: "\(habit.name): done for today.")
    }
}

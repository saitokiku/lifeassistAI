// Siri / Shortcuts entry points for Life Assist (App Intents).
//
// The foreground half of voice capture: every intent here is a
// lightweight FOREGROUND intent that opens the app
// on a `lifeassist://capture?...` deep link. The Flutter capture bus
// parses the URL, opens the matching sheet prefilled, and the user
// confirms with one tap — these intents never write to the database, so
// there is nothing to keep consistent between Swift and drift.
//
// Wired into the Runner target via project.pbxproj (no Xcode step needed).
// Background intents that DO capture without opening the app live in
// BackgroundIntents.swift.

import AppIntents
import UIKit

struct LogExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Log an expense and review"
    static let description = IntentDescription(
        "Opens Life Assist with a prefilled expense to confirm.")
    static let openAppWhenRun = true

    @Parameter(title: "Amount", requestValueDialog: "How much was it?")
    var amount: Double

    @Parameter(title: "What for", requestValueDialog: "What was it for?")
    var note: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        var components = URLComponents()
        components.scheme = "lifeassist"
        components.host = "capture"
        components.queryItems = [
            URLQueryItem(name: "type", value: "expense"),
            URLQueryItem(name: "amount", value: String(amount)),
        ]
        if let note, !note.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "text", value: note))
        }
        if let url = components.url {
            await UIApplication.shared.open(url)
        }
        return .result()
    }
}

struct LogTimeIntent: AppIntent {
    static let title: LocalizedStringResource = "Log time and review"
    static let description = IntentDescription(
        "Opens Life Assist with prefilled hours to confirm.")
    static let openAppWhenRun = true

    @Parameter(title: "Hours", requestValueDialog: "How many hours?")
    var hours: Double

    @Parameter(title: "Category", requestValueDialog: "Which category?")
    var category: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        var components = URLComponents()
        components.scheme = "lifeassist"
        components.host = "capture"
        components.queryItems = [
            URLQueryItem(name: "type", value: "time"),
            URLQueryItem(name: "hours", value: String(hours)),
        ]
        if let category, !category.isEmpty {
            components.queryItems?.append(
                URLQueryItem(name: "category", value: category))
        }
        if let url = components.url {
            await UIApplication.shared.open(url)
        }
        return .result()
    }
}

struct LogStepIntent: AppIntent {
    static let title: LocalizedStringResource = "Log today's step"
    static let description = IntentDescription(
        "Opens Life Assist to log the day's step toward your goal.")
    static let openAppWhenRun = true

    @Parameter(title: "What you did", requestValueDialog: "What did you do?")
    var text: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        var components = URLComponents()
        components.scheme = "lifeassist"
        components.host = "capture"
        components.queryItems = [URLQueryItem(name: "type", value: "step")]
        if let text, !text.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "text", value: text))
        }
        if let url = components.url {
            await UIApplication.shared.open(url)
        }
        return .result()
    }
}

struct ParkIdeaIntent: AppIntent {
    static let title: LocalizedStringResource = "Park an idea and review"
    static let description = IntentDescription(
        "Opens Life Assist with the idea title prefilled.")
    static let openAppWhenRun = true

    @Parameter(title: "Idea", requestValueDialog: "What's the idea?")
    var idea: String

    @MainActor
    func perform() async throws -> some IntentResult {
        var components = URLComponents()
        components.scheme = "lifeassist"
        components.host = "capture"
        components.queryItems = [
            URLQueryItem(name: "type", value: "idea"),
            URLQueryItem(name: "text", value: idea),
        ]
        if let url = components.url {
            await UIApplication.shared.open(url)
        }
        return .result()
    }
}

struct AddReminderIntent: AppIntent {
    static let title: LocalizedStringResource = "Add a reminder and review"
    static let description = IntentDescription(
        "Opens Life Assist with a new reminder prefilled.")
    static let openAppWhenRun = true

    @Parameter(title: "Remind me to", requestValueDialog: "Remind you to do what?")
    var title_: String

    @MainActor
    func perform() async throws -> some IntentResult {
        var components = URLComponents()
        components.scheme = "lifeassist"
        components.host = "capture"
        components.queryItems = [
            URLQueryItem(name: "type", value: "reminder"),
            URLQueryItem(name: "text", value: title_),
        ]
        if let url = components.url {
            await UIApplication.shared.open(url)
        }
        return .result()
    }
}

/// The phrases Siri listens for without any user setup ("Hey Siri, log an
/// expense in Life Assist"). Phrases point at the BACKGROUND intents —
/// captures land with the phone locked; the "…and review" foreground
/// variants stay available in the Shortcuts app. The daily step keeps its
/// foreground flow on purpose: the outcome verdict is the user's call.
struct LifeAssistShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseBackgroundIntent(),
            phrases: [
                "Log an expense in \(.applicationName)",
                "Add an expense to \(.applicationName)",
            ],
            shortTitle: "Log expense",
            systemImageName: "dollarsign.circle"
        )
        AppShortcut(
            intent: LogTimeBackgroundIntent(),
            phrases: [
                "Log time in \(.applicationName)",
                "Log hours in \(.applicationName)",
            ],
            shortTitle: "Log time",
            systemImageName: "clock"
        )
        AppShortcut(
            intent: LogStepIntent(),
            phrases: [
                "Log my step in \(.applicationName)",
                "Log today's step in \(.applicationName)",
            ],
            shortTitle: "Log step",
            systemImageName: "figure.walk"
        )
        AppShortcut(
            intent: ParkIdeaBackgroundIntent(),
            phrases: [
                "Park an idea in \(.applicationName)",
                "Save an idea in \(.applicationName)",
            ],
            shortTitle: "Park idea",
            systemImageName: "lightbulb"
        )
        AppShortcut(
            intent: AddReminderBackgroundIntent(),
            phrases: [
                "Add a reminder in \(.applicationName)",
                "Remind me in \(.applicationName)",
            ],
            shortTitle: "Add reminder",
            systemImageName: "bell"
        )
        AppShortcut(
            intent: CheckHabitBackgroundIntent(),
            phrases: [
                "Check off a habit in \(.applicationName)",
                "Mark a habit done in \(.applicationName)",
            ],
            shortTitle: "Check habit",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: GetUpNextIntent(),
            phrases: [
                "What's next in \(.applicationName)",
                "What should I do in \(.applicationName)",
            ],
            shortTitle: "What's next",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: UndoLastCaptureIntent(),
            phrases: [
                "Undo that in \(.applicationName)",
                "Undo the last capture in \(.applicationName)",
            ],
            shortTitle: "Undo capture",
            systemImageName: "arrow.uturn.backward"
        )
    }
}

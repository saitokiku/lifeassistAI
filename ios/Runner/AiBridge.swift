// On-device AI via Apple's Foundation Models framework (iOS 26+).
//
// The `lifeassist/ai` MethodChannel exposes four capabilities to Dart:
//   availability() -> String state
//   parseCapture(text, categoryNames, timeBudgetNames, habitNames)
//       -> [CaptureDraft JSON]  (compound utterances yield several)
//   categorizeTransactions(rows, categoryNames) -> [{id, category}]
//   draftWeeklyReview(stats) -> String
//   triageIdea(text) -> {title, whyTempting, potentialValue}
//
// Guardrails: guided generation constrains category/budget/habit names to
// the caller-provided lists — the model cannot invent one; every AI
// output goes through the same user-confirmed sheets as manual input
// (zero silent writes); everything runs on-device (no Private Cloud
// Compute in v1), so nothing leaves the phone.
//
// The whole file is compiled out on SDKs without FoundationModels; at
// runtime, pre-iOS-26 devices answer `osTooOld` and the Dart surfaces
// hide themselves.

import Flutter
import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
@Generable
struct CaptureDraft {
    @Guide(description: "One of: expense, time, idea, reminder, habit")
    var kind: String

    @Guide(description: "Money amount in integer cents, only for expense")
    var amountCents: Int?

    @Guide(description: "Hours spent, only for time entries")
    var hours: Double?

    @Guide(description: "Short human text: what it was, the idea, or the reminder")
    var text: String?

    @Guide(description: "EXACT category/budget/habit name from the provided lists, or omit")
    var categoryName: String?

    @Guide(description: "ISO date yyyy-MM-dd if the user said a day like 'yesterday', else omit")
    var dateIso: String?
}

@available(iOS 26.0, *)
@Generable
struct CaptureDrafts {
    @Guide(description: "Every distinct thing the user wants logged, in order")
    var drafts: [CaptureDraft]
}

@available(iOS 26.0, *)
@Generable
struct CategorySuggestion {
    @Guide(description: "The row id exactly as given")
    var id: String

    @Guide(description: "EXACT category name from the provided list")
    var category: String
}

@available(iOS 26.0, *)
@Generable
struct CategorySuggestions {
    var suggestions: [CategorySuggestion]
}

@available(iOS 26.0, *)
@Generable
struct IdeaTriage {
    @Guide(description: "A crisp title for the idea, under 60 characters")
    var title: String

    @Guide(description: "One sentence: why it feels tempting right now")
    var whyTempting: String

    @Guide(description: "One sentence: the potential value if it works")
    var potentialValue: String
}
#endif

/// Registers the channel; every call answers gracefully on devices or
/// SDKs without Apple Intelligence.
enum AiBridge {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "lifeassist/ai",
            binaryMessenger: registrar.messenger()
        )
        channel.setMethodCallHandler { call, result in
            Task { await handle(call, result: result) }
        }
    }

    private static func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) async {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            await Available.handle(call, result: result)
            return
        }
        #endif
        // No SDK / OS support: availability says so, everything else
        // reports unavailable rather than pretending.
        if call.method == "availability" {
            result("osTooOld")
        } else {
            result(FlutterError(
                code: "unavailable",
                message: "On-device AI needs iOS 26 or later.",
                details: nil
            ))
        }
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
private enum Available {
    static func availabilityString() -> String {
        switch SystemLanguageModel.default.availability {
        case .available:
            return "available"
        case .unavailable(.deviceNotEligible):
            return "deviceNotEligible"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "appleIntelligenceNotEnabled"
        case .unavailable(.modelNotReady):
            return "modelNotReady"
        case .unavailable:
            return "unavailable"
        @unknown default:
            return "unavailable"
        }
    }

    static func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) async {
        switch call.method {
        case "availability":
            result(availabilityString())

        case "parseCapture":
            guard availabilityString() == "available",
                  let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String
            else {
                result(FlutterError(
                    code: "unavailable", message: nil, details: nil))
                return
            }
            let categories = args["categoryNames"] as? [String] ?? []
            let budgets = args["timeBudgetNames"] as? [String] ?? []
            let habits = args["habitNames"] as? [String] ?? []
            let today = args["todayIso"] as? String ?? ""
            do {
                let session = LanguageModelSession(instructions: """
                You turn one casual utterance into structured capture \
                drafts for a personal life dashboard. Today is \(today). \
                Money amounts become integer cents. Use ONLY these names \
                when one clearly matches, otherwise omit the name field. \
                Budget categories: \(categories.joined(separator: ", ")). \
                Time categories: \(budgets.joined(separator: ", ")). \
                Habits: \(habits.joined(separator: ", ")). \
                Never invent amounts, names, or dates that were not said.
                """)
                let response = try await session.respond(
                    to: text,
                    generating: CaptureDrafts.self
                )
                let drafts = response.content.drafts.map { draft in
                    [
                        "kind": draft.kind,
                        "amountCents": draft.amountCents as Any,
                        "hours": draft.hours as Any,
                        "text": draft.text as Any,
                        "categoryName": draft.categoryName as Any,
                        "dateIso": draft.dateIso as Any,
                    ]
                }
                result(drafts)
            } catch {
                result(FlutterError(
                    code: "generation",
                    message: error.localizedDescription,
                    details: nil
                ))
            }

        case "categorizeTransactions":
            guard availabilityString() == "available",
                  let args = call.arguments as? [String: Any],
                  let rows = args["rows"] as? [[String: Any]],
                  let categories = args["categoryNames"] as? [String],
                  !categories.isEmpty
            else {
                result(FlutterError(
                    code: "unavailable", message: nil, details: nil))
                return
            }
            do {
                let lines = rows.compactMap { row -> String? in
                    guard let id = row["id"] as? String,
                          let text = row["description"] as? String
                    else { return nil }
                    return "\(id): \(text)"
                }
                let session = LanguageModelSession(instructions: """
                Assign each bank-statement line to the best-fitting \
                category from EXACTLY this list: \
                \(categories.joined(separator: ", ")). \
                Skip lines that fit none — never force a match.
                """)
                let response = try await session.respond(
                    to: lines.joined(separator: "\n"),
                    generating: CategorySuggestions.self
                )
                result(response.content.suggestions
                    .filter { categories.contains($0.category) }
                    .map { ["id": $0.id, "category": $0.category] })
            } catch {
                result(FlutterError(
                    code: "generation",
                    message: error.localizedDescription,
                    details: nil
                ))
            }

        case "draftWeeklyReview":
            guard availabilityString() == "available",
                  let args = call.arguments as? [String: Any],
                  let stats = args["stats"] as? String
            else {
                result(FlutterError(
                    code: "unavailable", message: nil, details: nil))
                return
            }
            do {
                let session = LanguageModelSession(instructions: """
                Draft a short, honest weekly reflection (3-4 sentences, \
                first person, plain words, no cheerleading) from these \
                real numbers. Mention one thing that worked and one \
                friction. Never invent events that are not in the data.
                """)
                let response = try await session.respond(to: stats)
                result(response.content)
            } catch {
                result(FlutterError(
                    code: "generation",
                    message: error.localizedDescription,
                    details: nil
                ))
            }

        case "triageIdea":
            guard availabilityString() == "available",
                  let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String
            else {
                result(FlutterError(
                    code: "unavailable", message: nil, details: nil))
                return
            }
            do {
                let session = LanguageModelSession(instructions: """
                Expand a raw idea note into the parking-lot worksheet. \
                Stay faithful to what was said; no embellishment.
                """)
                let response = try await session.respond(
                    to: text,
                    generating: IdeaTriage.self
                )
                result([
                    "title": response.content.title,
                    "whyTempting": response.content.whyTempting,
                    "potentialValue": response.content.potentialValue,
                ])
            } catch {
                result(FlutterError(
                    code: "generation",
                    message: error.localizedDescription,
                    details: nil
                ))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
#endif

// Shared between the Runner app (which starts/ends the activity via
// ActivityBridge.swift) and the LifeAssistWidgets extension (which
// renders it). The struct must stay byte-identical in both targets —
// it is compiled into each, matched by name and Codable shape.

import Foundation

#if canImport(ActivityKit)
import ActivityKit

struct FocusTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // The timer renders from `startedAt`; nothing changes mid-flight.
        public init() {}
    }

    /// What the block is for — the time budget's name.
    var label: String

    /// When the timer started; lock screen and island count up from it.
    var startedAt: Date
}
#endif

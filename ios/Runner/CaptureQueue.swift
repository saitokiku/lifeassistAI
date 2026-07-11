// Write side of the Dart↔Swift bridge (see docs/SIRI_AI_BLUEPRINT.md §2).
//
// Background App Intents append one JSON file per capture. Atomic
// tmp+rename makes torn writes impossible; the filename's epoch prefix
// gives the drain a stable order; the record's UUID becomes the database
// row id on the Dart side, so at-least-once processing yields
// exactly-once rows. Money amounts are INTEGER CENTS by contract.

import Foundation
import UserNotifications

enum CaptureQueueError: Error {
    case writeFailed
}

enum CaptureQueue {
    /// Writes a capture record; returns its UUID (the future row id).
    @discardableResult
    static func enqueue(
        type: String,
        fields: [String: Any],
        notification: (id: Int, armed: Bool)? = nil
    ) throws -> String {
        let id = UUID().uuidString.lowercased()
        var record: [String: Any] = [
            "v": 1,
            "id": id,
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "source": "siri",
            "type": type,
            "fields": fields,
        ]
        if let notification {
            record["notification"] = [
                "id": notification.id,
                "armed": notification.armed,
            ]
        }

        do {
            let dir = BridgePaths.pendingDir
            try FileManager.default.createDirectory(
                at: dir, withIntermediateDirectories: true)
            let data = try JSONSerialization.data(withJSONObject: record)
            let epoch = Int(Date().timeIntervalSince1970 * 1000)
            let final = dir.appendingPathComponent("\(epoch)-\(id).json")
            let tmp = dir.appendingPathComponent("\(epoch)-\(id).tmp")
            try data.write(to: tmp, options: .atomic)
            try FileManager.default.moveItem(at: tmp, to: final)
            return id
        } catch {
            throw CaptureQueueError.writeFailed
        }
    }

    /// Deletes a still-pending record (snippet Undo before the app drains).
    static func removePending(id: String) -> Bool {
        let dir = BridgePaths.pendingDir
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil) else { return false }
        for file in files where file.lastPathComponent.contains(id) {
            try? FileManager.default.removeItem(at: file)
            return true
        }
        return false
    }

    // MARK: - Reminder notifications

    /// Arms a provisional local notification for a Siri-created reminder so
    /// it fires even if the app is never opened. The request is shaped to
    /// be indistinguishable from one scheduled by flutter_local_notifications
    /// (pinned to 18.0.1: identifier = String(id); userInfo keys
    /// NotificationId/payload/present*) — on the next app open, Dart stores
    /// this id in the reminder row and re-arms through the plugin, which
    /// cancels this exact identifier first. If the plugin's contract ever
    /// drifts, only pre-first-open tap routing degrades; the next drain
    /// replaces the request entirely.
    ///
    /// Never re-derive ids from Dart's String.hashCode — it is not stable
    /// across Dart releases. The id is random and travels with the record.
    static func armReminder(
        title: String,
        hour: Int,
        minute: Int,
        oneShotDate: Date?
    ) async -> (id: Int, armed: Bool) {
        let id = Int.random(in: 1...0x7FFF_FFFF)
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized ||
              settings.authorizationStatus == .provisional
        else { return (id, false) }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "A reminder you set with Siri."
        content.sound = .default
        content.userInfo = [
            "NotificationId": id,
            "payload": "route:/reminders",
            "presentAlert": true,
            "presentSound": true,
            "presentBadge": false,
            "presentBanner": true,
            "presentList": true,
        ]

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let repeats: Bool
        if let oneShotDate {
            let day = Calendar.current.dateComponents(
                [.year, .month, .day], from: oneShotDate)
            components.year = day.year
            components.month = day.month
            components.day = day.day
            repeats = false
        } else {
            repeats = true
        }

        let request = UNNotificationRequest(
            identifier: String(id),
            content: content,
            trigger: UNCalendarNotificationTrigger(
                dateMatching: components, repeats: repeats)
        )
        do {
            try await center.add(request)
            return (id, true)
        } catch {
            return (id, false)
        }
    }
}

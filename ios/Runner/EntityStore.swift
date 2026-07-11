// Read side of the Dart↔Swift bridge (see docs/SIRI_AI_BLUEPRINT.md §2).
//
// Dart's EntityMirrorService atomically rewrites entities.json whenever
// budgets, categories, or habits change. Siri's entity queries resolve
// against this file — no Flutter engine, no SQL against a migrating
// schema. A missing or unreadable mirror means "no suggestions", never an
// error: queue records also carry the raw spoken text and Dart re-resolves
// at drain time.

import Foundation

struct MirrorEntity: Codable {
    let id: String
    let name: String
}

struct BudgetCategoryMirror: Codable {
    let id: String
    let name: String
    let monthlyTargetCents: Int?
}

struct TimeBudgetMirror: Codable {
    let id: String
    let name: String
    let kind: String
}

struct EntityMirror: Codable {
    let v: Int
    let generatedAt: String?
    let budgetCategories: [BudgetCategoryMirror]
    let timeBudgets: [TimeBudgetMirror]
    let habits: [MirrorEntity]
}

/// Filesystem contract shared with lib/core/native/bridge_paths.dart.
///
/// When the App Group capability is enabled (widgets, Phase 6), both
/// sides automatically move to the shared container: Swift resolves it
/// here, Dart asks the `lifeassist/paths` channel. Without the
/// entitlement `containerURL` returns nil and everything stays in the
/// app's own container — today's behavior, unchanged.
enum BridgePaths {
    /// Must match the App Group the user adds in Xcode (Phase 6) and
    /// scripts/ios/add_widget_extension.rb.
    static let appGroupId = "group.com.kaizen.lifeDashboard"

    static var root: URL {
        if let group = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId) {
            return group.appendingPathComponent(
                "lifeassist_bridge", isDirectory: true)
        }
        return appContainerRoot
    }

    /// Pre-App-Group location; Dart still drains leftovers from here
    /// after the group container takes over.
    static var appContainerRoot: URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("lifeassist_bridge", isDirectory: true)
    }

    static var entitiesFile: URL {
        root.appendingPathComponent("entities.json")
    }

    static var pendingDir: URL {
        root.appendingPathComponent("queue", isDirectory: true)
            .appendingPathComponent("pending", isDirectory: true)
    }
}

enum EntityStore {
    static func load() -> EntityMirror? {
        guard let data = try? Data(contentsOf: BridgePaths.entitiesFile),
              let mirror = try? JSONDecoder().decode(EntityMirror.self, from: data),
              mirror.v >= 1
        else { return nil }
        return mirror
    }

    /// Case-insensitive contains-match over a name list.
    static func match<T>(_ items: [T], _ needle: String, name: (T) -> String) -> [T] {
        let query = needle.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return items }
        return items.filter { name($0).lowercased().contains(query) }
    }
}

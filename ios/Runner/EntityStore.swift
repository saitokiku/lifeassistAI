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

struct TimeBudgetMirror: Codable {
    let id: String
    let name: String
    let kind: String
}

struct EntityMirror: Codable {
    let v: Int
    let generatedAt: String?
    let budgetCategories: [MirrorEntity]
    let timeBudgets: [TimeBudgetMirror]
    let habits: [MirrorEntity]
}

/// Filesystem contract shared with lib/core/native/bridge_paths.dart.
enum BridgePaths {
    static var root: URL {
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

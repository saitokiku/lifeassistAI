import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Filesystem contract shared with the Swift side (EntityStore.swift and
/// CaptureQueue.swift read/write the same paths). Everything lives under
/// Application Support so it never shows in the user-visible Documents
/// tree and is backed up with the app.
///
/// entities.json        — Dart-written mirror the Swift EntityQueries read
/// today.json           — Dart-written aggregates for Siri answers/widgets
/// queue/pending/*.json — Swift-written captures the Dart drain consumes
/// queue/failed/*.json  — records the drain could not read (diagnostics)
class BridgePaths {
  BridgePaths(this.root, {this.legacyRoot});

  /// Production root. iOS answers through the `lifeassist/paths` channel
  /// so Dart and Swift always agree: the shared App Group container once
  /// its entitlement exists (widgets), the app's own container
  /// until then. Platforms without the channel fall back directly.
  static Future<BridgePaths> resolve() async {
    final support = await getApplicationSupportDirectory();
    final fallback = Directory('${support.path}/lifeassist_bridge');
    try {
      const channel = MethodChannel('lifeassist/paths');
      final root = await channel.invokeMethod<String>('bridgeRoot');
      if (root == null || root.isEmpty) return BridgePaths(fallback);
      final legacy = await channel.invokeMethod<String>('legacyBridgeRoot');
      return BridgePaths(
        Directory(root),
        // Records written before the App Group appeared still get
        // drained; same path twice means no legacy dir to check.
        legacyRoot: legacy != null && legacy != root
            ? Directory(legacy)
            : null,
      );
    } on MissingPluginException {
      return BridgePaths(fallback);
    } on PlatformException {
      return BridgePaths(fallback);
    }
  }

  final Directory root;

  /// Pre-App-Group location, only set when it differs from [root].
  final Directory? legacyRoot;

  File get entitiesFile => File('${root.path}/entities.json');
  Directory get pendingDir => Directory('${root.path}/queue/pending');
  Directory get failedDir => Directory('${root.path}/queue/failed');

  /// Pending dir from before the container move, if any.
  Directory? get legacyPendingDir => legacyRoot == null
      ? null
      : Directory('${legacyRoot!.path}/queue/pending');

  Future<void> ensureDirs() async {
    await pendingDir.create(recursive: true);
    await failedDir.create(recursive: true);
  }
}

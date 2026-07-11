import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Filesystem contract shared with the Swift side (EntityStore.swift and
/// CaptureQueue.swift read/write the same paths). Everything lives under
/// Application Support so it never shows in the user-visible Documents
/// tree and is backed up with the app.
///
/// entities.json        — Dart-written mirror the Swift EntityQueries read
/// queue/pending/*.json — Swift-written captures the Dart drain consumes
/// queue/failed/*.json  — records the drain could not read (diagnostics)
class BridgePaths {
  BridgePaths(this.root);

  /// Production root: `<Application Support>/lifeassist_bridge`.
  static Future<BridgePaths> resolve() async {
    final support = await getApplicationSupportDirectory();
    return BridgePaths(Directory('${support.path}/lifeassist_bridge'));
  }

  final Directory root;

  File get entitiesFile => File('${root.path}/entities.json');
  Directory get pendingDir => Directory('${root.path}/queue/pending');
  Directory get failedDir => Directory('${root.path}/queue/failed');

  Future<void> ensureDirs() async {
    await pendingDir.create(recursive: true);
    await failedDir.create(recursive: true);
  }
}

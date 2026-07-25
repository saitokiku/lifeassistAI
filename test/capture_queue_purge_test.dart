import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/native/bridge_paths.dart';
import 'package:life_dashboard/core/native/capture_queue_drain.dart';
import 'package:life_dashboard/core/storage/app_database.dart';

/// "Reset all data" must also empty the Siri capture queue: records
/// written before the reset would otherwise drain on the next foreground
/// and re-insert data the user just erased.
void main() {
  late Directory temp;
  late Directory legacyTemp;
  late AppDatabase db;
  late BridgePaths paths;
  late CaptureQueueDrain drain;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('queue_purge_test');
    legacyTemp = await Directory.systemTemp.createTemp('queue_purge_legacy');
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    paths = BridgePaths(temp, legacyRoot: legacyTemp);
    drain = CaptureQueueDrain(db, paths);
    await paths.ensureDirs();
  });

  tearDown(() async {
    await db.close();
    await temp.delete(recursive: true);
    await legacyTemp.delete(recursive: true);
  });

  test('purgeAll empties pending, legacy-pending, and failed', () async {
    File pending(String name) => File('${paths.pendingDir.path}/$name');
    final legacyDir = paths.legacyPendingDir!;
    await legacyDir.create(recursive: true);

    await pending('1-a.json').writeAsString('{"v":1}');
    await pending('2-b.json').writeAsString('{"v":1}');
    await File('${legacyDir.path}/0-old.json').writeAsString('{"v":1}');
    await File('${paths.failedDir.path}/broken.json')
        .writeAsString('not json');

    await drain.purgeAll();

    expect(paths.pendingDir.listSync().whereType<File>(), isEmpty);
    expect(legacyDir.listSync().whereType<File>(), isEmpty);
    expect(paths.failedDir.listSync().whereType<File>(), isEmpty);
  });

  test('purgeAll on empty or missing directories is a no-op', () async {
    await drain.purgeAll();
    await drain.purgeAll(); // twice: still fine
    expect(paths.pendingDir.existsSync(), isTrue);
  });
}

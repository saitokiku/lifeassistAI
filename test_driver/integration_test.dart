import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Receives screenshots from integration_test/screenshots_test.dart and
/// writes them under screenshots/ (CI uploads that directory as the
/// AppStoreScreenshots artifact).
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}

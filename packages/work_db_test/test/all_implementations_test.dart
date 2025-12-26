@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:work_db/work_db.dart';
import 'package:work_db_test/work_db_test.dart';

/// Runs the complete test suite against all WorkDB implementations.
///
/// This is the main entry point for testing all storage backends:
/// - Memory (in-memory storage)
/// - Web (localStorage-like storage)
/// - IO (file system storage)
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('work_db_all_tests_');
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  // ==================== Memory Tests ====================
  group('Memory WorkDB', () {
    setUp(() {
      WorkDbFactory.reset();
    });

    testIWorkDb(() => WorkDbFactory.createMemory());
  });

  // ==================== Web Tests ====================
  group('Web WorkDB', () {
    setUp(() {
      WorkDbFactory.reset();
    });

    testIWorkDb(() => WorkDbFactory.createWeb(storage: MapWebStorage()));
  });

  // ==================== IO Tests ====================
  group('IO WorkDB', () {
    var ioTestCounter = 0;

    setUp(() {
      WorkDbFactory.reset();
    });

    testIWorkDb(() {
      ioTestCounter++;
      final testDir = Directory('${tempDir.path}/io_test_$ioTestCounter');
      testDir.createSync(recursive: true);
      return WorkDbFactory.createIo(dataPath: testDir.path);
    });
  });
}

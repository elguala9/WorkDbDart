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

  // ==================== Memory Tests ==================== // IA
  group('Memory WorkDB', () { // IA
    late WorkDbFactory factory; // IA
    setUp(() { // IA
      factory = WorkDbFactory(); // IA
      factory.reset(); // IA
    }); // IA
    testIWorkDb(() => factory.createNew(MemoryWorkDbFactoryInput())); // IA
  }); // IA

  // ==================== Web Tests ==================== // IA
  group('Web WorkDB', () { // IA
    late WorkDbFactory factory; // IA
    setUp(() { // IA
      factory = WorkDbFactory(); // IA
      factory.reset(); // IA
    }); // IA
    testIWorkDb(() => factory.createNew(WebWorkDbFactoryInput(webStorage: MapWebStorage()))); // IA
  }); // IA

  // ==================== IO Tests ==================== // IA
  group('IO WorkDB', () { // IA
    var ioTestCounter = 0; // IA
    late WorkDbFactory factory; // IA
    setUp(() { // IA
      factory = WorkDbFactory(); // IA
      factory.reset(); // IA
    }); // IA
    testIWorkDb(() { // IA
      ioTestCounter++; // IA
      final testDir = Directory('${tempDir.path}/io_test_$ioTestCounter'); // IA
      testDir.createSync(recursive: true); // IA
      return factory.createNew(IoWorkDbFactoryInput(dataPath: testDir.path)); // IA
    }); // IA
  }); // IA
}

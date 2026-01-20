@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:work_db/work_db.dart';
import 'package:work_db_test/work_db_test.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    // Create a temporary directory for all tests
    tempDir = await Directory.systemTemp.createTemp('work_db_io_test_');
  });

  tearDownAll(() async {
    // Clean up after all tests
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('IO WorkDB', () { // IA
    var testCounter = 0; // IA
    late WorkDbFactory factory; // IA
    setUp(() { // IA
      factory = WorkDbFactory(); // IA
      factory.reset(); // IA
    }); // IA
    testIWorkDb(() { // IA
      testCounter++; // IA
      final testDir = Directory('${tempDir.path}/test_$testCounter'); // IA
      testDir.createSync(recursive: true); // IA
      return factory.createNew(IoWorkDbFactoryInput(dataPath: testDir.path)); // IA
    }); // IA
  }); // IA
}

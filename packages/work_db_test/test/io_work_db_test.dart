@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:work_db/work_db.dart';
import 'package:work_db_test/work_db_test.dart';

void main() {
  late Directory tempDir;
  final factory = WorkDbFactory();

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

  group('IO WorkDB', () {
    var testCounter = 0;

    testIWorkDb(() {
      testCounter++;
      final testDir = Directory('${tempDir.path}/test_$testCounter');
      testDir.createSync(recursive: true);
      return factory.create(IoWorkDbFactoryInput(dataPath: testDir.path));
    });
  });
}

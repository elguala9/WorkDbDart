import 'package:test/test.dart';
import 'package:work_db/work_db.dart';
import 'package:work_db_test/work_db_test.dart';

void main() {
  final factory = WorkDbFactory();

  group('Memory WorkDB', () {
    testIWorkDb(() => factory.create(MemoryWorkDbFactoryInput()));
  });

  group('Memory WorkDB with max records', () {
    testIWorkDbWithMaxRecords(() => factory.create(
          MemoryWorkDbFactoryInput(maxRecordsPerCollection: 3),
        ) as ClientWorkDb);
  });
}

import 'package:test/test.dart';
import 'package:work_db/work_db.dart';
import 'package:work_db_test/work_db_test.dart';

void main() {
  final factory = WorkDbFactory();

  group('Web WorkDB', () {
    testIWorkDb(
      () => factory.create(WebWorkDbFactoryInput(webStorage: MapWebStorage())),
    );
  });

  group('Web WorkDB with max records', () {
    testIWorkDbWithMaxRecords(() => factory.create(
          WebWorkDbFactoryInput(
            webStorage: MapWebStorage(),
            maxRecordsPerCollection: 3,
          ),
        ) as ClientWorkDb);
  });
}

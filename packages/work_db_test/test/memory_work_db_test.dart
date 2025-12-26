import 'package:test/test.dart';
import 'package:work_db/work_db.dart';
import 'package:work_db_test/work_db_test.dart';

void main() {
  // Reset singleton before tests
  WorkDbFactory.reset();

  group('Memory WorkDB', () {
    testIWorkDb(() {
      // Create a fresh memory instance for each test
      return WorkDbFactory.createMemory();
    });
  });
}

import 'package:test/test.dart';
import 'package:work_db/work_db.dart';
import 'package:work_db_test/work_db_test.dart';

void main() {
  // Reset singleton before tests
  WorkDbFactory.reset();

  group('Web WorkDB', () {
    testIWorkDb(() {
      // Create a fresh web instance for each test with a new MapWebStorage
      return WorkDbFactory.createWeb(storage: MapWebStorage());
    });
  });
}

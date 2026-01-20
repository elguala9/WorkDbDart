import 'package:test/test.dart';
import 'package:work_db/work_db.dart';
import 'package:work_db_test/work_db_test.dart';

void main() { // IA
  late WorkDbFactory factory; // IA
  setUp(() { // IA
    factory = WorkDbFactory(); // IA
    factory.reset(); // IA
  }); // IA
  group('Memory WorkDB', () { // IA
    testIWorkDb(() => factory.createNew(MemoryWorkDbFactoryInput())); // IA
  }); // IA
} // IA

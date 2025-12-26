/// WorkDB - A cross-platform local database for Dart.
///
/// This library provides implementations of the WorkDB interfaces
/// for multiple platforms: Desktop (IO), Web, and Mobile.
///
/// ## Getting Started
///
/// ```dart
/// import 'package:work_db/work_db.dart';
///
/// void main() async {
///   // Create instance for your platform
///   final db = WorkDbFactory.forIo(dataPath: './data');
///
///   // Create an item
///   await db.create(ItemWithId(
///     id: 'user-1',
///     collection: 'users',
///     item: {'name': 'John'},
///   ));
///
///   // Retrieve it
///   final user = await db.retrieve(ItemId(
///     id: 'user-1',
///     collection: 'users',
///   ));
///   print(user?.item['name']); // John
/// }
/// ```
library work_db;

// Export types and interfaces
export 'src/i_work_db.dart';
export 'src/i_work_file_system.dart';
export 'src/types.dart';

// Core implementation
export 'src/client_work_db.dart';

// Factories
export 'src/factories/work_db_factory.dart';

// Platform implementations
export 'src/implementations/io_work_db.dart';
export 'src/implementations/memory_work_db.dart';
export 'src/implementations/web_work_db.dart';

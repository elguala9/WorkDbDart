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
///   // Simple usage with WorkDb factory
///   final db = WorkDb.memory();
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

// Types and exceptions
export 'src/exceptions.dart';
export 'src/types.dart';

// Interfaces
export 'src/interfaces/i_lock_manager.dart';
export 'src/interfaces/i_lock_manager_sync.dart';
export 'src/interfaces/i_path_validator.dart';
export 'src/interfaces/i_work_db.dart';
export 'src/interfaces/i_work_db_sync.dart';
export 'src/interfaces/i_work_file_system.dart';
export 'src/interfaces/i_work_file_system_sync.dart';

// Implementations
export 'src/implementations/client_work_db.dart';
export 'src/implementations/platforms/io_work_db.dart';
export 'src/implementations/lock_manager.dart';
export 'src/implementations/lock_manager_sync.dart';
export 'src/implementations/platforms/memory_work_db.dart';
export 'src/implementations/path_validator.dart';
export 'src/implementations/platforms/web_work_db.dart';
export 'src/implementations/platforms/work_db.dart';


// Factories
export 'src/factories/work_db_factory.dart';

import '../client_work_db.dart';
import 'io_work_db.dart';
import 'memory_work_db.dart';
import 'web_work_db.dart';

/// Convenience class with static factory methods for creating [ClientWorkDb].
///
/// Provides simple methods to create database instances for each environment
/// without requiring configuration parameters.
///
/// ## Usage
///
/// ```dart
/// // In-memory database (for testing)
/// final db = WorkDb.memory();
///
/// // File-based database (desktop/server)
/// final db = WorkDb.io();
///
/// // Web storage database
/// final db = WorkDb.web();
/// ```
class WorkDb {
  WorkDb._();

  /// Creates an in-memory database instance.
  ///
  /// Data is lost when the application terminates.
  /// Ideal for testing and temporary storage.
  static ClientWorkDb memory() => ClientWorkDb(MemoryWorkDb());

  /// Creates a file-based database instance.
  ///
  /// Uses the current working directory as the base path.
  /// Data is persisted to the file system.
  static ClientWorkDb io() => ClientWorkDb(IoWorkDb('./DefaultWorkDb'));

  /// Creates a web storage database instance.
  ///
  /// Uses [MapWebStorage] as the backend.
  /// In a real browser environment, you should use an adapter
  /// for `window.localStorage`.
  static ClientWorkDb web() => ClientWorkDb(WebWorkDb());
}

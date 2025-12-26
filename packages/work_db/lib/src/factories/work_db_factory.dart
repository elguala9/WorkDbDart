import '../client_work_db.dart';
import '../implementations/io_work_db.dart';
import '../implementations/memory_work_db.dart';
import '../implementations/web_work_db.dart';

/// Supported platform types for WorkDB.
enum PlatformType {
  /// Desktop/Server platforms using dart:io
  io,

  /// Web platform using localStorage
  web,

  /// In-memory storage (for testing)
  memory,
}

/// Configuration options for creating a WorkDB instance.
class WorkDbConfig {
  /// Creates a new configuration.
  ///
  /// [platform] is required and determines which implementation to use.
  /// [dataPath] is used for IO platform (defaults to './data').
  /// [webStorage] can be provided for custom web storage implementation.
  const WorkDbConfig({
    required this.platform,
    this.dataPath = './data',
    this.webStorage,
  });

  /// The target platform type.
  final PlatformType platform;

  /// The base path for file storage (used by [PlatformType.io]).
  final String dataPath;

  /// Optional custom web storage (used by [PlatformType.web]).
  final IWebStorage? webStorage;
}

/// Factory for creating WorkDB instances.
///
/// This class provides convenient methods for creating database instances
/// for different platforms.
///
/// ## Usage
///
/// ```dart
/// // Create for desktop/server
/// final db = WorkDbFactory.forIo(dataPath: './my_data');
///
/// // Create for web
/// final db = WorkDbFactory.forWeb();
///
/// // Create for testing
/// final db = WorkDbFactory.forMemory();
///
/// // Auto-detect platform (advanced)
/// final db = createWorkDb(WorkDbConfig(platform: detectPlatform()));
/// ```
abstract final class WorkDbFactory {
  /// Creates a WorkDB instance for Desktop/Server platforms (dart:io).
  ///
  /// [dataPath] is the base directory for database files.
  /// Defaults to './data'.
  ///
  /// This uses file system storage and is suitable for:
  /// - Windows desktop apps
  /// - macOS desktop apps
  /// - Linux desktop apps
  /// - Server-side Dart applications
  ///
  /// Example:
  /// ```dart
  /// final db = WorkDbFactory.forIo(dataPath: '/home/user/.myapp/data');
  /// ```
  static ClientWorkDb forIo({String dataPath = './data'}) {
    final ioImpl = IoWorkDb(dataPath);
    return ClientWorkDb.getInstance(ioImpl);
  }

  /// Creates a new (non-singleton) WorkDB instance for Desktop/Server.
  ///
  /// Use this when you need multiple independent database instances.
  ///
  /// [dataPath] is the base directory for database files.
  ///
  /// Example:
  /// ```dart
  /// final db1 = WorkDbFactory.createIo(dataPath: './db1');
  /// final db2 = WorkDbFactory.createIo(dataPath: './db2');
  /// ```
  static ClientWorkDb createIo({String dataPath = './data'}) {
    final ioImpl = IoWorkDb(dataPath);
    return ClientWorkDb.createInstance(ioImpl);
  }

  /// Creates a WorkDB instance for Web platform.
  ///
  /// [storage] is an optional custom storage implementation.
  /// If not provided, uses [MapWebStorage] (in-memory for non-browser).
  ///
  /// In a browser environment, you would pass an adapter for
  /// `window.localStorage`.
  ///
  /// Example:
  /// ```dart
  /// // In browser
  /// final db = WorkDbFactory.forWeb(storage: browserStorageAdapter);
  ///
  /// // For testing
  /// final db = WorkDbFactory.forWeb();
  /// ```
  static ClientWorkDb forWeb({IWebStorage? storage}) {
    final webImpl = WebWorkDb(storage);
    return ClientWorkDb.getInstance(webImpl);
  }

  /// Creates a new (non-singleton) WorkDB instance for Web.
  ///
  /// Use this when you need multiple independent database instances.
  ///
  /// [storage] is an optional custom storage implementation.
  static ClientWorkDb createWeb({IWebStorage? storage}) {
    final webImpl = WebWorkDb(storage);
    return ClientWorkDb.createInstance(webImpl);
  }

  /// Creates a WorkDB instance using in-memory storage.
  ///
  /// This is ideal for:
  /// - Unit testing
  /// - Temporary/ephemeral data
  /// - Quick prototyping
  ///
  /// **Note**: All data is lost when the application terminates.
  ///
  /// Example:
  /// ```dart
  /// final db = WorkDbFactory.forMemory();
  /// // Data is stored only in memory
  /// ```
  static ClientWorkDb forMemory() {
    final memoryImpl = MemoryWorkDb();
    return ClientWorkDb.getInstance(memoryImpl);
  }

  /// Creates a new (non-singleton) WorkDB instance for memory.
  ///
  /// Use this when you need multiple independent database instances.
  ///
  /// Example:
  /// ```dart
  /// final testDb = WorkDbFactory.createMemory();
  /// // Each call creates a fresh instance
  /// ```
  static ClientWorkDb createMemory() {
    final memoryImpl = MemoryWorkDb();
    return ClientWorkDb.createInstance(memoryImpl);
  }

  /// Resets all singleton instances.
  ///
  /// This is primarily useful for testing to ensure a clean state.
  ///
  /// **Warning**: Should not be used in production code.
  static void reset() {
    ClientWorkDb.resetInstance();
  }
}

/// Creates a WorkDB instance based on the provided configuration.
///
/// [config] specifies the platform and options.
///
/// Example:
/// ```dart
/// final db = createWorkDb(WorkDbConfig(
///   platform: PlatformType.io,
///   dataPath: './custom_path',
/// ));
/// ```
ClientWorkDb createWorkDb(WorkDbConfig config) {
  switch (config.platform) {
    case PlatformType.io:
      return WorkDbFactory.forIo(dataPath: config.dataPath);
    case PlatformType.web:
      return WorkDbFactory.forWeb(storage: config.webStorage);
    case PlatformType.memory:
      return WorkDbFactory.forMemory();
  }
}

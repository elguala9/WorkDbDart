import '../implementations/client_work_db.dart';
import '../implementations/platforms/io_work_db.dart';
import '../implementations/platforms/memory_work_db.dart';
import '../implementations/platforms/web_work_db.dart';

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

/// Base class for factory input types.
///
/// Each implementation has its own input class that extends this.
abstract class WorkDbFactoryInput {
  const WorkDbFactoryInput();
}

/// Input configuration for creating an [IoWorkDb] instance.
///
/// Example:
/// ```dart
/// final db = factory.create(IoWorkDbFactoryInput(dataPath: './data'));
/// ```
class IoWorkDbFactoryInput extends WorkDbFactoryInput {
  /// Creates input for IO-based storage.
  ///
  /// [dataPath] is the base directory for storing database files.
  const IoWorkDbFactoryInput({required this.dataPath});

  /// The base path for file storage.
  final String dataPath;
}

/// Input configuration for creating a [WebWorkDb] instance.
///
/// Example:
/// ```dart
/// final db = factory.create(WebWorkDbFactoryInput());
/// ```
class WebWorkDbFactoryInput extends WorkDbFactoryInput {
  /// Creates input for web-based storage.
  ///
  /// [webStorage] is an optional custom storage implementation.
  /// If not provided, defaults to [MapWebStorage].
  const WebWorkDbFactoryInput({this.webStorage});

  /// Optional custom web storage implementation.
  final IWebStorage? webStorage;
}

/// Input configuration for creating a [MemoryWorkDb] instance.
///
/// Example:
/// ```dart
/// final db = factory.create(MemoryWorkDbFactoryInput());
/// ```
class MemoryWorkDbFactoryInput extends WorkDbFactoryInput {
  /// Creates input for in-memory storage.
  const MemoryWorkDbFactoryInput();
}

/// Interface for WorkDB factory implementations.
abstract class IWorkDbFactory {
  /// Creates a database instance based on the provided input type.
  ClientWorkDb create(WorkDbFactoryInput input);
}

/// Factory for creating WorkDB instances.
///
/// Supports polymorphic creation using dedicated input types for each
/// implementation (IO, Web, Memory).
///
/// Each call to [create] returns a new independent instance.
///
/// Example:
/// ```dart
/// final factory = WorkDbFactory();
///
/// // For desktop/server
/// final ioDb = factory.create(IoWorkDbFactoryInput(dataPath: './data'));
///
/// // For web
/// final webDb = factory.create(WebWorkDbFactoryInput());
///
/// // For testing
/// final memDb = factory.create(MemoryWorkDbFactoryInput());
///
/// // Multiple independent instances
/// final db1 = factory.create(IoWorkDbFactoryInput(dataPath: './data1'));
/// final db2 = factory.create(IoWorkDbFactoryInput(dataPath: './data2'));
/// // db1 and db2 are completely independent
/// ```
class WorkDbFactory implements IWorkDbFactory {
  @override
  ClientWorkDb create(WorkDbFactoryInput input) {
    if (input is IoWorkDbFactoryInput) {
      return ClientWorkDb(IoWorkDb(input.dataPath));
    }
    if (input is WebWorkDbFactoryInput) {
      return ClientWorkDb(WebWorkDb(input.webStorage));
    }
    if (input is MemoryWorkDbFactoryInput) {
      return ClientWorkDb(MemoryWorkDb());
    }
    throw ArgumentError('Unsupported input type: ${input.runtimeType}');
  }
}

/// Creates a WorkDB instance using configuration.
///
/// This is a convenience function for creating database instances
/// using the [WorkDbConfig] class.
///
/// Example:
/// ```dart
/// final db = createWorkDb(WorkDbConfig(
///   platform: PlatformType.io,
///   dataPath: './data',
/// ));
/// ```
ClientWorkDb createWorkDb(WorkDbConfig config) {
  final factory = WorkDbFactory();
  switch (config.platform) {
    case PlatformType.io:
      return factory.create(IoWorkDbFactoryInput(dataPath: config.dataPath));
    case PlatformType.web:
      return factory.create(WebWorkDbFactoryInput(webStorage: config.webStorage));
    case PlatformType.memory:
      return factory.create(MemoryWorkDbFactoryInput());
  }
}

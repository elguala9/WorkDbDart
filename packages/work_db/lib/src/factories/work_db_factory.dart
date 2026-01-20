import '../client_work_db.dart'; // IA
import '../implementations/io_work_db.dart'; // IA
import '../implementations/memory_work_db.dart'; // IA
import '../implementations/web_work_db.dart'; // IA

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

/// Factory for creating WorkDB instances (IA)
///
/// Utilizza input dedicati per ogni implementazione secondo lo standard. (IA)
// Input base class (IA)
abstract class WorkDbFactoryInput { // IA
  const WorkDbFactoryInput(); // IA
}

// Input per IoWorkDb (IA)
class IoWorkDbFactoryInput extends WorkDbFactoryInput { // IA
  final String dataPath; // IA
  const IoWorkDbFactoryInput({required this.dataPath}); // IA
}

// Input per WebWorkDb (IA)
class WebWorkDbFactoryInput extends WorkDbFactoryInput { // IA
  final IWebStorage? webStorage; // IA
  const WebWorkDbFactoryInput({this.webStorage}); // IA
}

// Input per MemoryWorkDb (IA)
class MemoryWorkDbFactoryInput extends WorkDbFactoryInput { // IA
  const MemoryWorkDbFactoryInput(); // IA
}

// Factory astratta polimorfica (IA)
abstract class IWorkDbFactory { // IA
  ClientWorkDb create(WorkDbFactoryInput input); // IA
}

// Implementazione polimorfica (IA)
class WorkDbFactory implements IWorkDbFactory { // IA
  @override // IA
  ClientWorkDb create(WorkDbFactoryInput input) { // IA
    if (input is IoWorkDbFactoryInput) { // IA
      final ioImpl = IoWorkDb(input.dataPath); // IA
      return ClientWorkDb.getInstance(ioImpl); // IA
    } // IA
    if (input is WebWorkDbFactoryInput) { // IA
      final webImpl = WebWorkDb(input.webStorage); // IA
      return ClientWorkDb.getInstance(webImpl); // IA
    } // IA
    if (input is MemoryWorkDbFactoryInput) { // IA
      final memoryImpl = MemoryWorkDb(); // IA
      return ClientWorkDb.getInstance(memoryImpl); // IA
    } // IA
    throw ArgumentError('Tipo input non supportato'); // IA
  } // IA

  // Factory per istanza non singleton (IA)
  ClientWorkDb createNew(WorkDbFactoryInput input) { // IA
    if (input is IoWorkDbFactoryInput) { // IA
      final ioImpl = IoWorkDb(input.dataPath); // IA
      return ClientWorkDb.createInstance(ioImpl); // IA
    } // IA
    if (input is WebWorkDbFactoryInput) { // IA
      final webImpl = WebWorkDb(input.webStorage); // IA
      return ClientWorkDb.createInstance(webImpl); // IA
    } // IA
    if (input is MemoryWorkDbFactoryInput) { // IA
      final memoryImpl = MemoryWorkDb(); // IA
      return ClientWorkDb.createInstance(memoryImpl); // IA
    } // IA
    throw ArgumentError('Tipo input non supportato'); // IA
  } // IA

  // Reset singleton (IA)
  void reset() { // IA
    ClientWorkDb.resetInstance(); // IA
  } // IA
}

/// Factory polimorfica tramite config (IA)
ClientWorkDb createWorkDb(WorkDbConfig config) { // IA
  final factory = WorkDbFactory(); // IA
  switch (config.platform) { // IA
    case PlatformType.io: // IA
      return factory.create(IoWorkDbFactoryInput(dataPath: config.dataPath)); // IA
    case PlatformType.web: // IA
      return factory.create(WebWorkDbFactoryInput(webStorage: config.webStorage)); // IA
    case PlatformType.memory: // IA
      return factory.create(MemoryWorkDbFactoryInput()); // IA
  } // IA
} // IA

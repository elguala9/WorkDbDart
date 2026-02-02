import '../interfaces/i_lock_manager.dart';
import '../interfaces/i_work_file_system.dart';
import '../types.dart';

/// File-based implementation of [ILockManager].
///
/// Lock files are stored in a parallel directory structure:
/// - Data: `./WorkDB/collection/item`
/// - Lock: `./WorkDBLocks/collection/item.lock`
///
/// ## Usage
///
/// ```dart
/// final lockManager = LockManager(fileSystem);
///
/// if (await lockManager.tryAcquire('users/user-1')) {
///   try {
///     // perform operation
///   } finally {
///     await lockManager.release('users/user-1');
///   }
/// }
/// ```
class LockManager implements ILockManager {
  LockManager(this._fs);

  final IWorkFileSystem _fs;

  /// Root directory for lock files.
  static const String _lockRoot = './WorkDBLocks';

  /// Converts a document path to its corresponding lock path.
  String _toLockPath(String documentPath) {
    // ./WorkDB/collection/item -> ./WorkDBLocks/collection/item.lock
    final relativePath = documentPath.replaceFirst('./WorkDB/', '');
    return '$_lockRoot/$relativePath.lock';
  }

  @override
  Future<bool> tryAcquire(String documentPath) async {
    final lockPath = _toLockPath(documentPath);

    // Check if lock exists
    if (await _fs.exist(lockPath)) {
      return false; // Already locked
    }

    // Create lock file
    await _fs.writeFile(
      lockPath,
      Item(item: {
        'lockedAt': DateTime.now().toIso8601String(),
      }),
    );

    return true;
  }

  @override
  Future<void> release(String documentPath) async {
    final lockPath = _toLockPath(documentPath);

    if (await _fs.exist(lockPath)) {
      await _fs.deleteFile(lockPath);
    }
  }

  @override
  Future<bool> isLocked(String documentPath) async {
    final lockPath = _toLockPath(documentPath);
    return _fs.exist(lockPath);
  }

  @override
  Future<void> clearAllLocks() async {
    await _fs.deleteFolder(_lockRoot);
  }
}

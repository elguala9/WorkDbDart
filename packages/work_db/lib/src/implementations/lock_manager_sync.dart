import '../exceptions.dart';
import '../interfaces/i_lock_manager_sync.dart';
import '../interfaces/i_work_file_system_sync.dart';
import '../types.dart';

/// Synchronous file-based implementation of [ILockManagerSync].
///
/// Lock files are stored in a parallel directory structure:
/// - Data: `./WorkDB/collection/item`
/// - Lock: `./WorkDBLocks/collection/item.lock`
///
/// ## Usage
///
/// ```dart
/// final lockManager = LockManagerSync(fileSystem);
///
/// if (lockManager.tryAcquireSync('users/user-1')) {
///   try {
///     // perform operation
///   } finally {
///     lockManager.releaseSync('users/user-1');
///   }
/// }
/// ```
class LockManagerSync implements ILockManagerSync {
  /// Creates a new [LockManagerSync].
  ///
  /// [_fs] is the synchronous file system implementation.
  /// [_waitingMs] is the timeout in milliseconds for stale lock detection.
  /// If 0 (default), uses simple lock mechanism without stale lock cleanup.
  /// If > 0, expired locks are cleaned up automatically.
  LockManagerSync(this._fs, [this._waitingMs = 0]);

  final IWorkFileSystemSync _fs;
  final int _waitingMs;
  final int _lockTimeMs = 5000;

  /// Root directory for lock files.
  static const String _lockRoot = './WorkDBLocks';

  /// Converts a document path to its corresponding lock path.
  String _toLockPath(String documentPath) {
    final relativePath = documentPath.replaceFirst('./WorkDB/', '');
    return '$_lockRoot/$relativePath.lock';
  }

  /// Reads lock information from a lock file synchronously.
  _LockInfo? _readLockInfo(String lockPath) {
    try {
      if (!_fs.existSync(lockPath)) return null;
      final file = _fs.getFileSync(lockPath);
      final unlockAt = file.item['unlockAt'] as String?;
      final user = file.item['user'] as String?;
      if (unlockAt == null || user == null) return null;
      return _LockInfo(unlockAt, user);
    } catch (e) {
      return null;
    }
  }

  /// Writes lock information to a lock file synchronously.
  void _writeLockInfo(String lockPath, String user) {
    final now = DateTime.now();
    final unlockAt = now.add(Duration(milliseconds: _lockTimeMs));
    _fs.writeFileSync(
      lockPath,
      Item(item: {
        'unlockAt': unlockAt.toIso8601String(),
        'user': user,
        'lockedAt': now.toIso8601String(),
      }),
    );
  }

  /// Checks if a lock has expired based on its unlockAt time.
  bool _isLockExpired(String unlockAtIso) {
    try {
      final unlockAt = DateTime.parse(unlockAtIso);
      return DateTime.now().isAfter(unlockAt);
    } catch (e) {
      return false;
    }
  }

  void _deleteAndWriteLockInfo(String lockPath, String user) {
    _fs.deleteFileSync(lockPath);
    _writeLockInfo(lockPath, user);
  }

  @override
  bool tryAcquireSync(String documentPath) {
    final lockPath = _toLockPath(documentPath);
    const userId = 'system';

    final lockInfo = _readLockInfo(lockPath);

    if (lockInfo == null) {
      _writeLockInfo(lockPath, userId);
      return true;
    }

    if (_isLockExpired(lockInfo.unlockAt)) {
      _deleteAndWriteLockInfo(lockPath, userId);
      return true;
    }

    if (_waitingMs > 0) {
      DateTime unlockAt;
      try {
        unlockAt = DateTime.parse(lockInfo.unlockAt);
      } on FormatException {
        _deleteAndWriteLockInfo(lockPath, userId);
        return true;
      }

      final timeUntilExpiry =
          unlockAt.difference(DateTime.now()).inMilliseconds;

      if (timeUntilExpiry <= _waitingMs) {
        // Sync: busy-wait until lock expires
        final deadline = DateTime.now().add(Duration(milliseconds: timeUntilExpiry + 10));
        while (DateTime.now().isBefore(deadline)) {
          // spin
        }
        _deleteAndWriteLockInfo(lockPath, userId);
        return true;
      }
    }

    return false;
  }

  /// Attempts to acquire a lock synchronously, throwing if already locked.
  ///
  /// Throws [LockAcquisitionException] if the lock is already held.
  void tryAcquireThrowSync(String documentPath) {
    final lockPath = _toLockPath(documentPath);
    const userId = 'system';

    final lockInfo = _readLockInfo(lockPath);

    if (lockInfo == null) {
      _writeLockInfo(lockPath, userId);
      return;
    }

    if (_waitingMs > 0 && _isLockExpired(lockInfo.unlockAt)) {
      _fs.deleteFileSync(lockPath);
      _writeLockInfo(lockPath, userId);
      return;
    }

    throw LockAcquisitionException(
      'Lock is already held for: $documentPath',
      documentPath: documentPath,
    );
  }

  @override
  void releaseSync(String documentPath) {
    final lockPath = _toLockPath(documentPath);
    if (_fs.existSync(lockPath)) {
      try {
        _fs.deleteFileSync(lockPath);
      } catch (_) {
        // Ignore deletion errors
      }
    }
  }

  @override
  bool isLockedSync(String documentPath) {
    final lockPath = _toLockPath(documentPath);
    return _fs.existSync(lockPath);
  }

  @override
  void clearAllLocksSync() {
    _fs.deleteFolderSync(_lockRoot);
  }
}

class _LockInfo {
  _LockInfo(this.unlockAt, this.user);
  final String unlockAt;
  final String user;
}

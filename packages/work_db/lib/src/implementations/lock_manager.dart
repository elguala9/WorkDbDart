import '../exceptions.dart';
import '../interfaces/i_lock_manager.dart';
import '../interfaces/i_work_file_system.dart';
import '../types.dart';

class LockInfo {
  LockInfo(this.unlockAt, this.user);
  final String unlockAt;
  final String user;
}

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
  /// Creates a new [LockManager].
  ///
  /// [_fs] is the file system implementation.
  /// [_waitingMs] is the timeout in milliseconds for lock acquisition.
  /// If 0 (default), uses simple lock mechanism without retry logic.
  /// If > 0, implements timeout-based lock with automatic stale lock cleanup.
  LockManager(this._fs, [this._waitingMs = 0]);

  final IWorkFileSystem _fs;
  final int _waitingMs;
  final int _lockTimeMs = 5000;

  /// Root directory for lock files.
  static const String _lockRoot = './WorkDBLocks';

  /// Converts a document path to its corresponding lock path.
  String _toLockPath(String documentPath) {
    // ./WorkDB/collection/item -> ./WorkDBLocks/collection/item.lock
    final relativePath = documentPath.replaceFirst('./WorkDB/', '');
    return '$_lockRoot/$relativePath.lock';
  }

  /// Reads lock information from a lock file.
  Future<LockInfo?> _readLockInfo(String lockPath) async {
    try {
      if (!await _fs.exist(lockPath)) {
        return null;
      }
      final file = await _fs.getFile(lockPath);
      final unlockAt = file.item['unlockAt'] as String?;
      final user = file.item['user'] as String?;
      if (unlockAt == null || user == null) {
        return null;
      }
      return LockInfo(unlockAt, user);
    } catch (e) {
      return null;
    }
  }

  /// Writes lock information to a lock file.
  Future<void> _writeLockInfo(String lockPath, String user) async {
    final now = DateTime.now();
    final unlockAt = now.add(Duration(milliseconds: _lockTimeMs));
    await _fs.writeFile(
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

  @override
  Future<bool> tryAcquire(String documentPath) async {
    final lockPath = _toLockPath(documentPath);
    const userId = 'system';

    // Try once to acquire lock
    final lockInfo = await _readLockInfo(lockPath);

    if (lockInfo == null) {
      // Lock doesn't exist, acquire it
      await _writeLockInfo(lockPath, userId);
      return true;
    }

    // If lock is already expired, clean it and acquire new one
    if (_isLockExpired(lockInfo.unlockAt)) {
      await _deleteAndWriteLockInfo(lockPath, userId);
      return true;
    }

    // If _waitingMs > 0, check if lock will expire within waiting time
    if (_waitingMs > 0) {
      DateTime unlockAt;
      try {
        unlockAt = DateTime.parse(lockInfo.unlockAt);
      } on FormatException {
        // If parsing fails, lock file is corrupted - delete and acquire
        await _deleteAndWriteLockInfo(lockPath, userId);
        return true;
      }

      final now = DateTime.now();
      final timeUntilExpiry = unlockAt.difference(now).inMilliseconds;

      // If lock expires within our waiting window, wait and acquire
      if (timeUntilExpiry <= _waitingMs) {
        await Future.delayed(Duration(milliseconds: timeUntilExpiry + 10));
        await _deleteAndWriteLockInfo(lockPath, userId);
        return true;
      }
    }

    // Lock is active (not stale), cannot acquire
    return false;
  }

  Future<void> _deleteAndWriteLockInfo (String lockPath, String user) async {
      await _fs.deleteFile(lockPath);
      await _writeLockInfo(lockPath, user);
  }

  /// Attempts to acquire a lock, throwing an exception if already locked.
  ///
  /// Unlike [tryAcquire] which returns false if the lock is already held,
  /// this method throws an exception for an already-locked path.
  ///
  /// Throws [LockAcquisitionException] if the lock is already held.
  Future<void> tryAcquireThrow(String documentPath) async {
    final lockPath = _toLockPath(documentPath);
    const userId = 'system';

    // Try once to acquire lock
    final lockInfo = await _readLockInfo(lockPath);

    if (lockInfo == null) {
      // Lock doesn't exist, acquire it
      await _writeLockInfo(lockPath, userId);
      return;
    }

    // Lock exists, check if it's expired (stale)
    // If _waitingMs > 0, we consider locks as having an expiration time
    // and can clean up stale locks
    if (_waitingMs > 0 && _isLockExpired(lockInfo.unlockAt)) {
      // Lock is stale, remove it and acquire
      await _fs.deleteFile(lockPath);
      await _writeLockInfo(lockPath, userId);
      return;
    }

    // Lock is active (not stale), cannot acquire
    throw LockAcquisitionException(
      'Lock is already held for: $documentPath',
      documentPath: documentPath,
    );
  }

  @override
  Future<void> release(String documentPath) async {
    final lockPath = _toLockPath(documentPath);

    if (await _fs.exist(lockPath)) {
      try {
        await _fs.deleteFile(lockPath);
      } catch (e) {
        // Ignore deletion errors (can happen on Windows if file is still in use)
      }
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

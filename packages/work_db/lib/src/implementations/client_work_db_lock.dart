part of 'client_work_db.dart';

/// Client implementation of [IWorkDb] with file-based locking.
///
/// This class extends [ClientWorkDb] and adds file locking to prevent
/// concurrent access to the same items. It uses a separate lock file
/// directory structure for managing locks.
///
/// ## Usage
///
/// ```dart
/// final db = ClientWorkDbLock(IoWorkDb('./data'));
///
/// // Operations are protected by file locks
/// await db.create(ItemWithId(
///   id: 'doc-1',
///   collection: 'documents',
///   item: {'title': 'Hello'},
/// ));
/// ```
///
/// ## Lock Configuration
///
/// ```dart
/// // With default settings (5000ms lock timeout)
/// final db = ClientWorkDbLock(IoWorkDb('./data'));
///
/// // With custom timeout for stale lock detection
/// final db = ClientWorkDbLock.withWaitingMs(
///   IoWorkDb('./data'),
///   waitingMs: 300,
/// );
/// ```
class ClientWorkDbLock extends ClientWorkDb {
  /// Creates a new [ClientWorkDbLock] with the given file system backend
  /// and file locking enabled.
  ///
  /// Lock files are stored in `./WorkDBLocks` directory parallel to data files.
  /// Locks use a 5000ms timeout by default.
  ///
  /// Example:
  /// ```dart
  /// final db = ClientWorkDbLock(IoWorkDb('./data'));
  /// ```
  ClientWorkDbLock(super.workDbInternal)
      : _lockManager = LockManager(workDbInternal, 0);

  /// Creates a [ClientWorkDbLock] with custom lock timeout for stale lock detection.
  ///
  /// [waitingMs] enables stale lock detection and cleanup. When > 0, the lock
  /// manager will detect and clean up expired locks automatically.
  ///
  /// Example:
  /// ```dart
  /// final db = ClientWorkDbLock.withWaitingMs(
  ///   IoWorkDb('./data'),
  ///   waitingMs: 300,
  /// );
  /// ```
  ClientWorkDbLock.withWaitingMs(
    super.workDbInternal, {
    required int waitingMs,
  }) : _lockManager = LockManager(workDbInternal, waitingMs);

  final LockManager _lockManager;

  @override
  Future<void> create(ItemWithId input) async {
    final path = _getItemPath(input.toItemId());
    NamingConvention.validateOrThrow(path);

    if (!await _lockManager.tryAcquire(path)) {
      throw Exception('Unable to acquire lock for $path');
    }

    try {
      if (await _workDbInternal.exist(path)) {
        throw ItemAlreadyExistsException(
          id: input.id,
          collection: input.collection,
        );
      }

      await _workDbInternal.writeFile(path, Item(item: input.item));
    } finally {
      await _lockManager.release(path);
    }
  }

  @override
  Future<void> update(ItemWithId input) async {
    final path = _getItemPath(input.toItemId());
    NamingConvention.validateOrThrow(path);

    if (!await _lockManager.tryAcquire(path)) {
      throw Exception('Unable to acquire lock for $path');
    }

    try {
      if (!await _workDbInternal.exist(path)) {
        throw ItemNotFoundException(
          id: input.id,
          collection: input.collection,
        );
      }

      await _workDbInternal.writeFile(path, Item(item: input.item));
    } finally {
      await _lockManager.release(path);
    }
  }

  @override
  Future<void> createOrUpdate(ItemWithId input) async {
    final path = _getItemPath(input.toItemId());

    if (!await _lockManager.tryAcquire(path)) {
      throw Exception('Unable to acquire lock for $path');
    }

    try {
      await _workDbInternal.writeFile(path, Item(item: input.item));
    } finally {
      await _lockManager.release(path);
    }
  }

  @override
  Future<void> delete(ItemId input) async {
    final path = _getItemPath(input);
    NamingConvention.validateOrThrow(path);

    if (!await _lockManager.tryAcquire(path)) {
      throw Exception('Unable to acquire lock for $path');
    }

    try {
      if (!await _workDbInternal.exist(path)) {
        throw ItemNotFoundException(
          id: input.id,
          collection: input.collection,
        );
      }

      await _workDbInternal.deleteFile(path);
    } finally {
      await _lockManager.release(path);
    }
  }
}

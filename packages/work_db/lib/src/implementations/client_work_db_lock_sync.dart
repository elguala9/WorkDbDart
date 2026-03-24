part of 'client_work_db.dart';

/// Client implementation of [IWorkDb] and [IWorkDbSync] with file-based locking
/// on both async and sync operations.
///
/// Extends [ClientWorkDbLock] (which covers async locking) and additionally
/// protects all `*Sync` methods with a [LockManagerSync].
///
/// ## Usage
///
/// ```dart
/// final db = ClientWorkDbLockSync(IoWorkDb('./data'));
///
/// // Async operations are locked (inherited from ClientWorkDbLock)
/// await db.create(ItemWithId(...));
///
/// // Sync operations are also locked
/// db.createSync(ItemWithId(...));
/// ```
///
/// ## Lock Configuration
///
/// ```dart
/// final db = ClientWorkDbLockSync.withWaitingMs(
///   IoWorkDb('./data'),
///   waitingMs: 300,
/// );
/// ```
class ClientWorkDbLockSync extends ClientWorkDbLock {
  /// Creates a new [ClientWorkDbLockSync] with default lock settings.
  ClientWorkDbLockSync(super.workDbInternal)
      : _lockManagerSync = LockManagerSync(
          workDbInternal as IWorkFileSystemSync,
        );

  /// Creates a [ClientWorkDbLockSync] with custom stale lock detection timeout.
  ClientWorkDbLockSync.withWaitingMs(
    super.workDbInternal, {
    required super.waitingMs,
  })  : _lockManagerSync = LockManagerSync(
          workDbInternal as IWorkFileSystemSync,
          waitingMs,
        ),
        super.withWaitingMs();

  final LockManagerSync _lockManagerSync;

  @override
  void createSync(ItemWithId input) {
    final path = _getItemPath(input.toItemId());
    NamingConvention.validateOrThrow(path);

    if (!_lockManagerSync.tryAcquireSync(path)) {
      throw Exception('Unable to acquire lock for $path');
    }

    try {
      if (_workDbInternalSync.existSync(path)) {
        throw ItemAlreadyExistsException(
          id: input.id,
          collection: input.collection,
        );
      }
      _workDbInternalSync.writeFileSync(path, Item(item: input.item));
    } finally {
      _lockManagerSync.releaseSync(path);
    }
  }

  @override
  void createMultipleSync(List<ItemWithId> inputs) {
    for (final input in inputs) {
      createSync(input);
    }
  }

  @override
  void updateSync(ItemWithId input) {
    final path = _getItemPath(input.toItemId());
    NamingConvention.validateOrThrow(path);

    if (!_lockManagerSync.tryAcquireSync(path)) {
      throw Exception('Unable to acquire lock for $path');
    }

    try {
      if (!_workDbInternalSync.existSync(path)) {
        throw ItemNotFoundException(id: input.id, collection: input.collection);
      }
      _workDbInternalSync.writeFileSync(path, Item(item: input.item));
    } finally {
      _lockManagerSync.releaseSync(path);
    }
  }

  @override
  void createOrUpdateSync(ItemWithId input) {
    final path = _getItemPath(input.toItemId());

    if (!_lockManagerSync.tryAcquireSync(path)) {
      throw Exception('Unable to acquire lock for $path');
    }

    try {
      _workDbInternalSync.writeFileSync(path, Item(item: input.item));
    } finally {
      _lockManagerSync.releaseSync(path);
    }
  }

  @override
  void createOrUpdateMultipleSync(List<ItemWithId> inputs) {
    for (final input in inputs) {
      createOrUpdateSync(input);
    }
  }

  @override
  void deleteSync(ItemId input) {
    final path = _getItemPath(input);
    NamingConvention.validateOrThrow(path);

    if (!_lockManagerSync.tryAcquireSync(path)) {
      throw Exception('Unable to acquire lock for $path');
    }

    try {
      if (!_workDbInternalSync.existSync(path)) {
        throw ItemNotFoundException(id: input.id, collection: input.collection);
      }
      _workDbInternalSync.deleteFileSync(path);
    } finally {
      _lockManagerSync.releaseSync(path);
    }
  }
}

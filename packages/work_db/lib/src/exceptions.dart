/// Custom exceptions for WorkDB operations.
///
/// These exceptions provide specific error types for common database
/// operations, allowing for more precise error handling.
library;

/// Exception thrown when trying to create an item that already exists.
///
/// This exception is thrown by [IWorkDb.create] when an item with the
/// same id already exists in the specified collection.
///
/// Example:
/// ```dart
/// try {
///   await db.create(ItemWithId(id: 'user-1', collection: 'users', item: {}));
///   await db.create(ItemWithId(id: 'user-1', collection: 'users', item: {}));
/// } on ItemAlreadyExistsException catch (e) {
///   print('Item ${e.id} already exists in ${e.collection}');
/// }
/// ```
class ItemAlreadyExistsException implements Exception {
  /// Creates a new [ItemAlreadyExistsException].
  ///
  /// [id] is the id of the item that already exists.
  /// [collection] is the collection where the item exists.
  const ItemAlreadyExistsException({
    required this.id,
    required this.collection,
  });

  /// The id of the item that already exists.
  final String id;

  /// The collection where the item exists.
  final String collection;

  @override
  String toString() =>
      'ItemAlreadyExistsException: Item with id "$id" in collection '
      '"$collection" already exists.';
}

/// Exception thrown when trying to access an item that does not exist.
///
/// This exception is thrown by [IWorkDb.update] and [IWorkDb.delete]
/// when the specified item cannot be found.
///
/// Example:
/// ```dart
/// try {
///   await db.update(ItemWithId(id: 'nonexistent', collection: 'users', item: {}));
/// } on ItemNotFoundException catch (e) {
///   print('Item ${e.id} not found in ${e.collection}');
/// }
/// ```
class ItemNotFoundException implements Exception {
  /// Creates a new [ItemNotFoundException].
  ///
  /// [id] is the id of the item that was not found.
  /// [collection] is the collection where the item was expected.
  const ItemNotFoundException({
    required this.id,
    required this.collection,
  });

  /// The id of the item that was not found.
  final String id;

  /// The collection where the item was expected.
  final String collection;

  @override
  String toString() =>
      'ItemNotFoundException: Item with id "$id" in collection '
      '"$collection" does not exist.';
}

/// Exception thrown when a file operation fails.
///
/// This is a lower-level exception used by [IWorkFileSystem] implementations.
class FileOperationException implements Exception {
  /// Creates a new [FileOperationException].
  ///
  /// [path] is the file path involved in the failed operation.
  /// [operation] describes the operation that failed.
  /// [message] provides additional details about the failure.
  const FileOperationException({
    required this.path,
    required this.operation,
    this.message,
  });

  /// The file path involved in the failed operation.
  final String path;

  /// The operation that failed (e.g., 'read', 'write', 'delete').
  final String operation;

  /// Additional details about the failure.
  final String? message;

  @override
  String toString() {
    final msg = message != null ? ': $message' : '';
    return 'FileOperationException: Failed to $operation file at "$path"$msg';
  }
}

/// Exception thrown when trying to access a locked document.
///
/// This exception is thrown when an operation cannot proceed because
/// another process holds a lock on the document.
///
/// Example:
/// ```dart
/// try {
///   await db.update(ItemWithId(id: 'user-1', collection: 'users', item: {}));
/// } on DocumentLockedException catch (e) {
///   print('Document ${e.documentPath} is locked');
/// }
/// ```
class DocumentLockedException implements Exception {
  /// Creates a new [DocumentLockedException].
  ///
  /// [documentPath] is the path of the locked document.
  const DocumentLockedException({
    required this.documentPath,
  });

  /// The path of the locked document.
  final String documentPath;

  @override
  String toString() =>
      'DocumentLockedException: Document at "$documentPath" is currently locked.';
}

/// Exception thrown when a collection name is invalid.
class InvalidCollectionNameException implements Exception {
  const InvalidCollectionNameException({
    required this.collection,
    required this.reason,
  });

  final String collection;
  final String reason;

  @override
  String toString() =>
      'InvalidCollectionNameException: Collection name "$collection" is invalid: $reason';
}

/// Exception thrown when an item ID is invalid.
class InvalidItemIdException implements Exception {
  const InvalidItemIdException({
    required this.id,
    required this.reason,
  });

  final String id;
  final String reason;

  @override
  String toString() =>
      'InvalidItemIdException: Item ID "$id" is invalid: $reason';
}

/// Exception thrown when a path is invalid.
class InvalidPathException implements Exception {
  const InvalidPathException({
    required this.path,
    required this.reason,
  });

  final String path;
  final String reason;

  @override
  String toString() =>
      'InvalidPathException: Path "$path" is invalid: $reason';
}

/// Exception thrown when a lock cannot be acquired because it's already held.
///
/// This exception is thrown by [LockManager.tryAcquireThrow] when attempting
/// to acquire a lock that is already held by another client.
///
/// Example:
/// ```dart
/// try {
///   await lockManager.tryAcquireThrow('users/user-1');
/// } on LockAcquisitionException catch (e) {
///   print('Could not acquire lock: ${e.documentPath}');
/// }
/// ```
class LockAcquisitionException implements Exception {
  /// Creates a new [LockAcquisitionException].
  ///
  /// [documentPath] is the path of the document whose lock could not be acquired.
  /// [message] provides additional details about the failure.
  const LockAcquisitionException(
    this.message, {
    this.documentPath,
  });

  /// Additional details about the lock acquisition failure.
  final String message;

  /// The path of the document whose lock could not be acquired.
  final String? documentPath;

  @override
  String toString() => 'LockAcquisitionException: $message';
}

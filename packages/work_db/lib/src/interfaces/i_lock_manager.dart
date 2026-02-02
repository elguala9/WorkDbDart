/// Interface for document lock management.
///
/// Implementations can use different strategies for locking:
/// - File-based locks
/// - In-memory locks
/// - Database locks
/// - etc.
abstract interface class ILockManager {
  /// Attempts to acquire a lock on the document.
  ///
  /// Returns `true` if the lock was acquired, `false` if already locked.
  Future<bool> tryAcquire(String documentPath);

  /// Releases the lock on the document.
  ///
  /// Does nothing if the lock doesn't exist.
  Future<void> release(String documentPath);

  /// Checks if a document is currently locked.
  Future<bool> isLocked(String documentPath);

  /// Clears all locks.
  ///
  /// Use with caution - typically only for testing or recovery.
  Future<void> clearAllLocks();
}

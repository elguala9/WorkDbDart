/// Synchronous interface for document lock management.
///
/// Synchronous counterpart of [ILockManager].
/// Only available on platforms that support synchronous I/O (IO, memory).
abstract interface class ILockManagerSync {
  /// Attempts to acquire a lock on the document synchronously.
  ///
  /// Returns `true` if the lock was acquired, `false` if already locked.
  bool tryAcquireSync(String documentPath);

  /// Releases the lock on the document synchronously.
  ///
  /// Does nothing if the lock doesn't exist.
  void releaseSync(String documentPath);

  /// Checks if a document is currently locked synchronously.
  bool isLockedSync(String documentPath);

  /// Clears all locks synchronously.
  ///
  /// Use with caution - typically only for testing or recovery.
  void clearAllLocksSync();
}

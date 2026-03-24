# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-03-24

### Added

- **Synchronous API**: All database operations are now available as synchronous methods via `IWorkDbSync`
  - `createSync`, `createMultipleSync`, `updateSync`, `createOrUpdateSync`, `createOrUpdateMultipleSync`
  - `retrieveSync`, `retrieveMultipleSync`, `deleteSync`, `deleteCollectionSync`, `clearDatabaseSync`
  - `getItemsInCollectionSync`, `getCollectionsSync`
- **`IWorkDbSync`**: New interface defining the complete synchronous database API
- **`IWorkFileSystemSync`**: New interface for synchronous low-level file system operations
- **`ILockManagerSync`**: New interface for synchronous lock management
- **`LockManagerSync`**: Synchronous file-based lock manager (mirrors `LockManager`)
  - `tryAcquireSync`, `tryAcquireThrowSync`, `releaseSync`, `isLockedSync`, `clearAllLocksSync`
  - Stale lock detection with configurable timeout
- **`ClientWorkDbLockSync`**: Extends `ClientWorkDbLock` with thread-safe synchronous operations
  - Protects all `*Sync` methods with `LockManagerSync`
  - Both `ClientWorkDbLockSync(backend)` and `ClientWorkDbLockSync.withWaitingMs(backend, waitingMs: n)` constructors
- **`testIWorkDbSync`**: Reusable test suite for synchronous implementations (mirrors `testIWorkDb`)
- Sync tests added for all implementations (Memory, Web, IO) in `all_implementations_test.dart`

### Changed

- `ClientWorkDb` now implements both `IWorkDb` (async) and `IWorkDbSync` (sync)
- All built-in backends (`IoWorkDb`, `MemoryWorkDb`, `WebWorkDb`) already expose `IWorkFileSystemSync`

## [1.1.0] - 2026-02-02

### Added

- **File-based Locking**: Introducing `ClientWorkDbLock` for thread-safe concurrent access with automatic lock management
  - Lock acquisition with `tryAcquire()` and `tryAcquireThrow()` methods
  - Automatic lock expiration detection (5000ms timeout)
  - Stale lock cleanup with configurable timeout (`waitingMs` parameter)
  - Lock information tracking (timestamp and user)
  - Windows file lock error handling
- **LockManager**: New file-based lock manager implementation
  - Lock files stored in parallel `./WorkDBLocks` directory structure
  - ISO8601 timestamp-based expiration tracking
  - Optional timeout-based stale lock detection
  - Simple and timeout modes for flexibility
- **LockAcquisitionException**: New exception type for lock acquisition failures
- **Inheritance-based Architecture**: Refactored with `part` and `part of` for clean code separation
  - `ClientWorkDb` - Base class without locking (for non-concurrent scenarios)
  - `ClientWorkDbLock` - Extends ClientWorkDb with full locking support
  - Eliminates null checks and improves maintainability
- **Enhanced Testing**: Added 22 comprehensive locking tests covering:
  - Lock acquisition and release
  - Multi-client concurrent access
  - Stale lock detection and cleanup
  - Lock timeout and expiration
  - Error handling and lock recovery

### Changed

- `ClientWorkDb` is now a lightweight base implementation without locking overhead
- Users requiring thread-safety should use `ClientWorkDbLock` instead
- Internal architecture improved with library-level `part` directives

### Improved

- Better separation of concerns between locking and non-locking implementations
- More efficient for single-threaded or non-concurrent applications
- Comprehensive documentation for lock management
- 22 new tests ensuring lock correctness across scenarios

## [1.0.2] - 2026-01-20

### Added
- Introduced polymorphic Factory Pattern with dedicated input types (`IoWorkDbFactoryInput`, `WebWorkDbFactoryInput`, `MemoryWorkDbFactoryInput`) for each implementation.
- All examples, tests, and documentation now use the new factory pattern.
- All test suites aligned to the new pattern (202 tests, 100% pass).

### Changed
- Breaking change: All instantiation now requires input objects for factory methods.
- README and examples updated to reflect new usage.

### Removed
- Deprecated old static factory methods (`forIo`, `forWeb`, `forMemory`, `createIo`, `createWeb`, `createMemory`).

## [1.0.1] - 2025-12-26

### Changed

- Updated `createOrUpdate` to properly use `create` and `update` methods

## [1.0.0] - 2024-12-22

### Added

- Initial release
- `ClientWorkDb` - Main database client implementation
- `IoWorkDb` - File system storage for Desktop/Server (Windows, macOS, Linux)
- `WebWorkDb` - localStorage-based storage for Web
- `MemoryWorkDb` - In-memory storage for testing
- `WorkDbFactory` - Factory methods for easy instantiation
- Full CRUD operations: create, read, update, delete
- Batch operations: createMultiple, retrieveMultiple, createOrUpdateMultiple
- Collection management: getItemsInCollection, getCollections, deleteCollection
- Comprehensive test suite with 33 tests per implementation

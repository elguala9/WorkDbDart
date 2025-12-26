# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

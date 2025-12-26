# WorkDB Dart

A cross-platform local database for Dart, ported from the TypeScript WorkDB implementation.

## Structure

This is a monorepo managed with [Melos](https://melos.invertase.dev/) containing three packages:

```
packages/
├── work_db_interfaces/   # Abstract interfaces (IWorkDb, IWorkFileSystem)
├── work_db/              # Implementations (IO, Web, Memory)
└── work_db_test/         # Test suite and utilities
```

## Packages

### work_db_interfaces

Pure Dart interfaces that define the contract for all WorkDB implementations:

- `IWorkDb` - Main database interface with CRUD operations
- `IWorkFileSystem` - Low-level file system abstraction
- Type definitions (`ItemId`, `Item`, `ItemOutput`, `ItemWithId`)

### work_db

Platform-specific implementations:

- `IoWorkDb` - File system storage for Desktop/Server (dart:io)
- `WebWorkDb` - localStorage-like storage for Web
- `MemoryWorkDb` - In-memory storage (perfect for testing)
- `WorkDbFactory` - Factory methods for creating instances

### work_db_test

Complete test suite that can be run against any `IWorkDb` implementation:

- `testIWorkDb()` - Function that runs all standard tests
- Test utilities for binary data comparison
- Pre-configured test runners for each implementation

## Getting Started

### Installation

```yaml
dependencies:
  work_db:
    path: packages/work_db
```

### Usage

```dart
import 'package:work_db/work_db.dart';

void main() async {
  // Create instance for your platform
  final db = WorkDbFactory.forIo(dataPath: './data');
  // Or: WorkDbFactory.forWeb()
  // Or: WorkDbFactory.forMemory()

  // Create an item
  await db.create(ItemWithId(
    id: 'user-1',
    collection: 'users',
    item: {'name': 'John Doe', 'email': 'john@example.com'},
  ));

  // Retrieve the item
  final user = await db.retrieve(ItemId(
    id: 'user-1',
    collection: 'users',
  ));
  print(user?.item['name']); // John Doe

  // Update the item
  await db.update(ItemWithId(
    id: 'user-1',
    collection: 'users',
    item: {'name': 'John Doe', 'email': 'john.doe@example.com'},
  ));

  // Delete the item
  await db.delete(ItemId(id: 'user-1', collection: 'users'));

  // List all items in a collection
  final userIds = await db.getItemsInCollection('users');

  // List all collections
  final collections = await db.getCollections();

  // Clear everything
  await db.clearDatabase();
}
```

## API Reference

### IWorkDb Methods

| Method | Description |
|--------|-------------|
| `create(ItemWithId)` | Create a new item (throws if exists) |
| `createMultiple(List<ItemWithId>)` | Create multiple items |
| `update(ItemWithId)` | Update existing item (throws if not exists) |
| `createOrUpdate(ItemWithId)` | Create or update (upsert) |
| `createOrUpdateMultiple(List<ItemWithId>)` | Batch upsert |
| `retrieve(ItemId)` | Get item or null |
| `retrieveMultiple(List<ItemId>)` | Get multiple items |
| `delete(ItemId)` | Delete item (throws if not exists) |
| `deleteCollection(String)` | Delete entire collection |
| `clearDatabase()` | Delete all data |
| `getItemsInCollection(String)` | List item IDs in collection |
| `getCollections()` | List all collection names |

## Development

### Prerequisites

- Dart SDK >= 3.0.0
- Melos (optional, for monorepo commands)

### Setup

```bash
# Install melos globally (optional)
dart pub global activate melos

# Bootstrap all packages
melos bootstrap
# Or manually:
cd packages/work_db_interfaces && dart pub get
cd packages/work_db && dart pub get
cd packages/work_db_test && dart pub get
```

### Running Tests

```bash
# Run all tests
melos test
# Or manually:
cd packages/work_db_test && dart test

# Run specific implementation tests
dart test test/memory_work_db_test.dart
dart test test/io_work_db_test.dart
dart test test/web_work_db_test.dart

# Run all implementations in one file
dart test test/all_implementations_test.dart
```

### Available Melos Scripts

```bash
melos analyze   # Analyze all packages
melos format    # Format all packages
melos test      # Run tests in all packages
melos clean     # Clean build artifacts
```

## Platform Support

| Platform | Implementation | Storage |
|----------|---------------|---------|
| Windows/macOS/Linux | `IoWorkDb` | File system |
| Web | `WebWorkDb` | localStorage |
| Testing | `MemoryWorkDb` | In-memory Map |
| Flutter Mobile | Use `IoWorkDb` with path_provider | File system |

## Comparison with TypeScript Version

| TypeScript | Dart |
|------------|------|
| `IWorkDb` interface | `IWorkDb` abstract interface class |
| `NodeWorkDB` | `IoWorkDb` |
| `BrowserWorkDB` | `WebWorkDb` |
| `CapacitorWorkDB` | Not ported (use IoWorkDb + path_provider) |
| - | `MemoryWorkDb` (new, for testing) |

## License

MIT

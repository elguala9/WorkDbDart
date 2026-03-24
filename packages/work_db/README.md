# work_db

[![pub package](https://img.shields.io/pub/v/work_db.svg)](https://pub.dev/packages/work_db)
[![License: LGPL v3](https://img.shields.io/badge/License-LGPL_v3-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0)

A lightweight, cross-platform local database for Dart and Flutter with optional thread-safe locking. Simple key-value storage organized in collections, supporting Desktop, Web, Mobile platforms, and concurrent access scenarios.

## Features

- **Cross-platform**: Windows, macOS, Linux, Web, iOS, Android
- **Simple API**: CRUD operations, batch, upsert
- **Collections**: Organize data in named collections
- **Batch operations**: Create, retrieve, update multiple items
- **Type-safe**: Full Dart type safety
- **Thread-Safe Locking** *(New in 1.1.0)*: File-based locking with stale lock detection
  - `ClientWorkDbLock` for concurrent access protection
  - Automatic lock expiration (5000ms timeout)
  - Stale lock cleanup with configurable timeout
  - Lock information tracking (timestamp, user)
- **Flexible Architecture**: Choose `ClientWorkDb` (lightweight) or `ClientWorkDbLock` (thread-safe)
- **Factory Pattern**: Polymorphic factory with dedicated input types for each implementation
- **Minimal dependencies**: Only `path` for IO operations
- **Synchronous API** *(New in 1.2.0)*: Full `*Sync` counterparts for all operations via `IWorkDbSync`
  - `createSync`, `updateSync`, `retrieveSync`, `deleteSync`, and all other operations available synchronously
  - `ClientWorkDbLockSync` for thread-safe synchronous operations
- **Well tested**: 224 tests across all implementations + 22 comprehensive locking tests + full sync test coverage

## Installation

```yaml
dependencies:
  work_db: ^1.2.0
```

## Quick Start

```dart
import 'package:work_db/work_db.dart';

void main() async {
  // Create a factory
  final factory = WorkDbFactory();

  // Create a database instance for desktop/server
  final db = factory.create(IoWorkDbFactoryInput(dataPath: './data'));

  // Create an item
  await db.create(ItemWithId(
    id: 'user-1',
    collection: 'users',
    item: {'name': 'John Doe', 'email': 'john@example.com'},
  ));

  // Retrieve the item
  final user = await db.retrieve(ItemId(id: 'user-1', collection: 'users'));
  print(user?.item['name']); // John Doe

  // Update the item
  await db.update(ItemWithId(
    id: 'user-1',
    collection: 'users',
    item: {'name': 'John Doe', 'email': 'john.updated@example.com'},
  ));

  // Delete the item
  await db.delete(ItemId(id: 'user-1', collection: 'users'));
}
```

## Thread-Safe Operations with Locking *(New in 1.1.0)*

For concurrent access across multiple clients or isolates, use `ClientWorkDbLock` for automatic lock management:

```dart
import 'package:work_db/work_db.dart';

void main() async {
  // Create a locked database instance for thread-safe operations
  final db = ClientWorkDbLock(IoWorkDb('./data'));

  // All operations are protected by file locks
  await db.create(ItemWithId(
    id: 'user-1',
    collection: 'users',
    item: {'name': 'John Doe'},
  ));

  // Locks are automatically acquired and released
  await db.update(ItemWithId(
    id: 'user-1',
    collection: 'users',
    item: {'name': 'John Smith'},
  ));
}
```

### Locking Features

- **Automatic Lock Management**: Locks are acquired at operation start and released after completion
- **Stale Lock Cleanup**: Expired locks are automatically detected and cleaned up
- **Lock Expiration**: Locks expire after 5000ms if not explicitly released
- **Configurable Timeout**: Use `ClientWorkDbLock.withWaitingMs()` for stale lock detection with custom timeout

```dart
// Enable stale lock detection with 300ms timeout
final db = ClientWorkDbLock.withWaitingMs(
  IoWorkDb('./data'),
  waitingMs: 300,
);
```

### Choosing Between Implementations

| Use Case | Implementation | Benefits |
|----------|---|---|
| Single-threaded app | `ClientWorkDb` | Minimal overhead, simpler code |
| Concurrent access | `ClientWorkDbLock` | Thread-safe, automatic lock management |
| Sync single-threaded | `ClientWorkDb` (sync API) | No async overhead, blocking calls |
| Sync concurrent access | `ClientWorkDbLockSync` | Thread-safe sync operations |
| Testing | In-memory backend with `ClientWorkDb` or `ClientWorkDbLock` | No file I/O, isolated state |

## Synchronous API *(New in 1.2.0)*

All database operations are available as synchronous methods. `ClientWorkDb` implements `IWorkDbSync` directly — no wrapper needed:

```dart
import 'package:work_db/work_db.dart';

void main() {
  final db = ClientWorkDb(IoWorkDb('./data'));

  // Synchronous create
  db.createSync(ItemWithId(
    id: 'user-1',
    collection: 'users',
    item: {'name': 'John Doe'},
  ));

  // Synchronous retrieve
  final user = db.retrieveSync(ItemId(id: 'user-1', collection: 'users'));
  print(user?.item['name']); // John Doe

  // Synchronous update
  db.updateSync(ItemWithId(
    id: 'user-1',
    collection: 'users',
    item: {'name': 'John Smith'},
  ));

  // Synchronous delete
  db.deleteSync(ItemId(id: 'user-1', collection: 'users'));
}
```

### Thread-Safe Synchronous Operations

For concurrent synchronous access, use `ClientWorkDbLockSync`:

```dart
import 'package:work_db/work_db.dart';

void main() {
  final db = ClientWorkDbLockSync(IoWorkDb('./data'));

  // Sync operations are protected by file locks
  db.createSync(ItemWithId(
    id: 'doc-1',
    collection: 'documents',
    item: {'title': 'Hello'},
  ));

  // With stale lock detection
  final dbWithTimeout = ClientWorkDbLockSync.withWaitingMs(
    IoWorkDb('./data'),
    waitingMs: 300,
  );
}
```

`ClientWorkDbLockSync` also inherits all async operations from `ClientWorkDbLock`, so you can mix sync and async calls on the same instance.

## Platform-Specific Setup

### Desktop (Windows, macOS, Linux) & Server

```dart
import 'package:work_db/work_db.dart';

final factory = WorkDbFactory();
final db = factory.create(IoWorkDbFactoryInput(dataPath: './my_app_data'));
```

### Web

```dart
import 'package:work_db/work_db.dart';

final factory = WorkDbFactory();
final db = factory.create(WebWorkDbFactoryInput());
```

### Flutter Mobile (iOS, Android)

```dart
import 'package:work_db/work_db.dart';
import 'package:path_provider/path_provider.dart';

Future<IWorkDb> createDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final factory = WorkDbFactory();
  return factory.create(IoWorkDbFactoryInput(dataPath: dir.path));
}
```

### Testing

```dart
import 'package:work_db/work_db.dart';

final factory = WorkDbFactory();
final db = factory.create(MemoryWorkDbFactoryInput());
```

## API Reference

### Factory Methods

| Method | Description |
|--------|-------------|
| `WorkDbFactory().create(IoWorkDbFactoryInput)` | File system storage (Desktop/Server) |
| `WorkDbFactory().create(WebWorkDbFactoryInput)` | localStorage storage (Web) |
| `WorkDbFactory().create(MemoryWorkDbFactoryInput)` | In-memory storage (Testing) |

Each call to `create()` returns a new independent instance. You can create multiple databases with different paths:

```dart
final db1 = factory.create(IoWorkDbFactoryInput(dataPath: './data1'));
final db2 = factory.create(IoWorkDbFactoryInput(dataPath: './data2'));
// db1 and db2 are completely independent
```

### Database Operations

All operations are available in both async (`Future<T>`) and sync (`T`) variants.

| Async Method | Sync Method | Description |
|--------|-------------|-------------|
| `create(ItemWithId)` | `createSync(ItemWithId)` | Create a new item (throws if exists) |
| `createMultiple(List<ItemWithId>)` | `createMultipleSync(List<ItemWithId>)` | Create multiple items |
| `update(ItemWithId)` | `updateSync(ItemWithId)` | Update existing item (throws if not exists) |
| `createOrUpdate(ItemWithId)` | `createOrUpdateSync(ItemWithId)` | Create or update (upsert) |
| `createOrUpdateMultiple(List<ItemWithId>)` | `createOrUpdateMultipleSync(List<ItemWithId>)` | Batch upsert |
| `retrieve(ItemId)` | `retrieveSync(ItemId)` | Get item or null |
| `retrieveMultiple(List<ItemId>)` | `retrieveMultipleSync(List<ItemId>)` | Get multiple items |
| `delete(ItemId)` | `deleteSync(ItemId)` | Delete item (throws if not exists) |
| `deleteCollection(String)` | `deleteCollectionSync(String)` | Delete entire collection |
| `clearDatabase()` | `clearDatabaseSync()` | Delete all data |
| `getItemsInCollection(String)` | `getItemsInCollectionSync(String)` | List item IDs in collection |
| `getCollections()` | `getCollectionsSync()` | List all collection names |

## Examples

### Batch Operations

```dart
// Create multiple items at once
await db.createMultiple([
  ItemWithId(id: 'user-1', collection: 'users', item: {'name': 'Alice'}),
  ItemWithId(id: 'user-2', collection: 'users', item: {'name': 'Bob'}),
  ItemWithId(id: 'user-3', collection: 'users', item: {'name': 'Charlie'}),
]);

// Retrieve multiple items
final users = await db.retrieveMultiple([
  ItemId(id: 'user-1', collection: 'users'),
  ItemId(id: 'user-2', collection: 'users'),
]);
```

### Upsert (Create or Update)

```dart
// Creates if not exists, updates if exists
await db.createOrUpdate(ItemWithId(
  id: 'settings',
  collection: 'config',
  item: {'theme': 'dark', 'language': 'en'},
));
```

### Collection Management

```dart
// List all collections
final collections = await db.getCollections();
print(collections); // ['users', 'config', 'posts']

// List items in a collection
final userIds = await db.getItemsInCollection('users');
print(userIds); // ['user-1', 'user-2', 'user-3']

// Delete entire collection
await db.deleteCollection('cache');

// Clear everything
await db.clearDatabase();
```

### Nested Data

```dart
await db.create(ItemWithId(
  id: 'post-1',
  collection: 'posts',
  item: {
    'title': 'Hello World',
    'content': 'This is my first post',
    'author': {
      'name': 'John',
      'email': 'john@example.com',
    },
    'tags': ['dart', 'flutter', 'database'],
    'metadata': {
      'views': 0,
      'likes': 0,
      'published': true,
    },
  },
));
```

## Storage Format

Data is stored as JSON files in a simple directory structure:

```
<dataPath>/
└── WorkDB/
    ├── users/
    │   ├── user-1    (JSON file)
    │   └── user-2    (JSON file)
    └── posts/
        └── post-1    (JSON file)
```

## Error Handling

```dart
import 'package:work_db/work_db.dart';

try {
  await db.create(ItemWithId(
    id: 'duplicate',
    collection: 'test',
    item: {'data': 'value'},
  ));

  // This will throw ItemAlreadyExistsException
  await db.create(ItemWithId(
    id: 'duplicate',
    collection: 'test',
    item: {'data': 'new value'},
  ));
} on ItemAlreadyExistsException catch (e) {
  print('Item ${e.id} already exists in ${e.collection}');
}

// Use createOrUpdate to avoid exceptions
await db.createOrUpdate(ItemWithId(
  id: 'safe',
  collection: 'test',
  item: {'data': 'value'},
));
```

## Testing Your Code

```dart
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  late IWorkDb db;
  late WorkDbFactory factory;

  setUp(() {
    factory = WorkDbFactory();
    db = factory.createNew(MemoryWorkDbFactoryInput());
  });

  test('should store and retrieve data', () async {
    await db.create(ItemWithId(
      id: 'test-1',
      collection: 'test',
      item: {'value': 42},
    ));

    final result = await db.retrieve(ItemId(id: 'test-1', collection: 'test'));
    expect(result?.item['value'], equals(42));
  });
}
```

## License

LGPL v3 License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

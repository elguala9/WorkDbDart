# work_db

[![pub package](https://img.shields.io/pub/v/work_db.svg)](https://pub.dev/packages/work_db)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A lightweight, cross-platform local database for Dart and Flutter. Simple key-value storage organized in collections, with support for Desktop, Web, and Mobile platforms.

## Features

- ✅ **Cross-platform**: Works on Windows, macOS, Linux, Web, iOS, and Android
- ✅ **Simple API**: Easy-to-use CRUD operations
- ✅ **Collections**: Organize data in named collections
- ✅ **Batch operations**: Create, retrieve, and update multiple items at once
- ✅ **Type-safe**: Full Dart type safety with generics
- ✅ **No dependencies**: Minimal footprint (only `path` package for IO)
- ✅ **Well tested**: 99 tests across all implementations

## Installation

```yaml
dependencies:
  work_db: ^1.0.0
```

## Quick Start

```dart
import 'package:work_db/work_db.dart';

void main() async {
  // Create a database instance
  final db = WorkDbFactory.forIo(dataPath: './data');
  
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

## Platform-Specific Setup

### Desktop (Windows, macOS, Linux) & Server

```dart
import 'package:work_db/work_db.dart';

final db = WorkDbFactory.forIo(dataPath: './my_app_data');
```

### Web

```dart
import 'package:work_db/work_db.dart';

// Uses localStorage under the hood
final db = WorkDbFactory.forWeb();
```

### Flutter Mobile (iOS, Android)

```dart
import 'package:work_db/work_db.dart';
import 'package:path_provider/path_provider.dart';

Future<IWorkDb> createDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  return WorkDbFactory.forIo(dataPath: dir.path);
}
```

### Testing

```dart
import 'package:work_db/work_db.dart';

// In-memory storage, perfect for unit tests
final db = WorkDbFactory.forMemory();
```

## API Reference

### Factory Methods

| Method | Description |
|--------|-------------|
| `WorkDbFactory.forIo(dataPath:)` | File system storage (Desktop/Server) |
| `WorkDbFactory.forWeb(storage:)` | localStorage storage (Web) |
| `WorkDbFactory.forMemory()` | In-memory storage (Testing) |
| `WorkDbFactory.createIo(dataPath:)` | Non-singleton IO instance |
| `WorkDbFactory.createWeb(storage:)` | Non-singleton Web instance |
| `WorkDbFactory.createMemory()` | Non-singleton Memory instance |

### Database Operations

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
try {
  await db.create(ItemWithId(
    id: 'duplicate',
    collection: 'test',
    item: {'data': 'value'},
  ));
  
  // This will throw - item already exists
  await db.create(ItemWithId(
    id: 'duplicate',
    collection: 'test',
    item: {'data': 'new value'},
  ));
} catch (e) {
  print('Error: $e');
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

  setUp(() {
    // Fresh in-memory database for each test
    db = WorkDbFactory.createMemory();
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

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

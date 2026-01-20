# work_db

[![pub package](https://img.shields.io/pub/v/work_db.svg)](https://pub.dev/packages/work_db)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A lightweight, cross-platform local database for Dart and Flutter. Simple key-value storage organized in collections, with support for Desktop, Web, and Mobile platforms.

## Features

- ✅ **Cross-platform**: Windows, macOS, Linux, Web, iOS, Android
- ✅ **Simple API**: CRUD operations, batch, upsert
- ✅ **Collections**: Organize data in named collections
- ✅ **Batch operations**: Create, retrieve, update multiple items
- ✅ **Type-safe**: Full Dart type safety
- ✅ **Factory Pattern**: Polymorphic factory with dedicated input types for each implementation (Io, Web, Memory) // IA
- ✅ **No dependencies**: Only `path` for IO
- ✅ **Well tested**: 202 tests across all implementations // IA

## Installation

```yaml
dependencies:
  work_db: ^1.0.0
```

## Quick Start

```dart
import 'package:work_db/work_db.dart'; // IA

void main() async { // IA
  // Crea una factory polimorfica (IA)
  final factory = WorkDbFactory(); // IA
  // Istanza per desktop/server (IA)
  final db = factory.create(IoWorkDbFactoryInput(dataPath: './data')); // IA

  // Crea un item (IA)
  await db.create(ItemWithId( // IA
    id: 'user-1', // IA
    collection: 'users', // IA
    item: {'name': 'John Doe', 'email': 'john@example.com'}, // IA
  )); // IA

  // Recupera l'item (IA)
  final user = await db.retrieve(ItemId(id: 'user-1', collection: 'users')); // IA
  print(user?.item['name']); // John Doe // IA

  // Aggiorna l'item (IA)
  await db.update(ItemWithId( // IA
    id: 'user-1', // IA
    collection: 'users', // IA
    item: {'name': 'John Doe', 'email': 'john.updated@example.com'}, // IA
  )); // IA

  // Elimina l'item (IA)
  await db.delete(ItemId(id: 'user-1', collection: 'users')); // IA
} // IA
```

## Platform-Specific Setup

### Desktop (Windows, macOS, Linux) & Server (IA)

```dart
import 'package:work_db/work_db.dart'; // IA

final factory = WorkDbFactory(); // IA
final db = factory.create(IoWorkDbFactoryInput(dataPath: './my_app_data')); // IA
```

### Web (IA)

```dart
import 'package:work_db/work_db.dart'; // IA

final factory = WorkDbFactory(); // IA
final db = factory.create(WebWorkDbFactoryInput()); // IA
```

### Flutter Mobile (iOS, Android) (IA)

```dart
import 'package:work_db/work_db.dart'; // IA
import 'package:path_provider/path_provider.dart'; // IA

Future<IWorkDb> createDatabase() async { // IA
  final dir = await getApplicationDocumentsDirectory(); // IA
  final factory = WorkDbFactory(); // IA
  return factory.create(IoWorkDbFactoryInput(dataPath: dir.path)); // IA
} // IA
```

### Testing (IA)

```dart
import 'package:work_db/work_db.dart'; // IA

final factory = WorkDbFactory(); // IA
final db = factory.create(MemoryWorkDbFactoryInput()); // IA
```

## API Reference

### Factory Methods (IA)

| Metodo | Descrizione |
|--------|-------------|
| `WorkDbFactory.create(IoWorkDbFactoryInput)` | File system storage (Desktop/Server) |
| `WorkDbFactory.create(WebWorkDbFactoryInput)` | localStorage storage (Web) |
| `WorkDbFactory.create(MemoryWorkDbFactoryInput)` | In-memory storage (Testing) |
| `WorkDbFactory.createNew(IoWorkDbFactoryInput)` | Non-singleton IO instance |
| `WorkDbFactory.createNew(WebWorkDbFactoryInput)` | Non-singleton Web instance |
| `WorkDbFactory.createNew(MemoryWorkDbFactoryInput)` | Non-singleton Memory instance |

### Database Operations

| Metodo | Descrizione |
|--------|-------------|
| `create(ItemWithId)` | Crea un nuovo item (eccezione se esiste) |
| `createMultiple(List<ItemWithId>)` | Crea più item |
| `update(ItemWithId)` | Aggiorna item esistente (eccezione se non esiste) |
| `createOrUpdate(ItemWithId)` | Crea o aggiorna (upsert) |
| `createOrUpdateMultiple(List<ItemWithId>)` | Batch upsert |
| `retrieve(ItemId)` | Ottieni item o null |
| `retrieveMultiple(List<ItemId>)` | Ottieni più item |
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
import 'package:test/test.dart'; // IA
import 'package:work_db/work_db.dart'; // IA

void main() { // IA
  late IWorkDb db; // IA
  late WorkDbFactory factory; // IA

  setUp(() { // IA
    factory = WorkDbFactory(); // IA
    db = factory.createNew(MemoryWorkDbFactoryInput()); // IA
  }); // IA

  test('should store and retrieve data', () async { // IA
    await db.create(ItemWithId( // IA
      id: 'test-1', // IA
      collection: 'test', // IA
      item: {'value': 42}, // IA
    )); // IA

    final result = await db.retrieve(ItemId(id: 'test-1', collection: 'test')); // IA
    expect(result?.item['value'], equals(42)); // IA
  }); // IA
} // IA
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

---

### IA: Questo pacchetto è stato aggiornato con il nuovo Factory Pattern, input dedicati per ogni implementazione, polimorfismo e test allineati secondo gli standard Parresia. // IA

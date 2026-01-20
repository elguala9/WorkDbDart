// A complete example demonstrating all WorkDB features.

import 'package:work_db/work_db.dart';

void main() async {
  // Crea una factory polimorfica (IA)
  final factory = WorkDbFactory(); // IA
  // Crea un database in-memory (IA)
  final db = factory.createNew(MemoryWorkDbFactoryInput()); // IA

  print('=== WorkDB Example ===\n');

  // --- CREATE ---
  print('1. Creating items...');

  await db.create(ItemWithId(
    id: 'user-1',
    collection: 'users',
    item: {
      'name': 'Alice Johnson',
      'email': 'alice@example.com',
      'role': 'admin',
    },
  ));
  print('   Created user-1');

  // Create multiple items at once
  await db.createMultiple([
    ItemWithId(
      id: 'user-2',
      collection: 'users',
      item: {'name': 'Bob Smith', 'email': 'bob@example.com', 'role': 'user'},
    ),
    ItemWithId(
      id: 'user-3',
      collection: 'users',
      item: {
        'name': 'Charlie Brown',
        'email': 'charlie@example.com',
        'role': 'user'
      },
    ),
  ]);
  print('   Created user-2 and user-3\n');

  // --- RETRIEVE ---
  print('2. Retrieving items...');

  final alice = await db.retrieve(ItemId(id: 'user-1', collection: 'users'));
  print('   user-1: ${alice?.item['name']} (${alice?.item['email']})');

  // Retrieve multiple items
  final users = await db.retrieveMultiple([
    ItemId(id: 'user-2', collection: 'users'),
    ItemId(id: 'user-3', collection: 'users'),
    ItemId(id: 'user-999', collection: 'users'), // doesn't exist
  ]);
  print('   user-2: ${users[0]?.item['name']}');
  print('   user-3: ${users[1]?.item['name']}');
  print('   user-999: ${users[2]?.item['name'] ?? 'NOT FOUND'}\n');

  // --- UPDATE ---
  print('3. Updating items...');

  await db.update(ItemWithId(
    id: 'user-1',
    collection: 'users',
    item: {
      'name': 'Alice Johnson',
      'email': 'alice.johnson@company.com', // updated email
      'role': 'superadmin', // promoted!
    },
  ));

  final updatedAlice =
      await db.retrieve(ItemId(id: 'user-1', collection: 'users'));
  print('   Updated user-1 role: ${updatedAlice?.item['role']}\n');

  // --- CREATE OR UPDATE (Upsert) ---
  print('4. Upsert operations...');

  // This creates because it doesn't exist
  await db.createOrUpdate(ItemWithId(
    id: 'settings',
    collection: 'config',
    item: {'theme': 'dark', 'language': 'en'},
  ));
  print('   Created settings (upsert)');

  // This updates because it now exists
  await db.createOrUpdate(ItemWithId(
    id: 'settings',
    collection: 'config',
    item: {'theme': 'light', 'language': 'en', 'notifications': true},
  ));

  final settings =
      await db.retrieve(ItemId(id: 'settings', collection: 'config'));
  print('   Updated settings theme: ${settings?.item['theme']}\n');

  // --- COLLECTION OPERATIONS ---
  print('5. Collection operations...');

  final collections = await db.getCollections();
  print('   Collections: $collections');

  final userIds = await db.getItemsInCollection('users');
  print('   Users in collection: $userIds\n');

  // --- NESTED DATA ---
  print('6. Nested data structures...');

  await db.create(ItemWithId(
    id: 'post-1',
    collection: 'posts',
    item: {
      'title': 'Getting Started with WorkDB',
      'content': 'WorkDB is a simple yet powerful local database...',
      'author': {
        'id': 'user-1',
        'name': 'Alice Johnson',
      },
      'tags': ['dart', 'flutter', 'database', 'tutorial'],
      'metadata': {
        'views': 0,
        'likes': 0,
        'published': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
    },
  ));

  final post = await db.retrieve(ItemId(id: 'post-1', collection: 'posts'));
  final authorName = (post?.item['author'] as Map)['name'];
  final tags = post?.item['tags'] as List;
  print('   Post by $authorName');
  print('   Tags: ${tags.join(', ')}\n');

  // --- DELETE ---
  print('7. Delete operations...');

  await db.delete(ItemId(id: 'user-3', collection: 'users'));
  print('   Deleted user-3');

  final remainingUsers = await db.getItemsInCollection('users');
  print('   Remaining users: $remainingUsers');

  // Delete entire collection
  await db.deleteCollection('config');
  print('   Deleted config collection');

  final remainingCollections = await db.getCollections();
  print('   Remaining collections: $remainingCollections\n');

  // --- CLEAR DATABASE ---
  print('8. Clear database...');
  await db.clearDatabase();

  final afterClear = await db.getCollections();
  print('   Collections after clear: $afterClear (empty)\n');

  print('=== Example Complete ===');
}

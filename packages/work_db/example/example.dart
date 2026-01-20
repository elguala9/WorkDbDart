// Copyright (c) 2024 Andrea Parodi. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// Example demonstrating WorkDB usage.
///
/// This example shows common database operations including:
/// - Creating database instances
/// - CRUD operations
/// - Batch operations
/// - Collection management
library;

import 'package:work_db/work_db.dart';

Future<void> main() async {
  // Crea una factory polimorfica (IA)
  final factory = WorkDbFactory(); // IA
  // Crea un database in-memory (IA)
  final db = factory.createNew(MemoryWorkDbFactoryInput()); // IA

  print('=== WorkDB Example ===\n');

  // ==================== Create Operations ====================
  print('1. Creating items...');

  // Create a single user
  await db.create(
    ItemWithId(
      id: 'user-1',
      collection: 'users',
      item: {'name': 'Alice', 'email': 'alice@example.com', 'age': 28},
    ),
  );
  print('   Created user-1');

  // Create multiple items at once
  await db.createMultiple([
    ItemWithId(
      id: 'user-2',
      collection: 'users',
      item: {'name': 'Bob', 'email': 'bob@example.com', 'age': 32},
    ),
    ItemWithId(
      id: 'user-3',
      collection: 'users',
      item: {'name': 'Charlie', 'email': 'charlie@example.com', 'age': 25},
    ),
  ]);
  print('   Created user-2 and user-3');

  // Create items in different collections
  await db.create(
    ItemWithId(
      id: 'post-1',
      collection: 'posts',
      item: {
        'title': 'Hello World',
        'content': 'My first post!',
        'authorId': 'user-1',
      },
    ),
  );
  print('   Created post-1 in posts collection\n');

  // ==================== Retrieve Operations ====================
  print('2. Retrieving items...');

  // Retrieve a single item
  final alice = await db.retrieve(ItemId(id: 'user-1', collection: 'users'));
  print('   Retrieved: ${alice?.item}');

  // Retrieve multiple items (including one that doesn\'t exist)
  final users = await db.retrieveMultiple([
    ItemId(id: 'user-1', collection: 'users'),
    ItemId(id: 'user-2', collection: 'users'),
    ItemId(id: 'nonexistent', collection: 'users'),
  ]);
  print('   Retrieved ${users.where((u) => u != null).length} users');
  print('   Third item is null: ${users[2] == null}\n');

  // ==================== Update Operations ====================
  print('3. Updating items...');

  // Update an existing item
  await db.update(
    ItemWithId(
      id: 'user-1',
      collection: 'users',
      item: {
        'name': 'Alice Smith',
        'email': 'alice.smith@example.com',
        'age': 29,
      },
    ),
  );

  final updatedAlice = await db.retrieve(
    ItemId(id: 'user-1', collection: 'users'),
  );
  print('   Updated user-1: ${updatedAlice?.item}');

  // Create or update (upsert)
  await db.createOrUpdate(
    ItemWithId(
      id: 'user-4',
      collection: 'users',
      item: {'name': 'David', 'email': 'david@example.com', 'age': 30},
    ),
  );
  print('   Created user-4 via createOrUpdate\n');

  // ==================== Collection Management ====================
  print('4. Collection management...');

  // List all collections
  final collections = await db.getCollections();
  print('   Collections: $collections');

  // List items in a collection
  final userIds = await db.getItemsInCollection('users');
  print('   Users in database: $userIds');

  // Count items
  print('   Total users: ${userIds.length}\n');

  // ==================== Delete Operations ====================
  print('5. Delete operations...');

  // Delete a single item
  await db.delete(ItemId(id: 'user-4', collection: 'users'));
  print('   Deleted user-4');

  // Delete a collection
  await db.deleteCollection('posts');
  print('   Deleted posts collection');

  final remainingCollections = await db.getCollections();
  print('   Remaining collections: $remainingCollections');

  // Clear the database
  await db.clearDatabase();
  print('   Cleared entire database');

  final emptyCollections = await db.getCollections();
  print('   Collections after clear: $emptyCollections\n');

  // ==================== Platform-Specific Examples ====================
  print('6. Platform-specific usage:');
  print('''
   // Desktop/Server (file system storage)
   final db = WorkDbFactory.forIo(dataPath: './data');

   // Web (localStorage)
   final db = WorkDbFactory.forWeb();

   // Flutter with path_provider
   final dir = await getApplicationDocumentsDirectory();
   final db = WorkDbFactory.forIo(dataPath: dir.path);

   // Testing (in-memory)
   final db = WorkDbFactory.forMemory();
''');

  print('=== Example Complete ===');
}

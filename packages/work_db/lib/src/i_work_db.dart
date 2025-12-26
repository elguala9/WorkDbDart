import 'types.dart';

/// The main interface for WorkDB database operations.
///
/// This interface defines the contract for all database operations
/// that any platform-specific implementation must fulfill.
///
/// ## Usage Example
///
/// ```dart
/// // Assuming you have an implementation
/// IWorkDb db = getWorkDbInstance();
///
/// // Create an item
/// await db.create(ItemWithId(
///   id: 'user-1',
///   collection: 'users',
///   item: {'name': 'John Doe'},
/// ));
///
/// // Retrieve the item
/// final result = await db.retrieve(ItemId(
///   id: 'user-1',
///   collection: 'users',
/// ));
/// print(result?.item); // {name: John Doe}
/// ```
abstract interface class IWorkDb {
  /// Creates a new item in the specified collection with the given id.
  ///
  /// [input] contains the item data along with its collection and id.
  ///
  /// Throws an [Exception] if an item with the same id already exists
  /// in the specified collection.
  ///
  /// Example:
  /// ```dart
  /// await db.create(ItemWithId(
  ///   id: 'doc-123',
  ///   collection: 'documents',
  ///   item: {'title': 'My Document', 'content': 'Hello World'},
  /// ));
  /// ```
  Future<void> create(ItemWithId input);

  /// Creates multiple items in their respective collections.
  ///
  /// [inputs] is a list of items with their collection/id information.
  ///
  /// This operation is atomic per item - if one item fails to create
  /// (e.g., duplicate id), it will throw an exception but previously
  /// created items in the batch will persist.
  ///
  /// Example:
  /// ```dart
  /// await db.createMultiple([
  ///   ItemWithId(id: 'user-1', collection: 'users', item: {'name': 'Alice'}),
  ///   ItemWithId(id: 'user-2', collection: 'users', item: {'name': 'Bob'}),
  /// ]);
  /// ```
  Future<void> createMultiple(List<ItemWithId> inputs);

  /// Updates an existing item in the specified collection.
  ///
  /// [input] contains the updated item data and its collection/id.
  ///
  /// Throws an [Exception] if the item doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// await db.update(ItemWithId(
  ///   id: 'doc-123',
  ///   collection: 'documents',
  ///   item: {'title': 'Updated Title', 'content': 'New content'},
  /// ));
  /// ```
  Future<void> update(ItemWithId input);

  /// Creates a new item or updates an existing one.
  ///
  /// If the item exists, it will be updated; if not, it will be created.
  /// This is an "upsert" operation.
  ///
  /// [input] contains the item data and its collection/id information.
  ///
  /// Example:
  /// ```dart
  /// // This will create if not exists, or update if exists
  /// await db.createOrUpdate(ItemWithId(
  ///   id: 'settings',
  ///   collection: 'config',
  ///   item: {'theme': 'dark', 'language': 'en'},
  /// ));
  /// ```
  Future<void> createOrUpdate(ItemWithId input);

  /// Creates new items or updates existing ones.
  ///
  /// For each item: if it exists, it will be updated; if not, it will be created.
  /// This is a batch "upsert" operation.
  ///
  /// [inputs] is a list of items with their collection/id information.
  ///
  /// Example:
  /// ```dart
  /// await db.createOrUpdateMultiple([
  ///   ItemWithId(id: 'key1', collection: 'cache', item: {'value': 42}),
  ///   ItemWithId(id: 'key2', collection: 'cache', item: {'value': 'hello'}),
  /// ]);
  /// ```
  Future<void> createOrUpdateMultiple(List<ItemWithId> inputs);

  /// Retrieves an item from the specified collection and id.
  ///
  /// [input] identifies the item to retrieve.
  ///
  /// Returns the [ItemOutput] containing the item data and metadata,
  /// or `null` if the item doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// final user = await db.retrieve(ItemId(
  ///   id: 'user-123',
  ///   collection: 'users',
  /// ));
  /// if (user != null) {
  ///   print('User name: ${user.item['name']}');
  /// }
  /// ```
  Future<ItemOutput?> retrieve(ItemId input);

  /// Retrieves multiple items by their identifiers.
  ///
  /// [ids] is a list of item identifiers to retrieve.
  ///
  /// Returns a list of [ItemOutput] in the same order as [ids].
  /// Items that don't exist will be `null` in the result list.
  ///
  /// Example:
  /// ```dart
  /// final results = await db.retrieveMultiple([
  ///   ItemId(id: 'user-1', collection: 'users'),
  ///   ItemId(id: 'user-2', collection: 'users'),
  ///   ItemId(id: 'nonexistent', collection: 'users'),
  /// ]);
  /// // results[0] and results[1] contain data, results[2] is null
  /// ```
  Future<List<ItemOutput?>> retrieveMultiple(List<ItemId> ids);

  /// Deletes an item from the specified collection.
  ///
  /// [input] identifies the item to delete.
  ///
  /// Throws an [Exception] if the item doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// await db.delete(ItemId(id: 'temp-doc', collection: 'documents'));
  /// ```
  Future<void> delete(ItemId input);

  /// Deletes an entire collection and all its items.
  ///
  /// [collection] is the name of the collection to delete.
  ///
  /// This operation removes all items in the collection.
  ///
  /// Example:
  /// ```dart
  /// // Remove all cached data
  /// await db.deleteCollection('cache');
  /// ```
  Future<void> deleteCollection(String collection);

  /// Completely clears the database.
  ///
  /// **Warning**: This removes ALL data from ALL collections.
  /// Use with caution!
  ///
  /// Example:
  /// ```dart
  /// // Reset the database to empty state
  /// await db.clearDatabase();
  /// ```
  Future<void> clearDatabase();

  /// Returns a list of all item IDs in the specified collection.
  ///
  /// [collection] is the name of the collection to query.
  ///
  /// Returns an empty list if the collection doesn't exist or is empty.
  ///
  /// Example:
  /// ```dart
  /// final userIds = await db.getItemsInCollection('users');
  /// print('Found ${userIds.length} users');
  /// ```
  Future<List<String>> getItemsInCollection(String collection);

  /// Returns a list of all collection names in the database.
  ///
  /// Returns an empty list if the database is empty.
  ///
  /// Example:
  /// ```dart
  /// final collections = await db.getCollections();
  /// for (final name in collections) {
  ///   final items = await db.getItemsInCollection(name);
  ///   print('Collection "$name" has ${items.length} items');
  /// }
  /// ```
  Future<List<String>> getCollections();
}

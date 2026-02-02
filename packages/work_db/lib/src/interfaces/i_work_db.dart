import '../types.dart';

/// Interface for WorkDB database operations.
///
/// This interface defines all CRUD operations available for the database.
/// Implementations should provide platform-specific storage backends.
///
/// ## Example
///
/// ```dart
/// class MyWorkDb implements IWorkDb {
///   // implement all methods
/// }
/// ```
abstract interface class IWorkDb {
  /// Creates a new item in the database.
  ///
  /// Throws [ItemAlreadyExistsException] if an item with the same id
  /// already exists in the collection.
  Future<void> create(ItemWithId input);

  /// Creates multiple items in the database.
  ///
  /// Throws [ItemAlreadyExistsException] if any item already exists.
  Future<void> createMultiple(List<ItemWithId> inputs);

  /// Updates an existing item in the database.
  ///
  /// Throws [ItemNotFoundException] if the item does not exist.
  Future<void> update(ItemWithId input);

  /// Creates an item if it doesn't exist, or updates it if it does.
  Future<void> createOrUpdate(ItemWithId input);

  /// Creates or updates multiple items in the database.
  Future<void> createOrUpdateMultiple(List<ItemWithId> inputs);

  /// Retrieves an item from the database.
  ///
  /// Returns `null` if the item does not exist.
  Future<ItemOutput?> retrieve(ItemId input);

  /// Retrieves multiple items from the database.
  ///
  /// Returns `null` for items that do not exist.
  Future<List<ItemOutput?>> retrieveMultiple(List<ItemId> ids);

  /// Deletes an item from the database.
  ///
  /// Throws [ItemNotFoundException] if the item does not exist.
  Future<void> delete(ItemId input);

  /// Deletes an entire collection from the database.
  Future<void> deleteCollection(String collection);

  /// Clears all data from the database.
  Future<void> clearDatabase();

  /// Returns a list of all item IDs in a collection.
  Future<List<String>> getItemsInCollection(String collection);

  /// Returns a list of all collection names in the database.
  Future<List<String>> getCollections();
}

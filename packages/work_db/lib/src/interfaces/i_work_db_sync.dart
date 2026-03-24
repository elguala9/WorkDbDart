import '../types.dart';

/// Interface for WorkDB database operations. But sync!
abstract interface class IWorkDbSync {
  /// Creates a new item in the database.
  ///
  /// Throws [ItemAlreadyExistsException] if an item with the same id
  /// already exists in the collection.
  void createSync(ItemWithId input);

  /// Creates multiple items in the database.
  ///
  /// Throws [ItemAlreadyExistsException] if any item already exists.
  void createMultipleSync(List<ItemWithId> inputs);

  /// Updates an existing item in the database.
  ///
  /// Throws [ItemNotFoundException] if the item does not exist.
  void updateSync(ItemWithId input);

  /// Creates an item if it doesn't exist, or updates it if it does.
  void createOrUpdateSync(ItemWithId input);

  /// Creates or updates multiple items in the database.
  void createOrUpdateMultipleSync(List<ItemWithId> inputs);

  /// Retrieves an item from the database.
  ///
  /// Returns `null` if the item does not exist.
  ItemOutput? retrieveSync(ItemId input);

  /// Retrieves multiple items from the database.
  ///
  /// Returns `null` for items that do not exist.
  List<ItemOutput?> retrieveMultipleSync(List<ItemId> ids);

  /// Deletes an item from the database.
  ///
  /// Throws [ItemNotFoundException] if the item does not exist.
  void deleteSync(ItemId input);

  /// Deletes an entire collection from the database.
  void deleteCollectionSync(String collection);

  /// Clears all data from the database.
  void clearDatabaseSync();

  /// Returns a list of all item IDs in a collection.
  List<String> getItemsInCollectionSync(String collection);

  /// Returns a list of all collection names in the database.
  List<String> getCollectionsSync();
}

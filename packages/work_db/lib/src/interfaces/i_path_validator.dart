/// Interface for validating paths and names in WorkDB.
///
/// Implementations should validate:
/// - Collection names
/// - Item IDs
/// - File paths
///
/// This ensures that invalid characters or patterns don't cause
/// issues with the underlying storage system.
abstract interface class IPathValidator {
  /// Validates a collection name.
  ///
  /// Throws [InvalidCollectionNameException] if the name is invalid.
  void validateCollectionName(String collection);

  /// Validates an item ID.
  ///
  /// Throws [InvalidItemIdException] if the ID is invalid.
  void validateItemId(String id);

  /// Validates a document path.
  ///
  /// Throws [InvalidPathException] if the path is invalid.
  void validatePath(String path);

  /// Checks if a collection name is valid without throwing.
  ///
  /// Returns `true` if valid, `false` otherwise.
  bool isValidCollectionName(String collection);

  /// Checks if an item ID is valid without throwing.
  ///
  /// Returns `true` if valid, `false` otherwise.
  bool isValidItemId(String id);

  /// Checks if a path is valid without throwing.
  ///
  /// Returns `true` if valid, `false` otherwise.
  bool isValidPath(String path);
}

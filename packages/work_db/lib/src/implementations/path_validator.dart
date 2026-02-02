import '../exceptions.dart';
import '../interfaces/i_path_validator.dart';

/// Default implementation of [IPathValidator].
///
/// Validates paths and names to ensure they are safe for file system storage.
///
/// ## Rules
///
/// **Collection names and Item IDs:**
/// - Cannot be empty
/// - Cannot contain: / \ : * ? " < > |
/// - Cannot start or end with spaces
/// - Cannot be "." or ".."
/// - Maximum length: 255 characters
///
/// **Paths:**
/// - Cannot be empty
/// - Cannot contain: \ : * ? " < > |
/// - Cannot contain ".."
/// - Cannot start or end with spaces
class PathValidator implements IPathValidator {
  /// Characters not allowed in collection names and item IDs.
  static const _invalidNameChars = r'/\:*?"<>|';

  /// Characters not allowed in paths (except /).
  static const _invalidPathChars = r'\:*?"<>|';

  /// Maximum length for names.
  static const _maxNameLength = 255;

  @override
  void validateCollectionName(String collection) {
    if (!isValidCollectionName(collection)) {
      throw InvalidCollectionNameException(
        collection: collection,
        reason: _getNameInvalidReason(collection),
      );
    }
  }

  @override
  void validateItemId(String id) {
    if (!isValidItemId(id)) {
      throw InvalidItemIdException(
        id: id,
        reason: _getNameInvalidReason(id),
      );
    }
  }

  @override
  void validatePath(String path) {
    if (!isValidPath(path)) {
      throw InvalidPathException(
        path: path,
        reason: _getPathInvalidReason(path),
      );
    }
  }

  @override
  bool isValidCollectionName(String collection) {
    return _isValidName(collection);
  }

  @override
  bool isValidItemId(String id) {
    return _isValidName(id);
  }

  @override
  bool isValidPath(String path) {
    if (path.isEmpty) return false;
    if (path.trim() != path) return false;
    if (path.contains('..')) return false;

    for (final char in _invalidPathChars.split('')) {
      if (path.contains(char)) return false;
    }

    return true;
  }

  bool _isValidName(String name) {
    if (name.isEmpty) return false;
    if (name.trim() != name) return false;
    if (name == '.' || name == '..') return false;
    if (name.length > _maxNameLength) return false;

    for (final char in _invalidNameChars.split('')) {
      if (name.contains(char)) return false;
    }

    return true;
  }

  String _getNameInvalidReason(String name) {
    if (name.isEmpty) return 'cannot be empty';
    if (name.trim() != name) return 'cannot start or end with spaces';
    if (name == '.' || name == '..') return 'cannot be "." or ".."';
    if (name.length > _maxNameLength) {
      return 'exceeds maximum length of $_maxNameLength characters';
    }

    for (final char in _invalidNameChars.split('')) {
      if (name.contains(char)) return 'contains invalid character "$char"';
    }

    return 'unknown reason';
  }

  String _getPathInvalidReason(String path) {
    if (path.isEmpty) return 'cannot be empty';
    if (path.trim() != path) return 'cannot start or end with spaces';
    if (path.contains('..')) return 'cannot contain ".."';

    for (final char in _invalidPathChars.split('')) {
      if (path.contains(char)) return 'contains invalid character "$char"';
    }

    return 'unknown reason';
  }
}

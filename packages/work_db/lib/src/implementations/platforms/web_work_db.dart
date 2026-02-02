import 'dart:convert';

import '../../interfaces/i_work_file_system.dart';
import '../../types.dart';

/// Storage interface for web platform abstraction.
///
/// This allows dependency injection for testing purposes.
abstract interface class IWebStorage {
  /// Retrieves the value associated with [key], or null if not found.
  String? getItem(String key);

  /// Stores a [value] associated with [key].
  void setItem(String key, String value);

  /// Removes the value associated with [key].
  void removeItem(String key);

  /// Returns the number of items stored.
  int get length;

  /// Returns the key at [index], or null if out of range.
  String? key(int index);

  /// Returns all keys in the storage.
  List<String> get keys;
}

/// Default implementation using a Map for storage.
///
/// In a real browser environment, you would create an adapter
/// for `window.localStorage`.
class MapWebStorage implements IWebStorage {
  final Map<String, String> _storage = {};

  @override
  String? getItem(String key) => _storage[key];

  @override
  void setItem(String key, String value) => _storage[key] = value;

  @override
  void removeItem(String key) => _storage.remove(key);

  @override
  int get length => _storage.length;

  @override
  String? key(int index) {
    if (index < 0 || index >= _storage.length) return null;
    return _storage.keys.elementAt(index);
  }

  @override
  List<String> get keys => _storage.keys.toList();
}

/// File system implementation for Web platform using localStorage.
///
/// This implementation stores data in the browser's localStorage,
/// making it suitable for web applications.
///
/// ## Limitations
///
/// - localStorage has a size limit (usually 5-10 MB)
/// - Data is stored as strings, so all items are JSON serialized
/// - Data persists across browser sessions but is domain-specific
///
/// ## Usage
///
/// ```dart
/// // Using default MapWebStorage (for testing/non-browser)
/// final fs = WebWorkDb();
///
/// // In a browser, you'd use an adapter for window.localStorage
/// final fs = WebWorkDb(BrowserStorageAdapter(window.localStorage));
///
/// final db = ClientWorkDb.getInstance(fs);
/// ```
class WebWorkDb implements IWorkFileSystem {
  /// Creates a new [WebWorkDb] with the specified storage.
  ///
  /// [localStorage] is the storage backend to use.
  /// Defaults to [MapWebStorage] for testing purposes.
  WebWorkDb([IWebStorage? localStorage])
      : _localStorage = localStorage ?? MapWebStorage();

  final IWebStorage _localStorage;

  @override
  Future<List<String>> ls(String dirPath) async {
    final entries = <String>{};
    final prefix = dirPath.endsWith('/') ? dirPath : '$dirPath/';

    for (final key in _localStorage.keys) {
      if (key.startsWith(prefix)) {
        // Get the relative path after the prefix
        final relativePath = key.substring(prefix.length);

        if (relativePath.isNotEmpty) {
          // Extract the first segment (could be a file or directory)
          final firstSegment = relativePath.split('/').first;
          if (firstSegment.isNotEmpty) {
            entries.add(firstSegment);
          }
        }
      }
    }

    return entries.toList();
  }

  @override
  Future<void> writeFile(String path, Item input) async {
    final data = const JsonEncoder.withIndent('  ').convert(input.item);
    _localStorage.setItem(path, data);
  }

  @override
  Future<ItemOutput> getFile(String path) async {
    final data = _localStorage.getItem(path);

    if (data == null) {
      throw Exception('File does not exist: $path');
    }

    final item = json.decode(data) as Map<String, dynamic>;
    return ItemOutput(item: item);
  }

  @override
  Future<void> deleteFile(String path) async {
    if (_localStorage.getItem(path) == null) {
      throw Exception('File does not exist: $path');
    }
    _localStorage.removeItem(path);
  }

  @override
  Future<void> deleteFolder(String folderPath) async {
    final keysToRemove = <String>[];
    final prefix = folderPath.endsWith('/') ? folderPath : '$folderPath/';

    for (final key in _localStorage.keys) {
      if (key == folderPath || key.startsWith(prefix)) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _localStorage.removeItem(key);
    }
  }

  @override
  Future<bool> exist(String path) async {
    return _localStorage.getItem(path) != null;
  }

  @override
  Future<void> renameFile(String oldPath, String newPath) async {
    final data = _localStorage.getItem(oldPath);

    if (data == null) {
      throw Exception('File does not exist: $oldPath');
    }

    _localStorage
      ..setItem(newPath, data)
      ..removeItem(oldPath);
  }

  @override
  String getPath() => ':localStorage:';
}

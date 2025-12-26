import 'dart:convert';

import '../i_work_file_system.dart';
import '../types.dart';

/// In-memory file system implementation.
///
/// This implementation stores all data in memory using a Map.
/// It's perfect for:
/// - Unit testing
/// - Temporary storage
/// - Quick prototyping
///
/// ## Note
///
/// All data is lost when the application terminates.
///
/// ## Usage
///
/// ```dart
/// final fs = MemoryWorkDb();
/// final db = ClientWorkDb.createInstance(fs);
///
/// // Use for testing
/// await db.create(ItemWithId(
///   id: 'test-1',
///   collection: 'test',
///   item: {'data': 'value'},
/// ));
/// ```
class MemoryWorkDb implements IWorkFileSystem {
  /// Internal storage for files.
  final Map<String, _StoredItem> _storage = {};

  @override
  Future<List<String>> ls(String dirPath) async {
    final entries = <String>{};
    final prefix = dirPath.endsWith('/') ? dirPath : '$dirPath/';

    for (final key in _storage.keys) {
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
    _storage[path] = _StoredItem(
      item: Map<String, dynamic>.from(input.item),
      createdAt: _storage[path]?.createdAt ?? DateTime.now(),
    );
  }

  @override
  Future<ItemOutput> getFile(String path) async {
    final stored = _storage[path];

    if (stored == null) {
      throw Exception('File does not exist: $path');
    }

    return ItemOutput(
      item: Map<String, dynamic>.from(stored.item),
      createdAt: stored.createdAt.toIso8601String(),
    );
  }

  @override
  Future<void> deleteFile(String path) async {
    if (!_storage.containsKey(path)) {
      throw Exception('File does not exist: $path');
    }

    _storage.remove(path);
  }

  @override
  Future<void> deleteFolder(String folderPath) async {
    final keysToRemove = <String>[];
    final prefix = folderPath.endsWith('/') ? folderPath : '$folderPath/';

    for (final key in _storage.keys) {
      if (key == folderPath || key.startsWith(prefix)) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _storage.remove(key);
    }
  }

  @override
  Future<bool> exist(String path) async {
    return _storage.containsKey(path);
  }

  @override
  Future<void> renameFile(String oldPath, String newPath) async {
    final stored = _storage[oldPath];

    if (stored == null) {
      throw Exception('File does not exist: $oldPath');
    }

    _storage[newPath] = stored;
    _storage.remove(oldPath);
  }

  /// Clears all data from memory.
  ///
  /// This is useful for resetting state between tests.
  void clear() {
    _storage.clear();
  }

  /// Returns the number of items stored.
  int get itemCount => _storage.length;

  /// Returns a JSON string representation of all stored data.
  ///
  /// Useful for debugging.
  String toJson() {
    final data = <String, dynamic>{};

    for (final entry in _storage.entries) {
      data[entry.key] = entry.value.item;
    }

    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

/// Internal class to store item with metadata.
class _StoredItem {
  _StoredItem({
    required this.item,
    required this.createdAt,
  });

  final Map<String, dynamic> item;
  final DateTime createdAt;
}

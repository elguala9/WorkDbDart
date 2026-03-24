import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import '../../interfaces/i_work_file_system.dart';
import '../../interfaces/i_work_file_system_sync.dart';
import '../../types.dart';

/// File system implementation for Desktop/Server platforms.
///
/// This implementation uses Dart's `dart:io` library to read and write
/// files to the local file system. It's suitable for:
/// - Windows
/// - macOS
/// - Linux
/// - Server-side Dart applications
///
/// ## Usage
///
/// ```dart
/// final fs = IoWorkDb('./data');
/// final db = ClientWorkDb.getInstance(fs);
/// ```
///
/// ## File Structure
///
/// Data is stored as JSON files in a hierarchical structure:
/// ```
/// <dataPath>/
/// └── WorkDB/
///     └── <collection>/
///         └── <itemId>  (JSON file)
/// ```
class IoWorkDb implements IWorkFileSystem, IWorkFileSystemSync {
  /// Creates a new [IoWorkDb] with the specified base path.
  ///
  /// [pathDb] is the base directory for all database files.
  /// If empty, defaults to the current working directory.
  ///
  /// Example:
  /// ```dart
  /// final fs = IoWorkDb('./my_app_data');
  /// ```
  IoWorkDb(String pathDb)
      : _pathDb = pathDb.isEmpty ? Directory.current.path : pathDb;

  /// The base path where all database files will be stored.
  final String _pathDb;

  /// Resolves a relative path to an absolute path.
  String _resolvePath(String relativePath) {
    return path.join(_pathDb, relativePath);
  }

  @override
  Future<List<String>> ls(String dirPath) async {
    final fullPath = _resolvePath(dirPath);
    final dir = Directory(fullPath);

    if (!dir.existsSync()) {
      return [];
    }

    final files = <String>[];

    await for (final entity in dir.list()) {
      if (entity is File) {
        files.add(path.basename(entity.path));
      } else if (entity is Directory) {
        files.add(path.basename(entity.path));
      }
    }

    return files;
  }

  @override
  Future<void> writeFile(String filePath, Item input) async {
    final fullPath = _resolvePath(filePath);
    final file = File(fullPath);

    // Create parent directories if needed
    await file.parent.create(recursive: true);

    // Serialize and write
    final data = const JsonEncoder.withIndent('  ').convert(input.item);
    await file.writeAsString(data);
  }

  @override
  Future<ItemOutput> getFile(String filePath) async {
    final fullPath = _resolvePath(filePath);
    final file = File(fullPath);

    if (!file.existsSync()) {
      throw Exception('File does not exist: $filePath');
    }

    final data = await file.readAsString();
    final item = json.decode(data) as Map<String, dynamic>;

    // Get file modification time as creation time fallback
    final stat = file.statSync();
    final createdAt = stat.modified.toIso8601String();

    return ItemOutput(item: item, createdAt: createdAt);
  }

  @override
  Future<void> deleteFile(String filePath) async {
    final fullPath = _resolvePath(filePath);
    final file = File(fullPath);

    if (!file.existsSync()) {
      throw Exception('File does not exist: $filePath');
    }

    await file.delete();
  }

  @override
  Future<void> deleteFolder(String folderPath) async {
    final fullPath = _resolvePath(folderPath);
    final dir = Directory(fullPath);

    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  @override
  Future<bool> exist(String filePath) async {
    final fullPath = _resolvePath(filePath);
    final file = File(fullPath);
    final dir = Directory(fullPath);

    return file.existsSync() || dir.existsSync();
  }

  @override
  Future<void> renameFile(String oldPath, String newPath) async {
    final fullOldPath = _resolvePath(oldPath);
    final fullNewPath = _resolvePath(newPath);

    final file = File(fullOldPath);

    if (!file.existsSync()) {
      throw Exception('File does not exist: $oldPath');
    }

    // Create parent directories for new path
    await File(fullNewPath).parent.create(recursive: true);

    await file.rename(fullNewPath);
  }

  @override
  String getPath() => _pathDb;

  // --- IWorkFileSystemSync ---

  @override
  bool existSync(String filePath) {
    final fullPath = _resolvePath(filePath);
    return File(fullPath).existsSync() || Directory(fullPath).existsSync();
  }

  @override
  void writeFileSync(String filePath, Item input) {
    final fullPath = _resolvePath(filePath);
    final file = File(fullPath);
    file.parent.createSync(recursive: true);
    final data = const JsonEncoder.withIndent('  ').convert(input.item);
    file.writeAsStringSync(data);
  }

  @override
  ItemOutput getFileSync(String filePath) {
    final fullPath = _resolvePath(filePath);
    final file = File(fullPath);
    if (!file.existsSync()) {
      throw Exception('File does not exist: $filePath');
    }
    final data = file.readAsStringSync();
    final item = json.decode(data) as Map<String, dynamic>;
    final stat = file.statSync();
    return ItemOutput(item: item, createdAt: stat.modified.toIso8601String());
  }

  @override
  void deleteFileSync(String filePath) {
    final fullPath = _resolvePath(filePath);
    final file = File(fullPath);
    if (!file.existsSync()) {
      throw Exception('File does not exist: $filePath');
    }
    file.deleteSync();
  }

  @override
  void deleteFolderSync(String folderPath) {
    final fullPath = _resolvePath(folderPath);
    final dir = Directory(fullPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  @override
  void renameFileSync(String oldPath, String newPath) {
    final fullOldPath = _resolvePath(oldPath);
    final fullNewPath = _resolvePath(newPath);
    final file = File(fullOldPath);
    if (!file.existsSync()) {
      throw Exception('File does not exist: $oldPath');
    }
    File(fullNewPath).parent.createSync(recursive: true);
    file.renameSync(fullNewPath);
  }

  @override
  List<String> lsSync(String dirPath) {
    final fullPath = _resolvePath(dirPath);
    final dir = Directory(fullPath);
    if (!dir.existsSync()) {
      return [];
    }
    return dir.listSync().map((e) => path.basename(e.path)).toList();
  }
}

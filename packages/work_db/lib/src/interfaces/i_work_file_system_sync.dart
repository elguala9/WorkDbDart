import '../types.dart';

/// Synchronous interface for low-level file system operations.
///
/// This is the synchronous counterpart of [IWorkFileSystem].
/// Only available on platforms that support synchronous I/O (IO, memory).
/// Web platforms cannot implement this interface.
abstract interface class IWorkFileSystemSync {
  /// Writes an item to the specified path synchronously.
  void writeFileSync(String path, Item input);

  /// Reads an item from the specified path synchronously.
  ///
  /// Throws an [Exception] if the file doesn't exist or cannot be read.
  ItemOutput getFileSync(String path);

  /// Deletes a file at the specified path synchronously.
  ///
  /// Throws an [Exception] if the file doesn't exist.
  void deleteFileSync(String path);

  /// Deletes a folder and all its contents recursively, synchronously.
  ///
  /// Does nothing if the folder doesn't exist.
  void deleteFolderSync(String folderPath);

  /// Checks if a file or folder exists at the specified path synchronously.
  bool existSync(String path);

  /// Renames/moves a file from one path to another synchronously.
  ///
  /// Throws an [Exception] if [oldPath] doesn't exist.
  void renameFileSync(String oldPath, String newPath);

  /// Lists all files/items in a directory synchronously.
  ///
  /// Returns an empty list if the directory doesn't exist or is empty.
  List<String> lsSync(String path);

  /// Returns the base path for this file system.
  String getPath();
}

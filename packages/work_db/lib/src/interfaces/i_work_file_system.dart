import '../types.dart';

/// Interface for low-level file system operations.
///
/// This interface abstracts the underlying storage mechanism,
/// allowing different implementations for different platforms
/// (file system, localStorage, etc.).
///
/// Implementations of this interface are used by [ClientWorkDb]
/// to persist data.
///
/// ## Timestamp Behavior
///
/// Different implementations handle timestamps differently:
///
/// | Implementation | Timestamp Behavior |
/// |----------------|-------------------|
/// | [MemoryWorkDb] | Maintains original creation time, preserved on updates |
/// | [IoWorkDb] | Uses file system modification time |
/// | [WebWorkDb] | No timestamp support (returns null) |
///
/// When relying on timestamps, be aware of these differences and
/// consider whether your use case requires consistent timestamp
/// handling across platforms.
abstract interface class IWorkFileSystem {
  /// Writes an item to the specified path.
  ///
  /// [path] is the relative path where the item will be stored.
  /// [input] is the item data to write.
  ///
  /// Creates any necessary parent directories/structure.
  Future<void> writeFile(String path, Item input);

  /// Reads an item from the specified path.
  ///
  /// [path] is the relative path to read from.
  ///
  /// Returns the [ItemOutput] with the stored data and metadata.
  ///
  /// Throws an [Exception] if the file doesn't exist or cannot be read.
  Future<ItemOutput> getFile(String path);

  /// Deletes a file at the specified path.
  ///
  /// [path] is the relative path to the file to delete.
  ///
  /// Throws an [Exception] if the file doesn't exist.
  Future<void> deleteFile(String path);

  /// Deletes a folder and all its contents recursively.
  ///
  /// [folderPath] is the relative path to the folder to delete.
  ///
  /// Does nothing if the folder doesn't exist.
  Future<void> deleteFolder(String folderPath);

  /// Checks if a file or folder exists at the specified path.
  ///
  /// [path] is the relative path to check.
  ///
  /// Returns `true` if the path exists, `false` otherwise.
  Future<bool> exist(String path);

  /// Renames/moves a file from one path to another.
  ///
  /// [oldPath] is the current path of the file.
  /// [newPath] is the destination path.
  ///
  /// Creates any necessary parent directories for [newPath].
  ///
  /// Throws an [Exception] if [oldPath] doesn't exist.
  Future<void> renameFile(String oldPath, String newPath);

  /// Lists all files/items in a directory.
  ///
  /// [path] is the relative path to the directory to list.
  ///
  /// Returns a list of file/item names (not full paths).
  /// Returns an empty list if the directory doesn't exist or is empty.
  Future<List<String>> ls(String path);

  String getPath();
}

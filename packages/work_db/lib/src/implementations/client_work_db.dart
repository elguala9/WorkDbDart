import 'package:work_db/src/implementations/naming_convention.dart';
import 'package:work_db/work_db.dart';

part 'client_work_db_lock.dart';
part 'client_work_db_lock_sync.dart';


/// The main client implementation of [IWorkDb].
///
/// This base class implements the WorkDB interface using a pluggable
/// [IWorkFileSystem] backend without file locking.
///
/// ## Usage
///
/// ```dart
/// // Create with a specific file system backend
/// final db = ClientWorkDb(IoWorkDb('./data'));
///
/// // Use the database
/// await db.create(ItemWithId(
///   id: 'doc-1',
///   collection: 'documents',
///   item: {'title': 'Hello'},
/// ));
/// ```
///
/// ## Multiple Instances
///
/// You can create multiple independent database instances with different
/// backends or paths:
///
/// ```dart
/// final db1 = ClientWorkDb(IoWorkDb('./data1'));
/// final db2 = ClientWorkDb(IoWorkDb('./data2'));
/// // db1 and db2 are completely independent
/// ```
///
/// ## Locking
///
/// For thread-safe operations with file locking, use [ClientWorkDbLock]:
///
/// ```dart
/// final db = ClientWorkDbLock(IoWorkDb('./data'));
/// // Operations are protected by file locks
/// ```
class ClientWorkDb implements IWorkDb, IWorkDbSync {
  /// Creates a new [ClientWorkDb] with the given file system backend.
  ///
  /// [workDbInternal] is the storage implementation to use.
  /// Must also implement [IWorkFileSystemSync] (all built-in backends do).
  ///
  /// Example:
  /// ```dart
  /// final db = ClientWorkDb(IoWorkDb('./data'));
  /// ```
  ClientWorkDb(IWorkFileSystem workDbInternal)
      : _workDbInternal = workDbInternal,
        _workDbInternalSync = workDbInternal as IWorkFileSystemSync {
    NamingConvention.validateOrThrow(workDbInternal.getPath());
  }

  final IWorkFileSystem _workDbInternal;
  final IWorkFileSystemSync _workDbInternalSync;

  /// The root directory for all database files.
  String get _root => './WorkDB';

  /// Gets the path to a collection.
  String _getCollectionPath(String collection) => '$_root/$collection';

  /// Gets the path to a specific item.
  String _getItemPath(ItemId itemId) =>
      '${_getCollectionPath(itemId.collection)}/${itemId.id}';

  @override
  Future<void> create(ItemWithId input) async {
    final path = _getItemPath(input.toItemId());
    NamingConvention.validateOrThrow(path);

    if (await _workDbInternal.exist(path)) {
      throw ItemAlreadyExistsException(
        id: input.id,
        collection: input.collection,
      );
    }

    await _workDbInternal.writeFile(path, Item(item: input.item));
  }

  @override
  Future<void> createMultiple(List<ItemWithId> inputs) async {
    for (final input in inputs) {
      await create(input);
    }
  }

  @override
  Future<void> update(ItemWithId input) async {
    final path = _getItemPath(input.toItemId());
    NamingConvention.validateOrThrow(path);

    if (!await _workDbInternal.exist(path)) {
      throw ItemNotFoundException(
        id: input.id,
        collection: input.collection,
      );
    }

    await _workDbInternal.writeFile(path, Item(item: input.item));
  }

  @override
  Future<void> createOrUpdate(ItemWithId input) async {
    final path = _getItemPath(input.toItemId());
    await _workDbInternal.writeFile(path, Item(item: input.item));
  }

  @override
  Future<void> createOrUpdateMultiple(List<ItemWithId> inputs) async {
    for (final input in inputs) {
      await createOrUpdate(input);
    }
  }

  @override
  Future<ItemOutput?> retrieve(ItemId input) async {
    final path = _getItemPath(input);
    NamingConvention.validateOrThrow(path);
    if (!await _workDbInternal.exist(path)) {
      return null;
    }

    return _workDbInternal.getFile(path);
  }

  @override
  Future<List<ItemOutput?>> retrieveMultiple(List<ItemId> ids) async {
    final results = <ItemOutput?>[];

    for (final id in ids) {
      results.add(await retrieve(id));
    }

    return results;
  }

  @override
  Future<void> delete(ItemId input) async {
    final path = _getItemPath(input);
    NamingConvention.validateOrThrow(path);

    if (!await _workDbInternal.exist(path)) {
      throw ItemNotFoundException(
        id: input.id,
        collection: input.collection,
      );
    }

    await _workDbInternal.deleteFile(path);
  }

  @override
  Future<void> deleteCollection(String collection) async {
    final path = _getCollectionPath(collection);
    await _workDbInternal.deleteFolder(path);
  }

  @override
  Future<void> clearDatabase() async {
    await _workDbInternal.deleteFolder(_root);
  }

  @override
  Future<List<String>> getItemsInCollection(String collection) async {
    final path = _getCollectionPath(collection);
    final files = await _workDbInternal.ls(path);

    // Return just the item IDs (file names without path)
    return files
        .map((f) => f.replaceFirst('$path/', ''))
        .where((f) => f.isNotEmpty && !f.contains('/'))
        .toList();
  }

  @override
  Future<List<String>> getCollections() async {
    final files = await _workDbInternal.ls(_root);

    // Extract unique collection names from the first level
    final collections = <String>{};

    for (final f in files) {
      final rel = f.replaceFirst('$_root/', '');
      final parts = rel.split('/');
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        collections.add(parts[0]);
      }
    }

    return collections.toList();
  }

  // --- IWorkDbSync ---

  @override
  void createSync(ItemWithId input) {
    final path = _getItemPath(input.toItemId());
    NamingConvention.validateOrThrow(path);
    if (_workDbInternalSync.existSync(path)) {
      throw ItemAlreadyExistsException(id: input.id, collection: input.collection);
    }
    _workDbInternalSync.writeFileSync(path, Item(item: input.item));
  }

  @override
  void createMultipleSync(List<ItemWithId> inputs) {
    for (final input in inputs) {
      createSync(input);
    }
  }

  @override
  void updateSync(ItemWithId input) {
    final path = _getItemPath(input.toItemId());
    NamingConvention.validateOrThrow(path);
    if (!_workDbInternalSync.existSync(path)) {
      throw ItemNotFoundException(id: input.id, collection: input.collection);
    }
    _workDbInternalSync.writeFileSync(path, Item(item: input.item));
  }

  @override
  void createOrUpdateSync(ItemWithId input) {
    final path = _getItemPath(input.toItemId());
    _workDbInternalSync.writeFileSync(path, Item(item: input.item));
  }

  @override
  void createOrUpdateMultipleSync(List<ItemWithId> inputs) {
    for (final input in inputs) {
      createOrUpdateSync(input);
    }
  }

  @override
  ItemOutput? retrieveSync(ItemId input) {
    final path = _getItemPath(input);
    NamingConvention.validateOrThrow(path);
    if (!_workDbInternalSync.existSync(path)) return null;
    return _workDbInternalSync.getFileSync(path);
  }

  @override
  List<ItemOutput?> retrieveMultipleSync(List<ItemId> ids) =>
      ids.map(retrieveSync).toList();

  @override
  void deleteSync(ItemId input) {
    final path = _getItemPath(input);
    NamingConvention.validateOrThrow(path);
    if (!_workDbInternalSync.existSync(path)) {
      throw ItemNotFoundException(id: input.id, collection: input.collection);
    }
    _workDbInternalSync.deleteFileSync(path);
  }

  @override
  void deleteCollectionSync(String collection) =>
      _workDbInternalSync.deleteFolderSync(_getCollectionPath(collection));

  @override
  void clearDatabaseSync() => _workDbInternalSync.deleteFolderSync(_root);

  @override
  List<String> getItemsInCollectionSync(String collection) {
    final path = _getCollectionPath(collection);
    return _workDbInternalSync
        .lsSync(path)
        .map((f) => f.replaceFirst('$path/', ''))
        .where((f) => f.isNotEmpty && !f.contains('/'))
        .toList();
  }

  @override
  List<String> getCollectionsSync() {
    final collections = <String>{};
    for (final f in _workDbInternalSync.lsSync(_root)) {
      final parts = f.replaceFirst('$_root/', '').split('/');
      if (parts.isNotEmpty && parts[0].isNotEmpty) collections.add(parts[0]);
    }
    return collections.toList();
  }
}
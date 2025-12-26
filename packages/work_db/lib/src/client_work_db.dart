import 'i_work_db.dart';
import 'i_work_file_system.dart';
import 'types.dart';

/// The main client implementation of [IWorkDb].
///
/// This class implements the WorkDB interface using a pluggable
/// [IWorkFileSystem] backend. It uses the Singleton pattern to ensure
/// only one instance exists per file system backend.
///
/// ## Usage
///
/// ```dart
/// // Get instance with a specific file system backend
/// final db = ClientWorkDb.getInstance(ioFileSystem);
///
/// // Use the database
/// await db.create(ItemWithId(
///   id: 'doc-1',
///   collection: 'documents',
///   item: {'title': 'Hello'},
/// ));
/// ```
///
/// ## Note on Singleton
///
/// The singleton pattern ensures consistency when the same backend
/// is used. However, calling [resetInstance] allows creating a new
/// instance, which is useful for testing.
class ClientWorkDb implements IWorkDb {
  /// Private constructor to enforce singleton pattern.
  ClientWorkDb._(this._workDbInternal);

  static ClientWorkDb? _instance;

  final IWorkFileSystem _workDbInternal;

  /// Returns the singleton instance of [ClientWorkDb].
  ///
  /// If not created, it will instantiate with the provided [workDbInternal].
  /// Subsequent calls return the same instance regardless of the parameter.
  ///
  /// [workDbInternal] is the file system backend to use.
  ///
  /// Example:
  /// ```dart
  /// final db = ClientWorkDb.getInstance(IoWorkDb('./data'));
  /// ```
  // ignore: prefer_constructors_over_static_methods
  static ClientWorkDb getInstance(IWorkFileSystem workDbInternal) {
    _instance ??= ClientWorkDb._(workDbInternal);
    return _instance!;
  }

  /// Resets the singleton instance.
  ///
  /// This is primarily useful for testing to ensure a clean state
  /// between test runs.
  ///
  /// **Warning**: This should not be used in production code.
  static void resetInstance() {
    _instance = null;
  }

  /// Creates a new non-singleton instance.
  ///
  /// Use this when you need multiple independent database instances
  /// or for testing purposes.
  ///
  /// [workDbInternal] is the file system backend to use.
  ///
  /// Example:
  /// ```dart
  /// final testDb = ClientWorkDb.createInstance(MockFileSystem());
  /// ```
  // ignore: prefer_constructors_over_static_methods
  static ClientWorkDb createInstance(IWorkFileSystem workDbInternal) {
    return ClientWorkDb._(workDbInternal);
  }

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

    if (await _workDbInternal.exist(path)) {
      throw Exception(
        'Item with id "${input.id}" in collection "${input.collection}" '
        'already exists.',
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

    if (!await _workDbInternal.exist(path)) {
      throw Exception(
        'Item with id "${input.id}" in collection "${input.collection}" '
        'does not exist.',
      );
    }

    await _workDbInternal.writeFile(path, Item(item: input.item));
  }

  @override
  Future<void> createOrUpdate(ItemWithId input) async {
    final path = _getItemPath(input.toItemId());

    if (await _workDbInternal.exist(path)) {
      await update(input);
    } else {
      await create(input);
    }
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

    if (!await _workDbInternal.exist(path)) {
      throw Exception(
        'Item with id "${input.id}" in collection "${input.collection}" '
        'does not exist.',
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
}

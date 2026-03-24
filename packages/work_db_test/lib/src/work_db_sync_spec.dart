import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

/// Runs the complete sync WorkDB test suite against the provided [IWorkDbSync] implementation.
///
/// Mirrors [testIWorkDb] for the synchronous interface.
///
/// ## Usage
///
/// ```dart
/// void main() {
///   group('Memory WorkDB sync', () {
///     testIWorkDbSync(() => MemoryWorkDb());
///   });
/// }
/// ```
void testIWorkDbSync(IWorkDbSync Function() getWorkDb) {
  group('WorkDB Sync Tests', () {
    late IWorkDbSync db;

    setUp(() {
      db = getWorkDb();
    });

    // -------------------------------------------------------------------------
    // createSync / retrieveSync
    // -------------------------------------------------------------------------

    group('createSync / retrieveSync', () {
      test('creates and retrieves an item', () {
        db.createSync(ItemWithId(id: 'r1', collection: 'col', item: {'v': 1}));
        final result = db.retrieveSync(ItemId(id: 'r1', collection: 'col'));
        expect(result, isNotNull);
        expect(result?.item['v'], equals(1));
      });

      test('returns null for non-existent item', () {
        final result = db.retrieveSync(ItemId(id: 'missing', collection: 'col'));
        expect(result, isNull);
      });

      test('throws ItemAlreadyExistsException on duplicate', () {
        final item = ItemWithId(id: 'dup1', collection: 'col', item: {});
        db.createSync(item);
        expect(
          () => db.createSync(item),
          throwsA(isA<ItemAlreadyExistsException>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // createMultipleSync / retrieveMultipleSync
    // -------------------------------------------------------------------------

    group('createMultipleSync / retrieveMultipleSync', () {
      test('creates all items', () {
        final items = List.generate(
          3,
          (i) => ItemWithId(id: 'cm$i', collection: 'col', item: {'i': i}),
        );
        db.createMultipleSync(items);

        for (var i = 0; i < 3; i++) {
          expect(
            db.retrieveSync(ItemId(id: 'cm$i', collection: 'col'))?.item['i'],
            equals(i),
          );
        }
      });

      test('retrieveMultipleSync returns list with nulls for missing items', () {
        db.createSync(ItemWithId(id: 'rmA', collection: 'col', item: {'v': 'A'}));
        db.createSync(ItemWithId(id: 'rmC', collection: 'col', item: {'v': 'C'}));

        final results = db.retrieveMultipleSync([
          ItemId(id: 'rmA', collection: 'col'),
          ItemId(id: 'rmB_missing', collection: 'col'),
          ItemId(id: 'rmC', collection: 'col'),
        ]);

        expect(results, hasLength(3));
        expect(results[0]?.item['v'], equals('A'));
        expect(results[1], isNull);
        expect(results[2]?.item['v'], equals('C'));
      });

      test('retrieveMultipleSync with all missing returns all nulls', () {
        final results = db.retrieveMultipleSync([
          ItemId(id: 'x1', collection: 'col'),
          ItemId(id: 'x2', collection: 'col'),
        ]);
        expect(results, equals([null, null]));
      });
    });

    // -------------------------------------------------------------------------
    // updateSync
    // -------------------------------------------------------------------------

    group('updateSync', () {
      test('updates an existing item', () {
        db.createSync(ItemWithId(id: 'u1', collection: 'col', item: {'v': 'old'}));
        db.updateSync(ItemWithId(id: 'u1', collection: 'col', item: {'v': 'new'}));
        expect(
          db.retrieveSync(ItemId(id: 'u1', collection: 'col'))?.item['v'],
          equals('new'),
        );
      });

      test('throws ItemNotFoundException when item does not exist', () {
        expect(
          () => db.updateSync(ItemWithId(id: 'u_missing', collection: 'col', item: {})),
          throwsA(isA<ItemNotFoundException>()),
        );
      });

      test('throws ItemNotFoundException after delete', () {
        db.createSync(ItemWithId(id: 'u2', collection: 'col', item: {}));
        db.deleteSync(ItemId(id: 'u2', collection: 'col'));
        expect(
          () => db.updateSync(ItemWithId(id: 'u2', collection: 'col', item: {})),
          throwsA(isA<ItemNotFoundException>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // createOrUpdateSync / createOrUpdateMultipleSync
    // -------------------------------------------------------------------------

    group('createOrUpdateSync', () {
      test('creates when item does not exist', () {
        db.createOrUpdateSync(ItemWithId(id: 'cou1', collection: 'col', item: {'v': 1}));
        expect(
          db.retrieveSync(ItemId(id: 'cou1', collection: 'col'))?.item['v'],
          equals(1),
        );
      });

      test('updates when item exists', () {
        db.createSync(ItemWithId(id: 'cou2', collection: 'col', item: {'v': 'old'}));
        db.createOrUpdateSync(ItemWithId(id: 'cou2', collection: 'col', item: {'v': 'new'}));
        expect(
          db.retrieveSync(ItemId(id: 'cou2', collection: 'col'))?.item['v'],
          equals('new'),
        );
      });

      test('does not throw on repeated calls', () {
        final item = ItemWithId(id: 'cou3', collection: 'col', item: {'v': 1});
        expect(() => db.createOrUpdateSync(item), returnsNormally);
        expect(() => db.createOrUpdateSync(item), returnsNormally);
      });
    });

    group('createOrUpdateMultipleSync', () {
      test('creates and updates items in one call', () {
        db.createSync(ItemWithId(id: 'coum0', collection: 'col', item: {'v': 'old'}));

        final items = List.generate(
          3,
          (i) => ItemWithId(id: 'coum$i', collection: 'col', item: {'v': 'new$i'}),
        );
        db.createOrUpdateMultipleSync(items);

        for (var i = 0; i < 3; i++) {
          expect(
            db.retrieveSync(ItemId(id: 'coum$i', collection: 'col'))?.item['v'],
            equals('new$i'),
          );
        }
      });
    });

    // -------------------------------------------------------------------------
    // deleteSync
    // -------------------------------------------------------------------------

    group('deleteSync', () {
      test('deletes an existing item', () {
        db.createSync(ItemWithId(id: 'd1', collection: 'col', item: {}));
        db.deleteSync(ItemId(id: 'd1', collection: 'col'));
        expect(db.retrieveSync(ItemId(id: 'd1', collection: 'col')), isNull);
      });

      test('throws ItemNotFoundException for missing item', () {
        expect(
          () => db.deleteSync(ItemId(id: 'd_missing', collection: 'col')),
          throwsA(isA<ItemNotFoundException>()),
        );
      });

      test('throws ItemNotFoundException on double delete', () {
        db.createSync(ItemWithId(id: 'd2', collection: 'col', item: {}));
        db.deleteSync(ItemId(id: 'd2', collection: 'col'));
        expect(
          () => db.deleteSync(ItemId(id: 'd2', collection: 'col')),
          throwsA(isA<ItemNotFoundException>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // deleteCollectionSync
    // -------------------------------------------------------------------------

    group('deleteCollectionSync', () {
      test('removes all items in the collection', () {
        db.createSync(ItemWithId(id: 'dc1', collection: 'toDelete', item: {}));
        db.createSync(ItemWithId(id: 'dc2', collection: 'toDelete', item: {}));
        db.createSync(ItemWithId(id: 'dc3', collection: 'toKeep', item: {}));

        db.deleteCollectionSync('toDelete');

        expect(db.retrieveSync(ItemId(id: 'dc1', collection: 'toDelete')), isNull);
        expect(db.retrieveSync(ItemId(id: 'dc2', collection: 'toDelete')), isNull);
        expect(db.retrieveSync(ItemId(id: 'dc3', collection: 'toKeep')), isNotNull);
      });

      test('does not throw on non-existent collection', () {
        expect(
          () => db.deleteCollectionSync('nonExistent'),
          returnsNormally,
        );
      });
    });

    // -------------------------------------------------------------------------
    // clearDatabaseSync
    // -------------------------------------------------------------------------

    group('clearDatabaseSync', () {
      test('removes all items from all collections', () {
        db.createSync(ItemWithId(id: 'cl1', collection: 'colA', item: {}));
        db.createSync(ItemWithId(id: 'cl2', collection: 'colB', item: {}));

        db.clearDatabaseSync();

        expect(db.retrieveSync(ItemId(id: 'cl1', collection: 'colA')), isNull);
        expect(db.retrieveSync(ItemId(id: 'cl2', collection: 'colB')), isNull);
      });

      test('does not throw on empty database', () {
        expect(() => db.clearDatabaseSync(), returnsNormally);
      });
    });

    // -------------------------------------------------------------------------
    // getItemsInCollectionSync
    // -------------------------------------------------------------------------

    group('getItemsInCollectionSync', () {
      test('returns item ids in collection', () {
        db.createSync(ItemWithId(id: 'li1', collection: 'listCol', item: {}));
        db.createSync(ItemWithId(id: 'li2', collection: 'listCol', item: {}));
        db.createSync(ItemWithId(id: 'li3', collection: 'otherCol', item: {}));

        final ids = db.getItemsInCollectionSync('listCol');

        expect(ids, contains('li1'));
        expect(ids, contains('li2'));
        expect(ids, isNot(contains('li3')));
      });

      test('returns empty list for non-existent collection', () {
        expect(db.getItemsInCollectionSync('noSuchCol'), isEmpty);
      });

      test('returns empty list after deleteCollectionSync', () {
        db.createSync(ItemWithId(id: 'li4', collection: 'tempCol', item: {}));
        db.deleteCollectionSync('tempCol');
        expect(db.getItemsInCollectionSync('tempCol'), isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // getCollectionsSync
    // -------------------------------------------------------------------------

    group('getCollectionsSync', () {
      test('returns all collection names', () {
        db.createSync(ItemWithId(id: 'gc1', collection: 'colGetA', item: {}));
        db.createSync(ItemWithId(id: 'gc2', collection: 'colGetB', item: {}));
        db.createSync(ItemWithId(id: 'gc3', collection: 'colGetC', item: {}));

        final cols = db.getCollectionsSync();

        expect(cols, contains('colGetA'));
        expect(cols, contains('colGetB'));
        expect(cols, contains('colGetC'));
      });

      test('returns empty list on empty database', () {
        expect(db.getCollectionsSync(), isEmpty);
      });

      test('does not include deleted collection', () {
        db.createSync(ItemWithId(id: 'gc4', collection: 'tempGet', item: {}));
        db.deleteCollectionSync('tempGet');
        expect(db.getCollectionsSync(), isNot(contains('tempGet')));
      });
    });

    // -------------------------------------------------------------------------
    // sequence tests
    // -------------------------------------------------------------------------

    group('sequence', () {
      test('create → update → delete', () {
        final id = ItemId(id: 'seq1', collection: 'col');
        db.createSync(ItemWithId(id: 'seq1', collection: 'col', item: {'v': 1}));
        db.updateSync(ItemWithId(id: 'seq1', collection: 'col', item: {'v': 2}));
        expect(db.retrieveSync(id)?.item['v'], equals(2));
        db.deleteSync(id);
        expect(db.retrieveSync(id), isNull);
      });
    });
  });
}

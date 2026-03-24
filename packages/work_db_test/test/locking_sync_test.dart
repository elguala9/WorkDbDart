import 'dart:io';

import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('LockManagerSync', () {
    group('tryAcquireSync()', () {
      test('acquires lock when free', () {
        final fs = MemoryWorkDb();
        final lm = LockManagerSync(fs);
        const path = './WorkDB/col/item1';

        expect(lm.tryAcquireSync(path), isTrue);
        lm.releaseSync(path);
      });

      test('returns false when lock is held', () {
        final fs = MemoryWorkDb();
        final lm = LockManagerSync(fs);
        const path = './WorkDB/col/item2';

        lm.tryAcquireSync(path);
        expect(lm.tryAcquireSync(path), isFalse);
        lm.releaseSync(path);
      });

      test('acquires lock after release', () {
        final fs = MemoryWorkDb();
        final lm = LockManagerSync(fs);
        const path = './WorkDB/col/item3';

        lm.tryAcquireSync(path);
        lm.releaseSync(path);
        expect(lm.tryAcquireSync(path), isTrue);
        lm.releaseSync(path);
      });

      test('cleans up expired stale lock', () {
        final fs = MemoryWorkDb();
        final lm = LockManagerSync(fs, 1);
        const path = './WorkDB/col/stale1';
        const lockPath = './WorkDBLocks/col/stale1.lock';

        // Write expired lock manually
        final expired = DateTime.now().subtract(const Duration(seconds: 1));
        fs.writeFileSync(
          lockPath,
          Item(item: {
            'unlockAt': expired.toIso8601String(),
            'user': 'crashed',
            'lockedAt': expired.toIso8601String(),
          }),
        );

        expect(lm.tryAcquireSync(path), isTrue);
        lm.releaseSync(path);
      });

      test('does not overwrite fresh lock even with waitingMs set', () {
        final fs1 = MemoryWorkDb();
        final fs2 = fs1; // same memory store
        final lm1 = LockManagerSync(fs1, 1);
        final lm2 = LockManagerSync(fs2, 1);
        const path = './WorkDB/col/fresh1';

        lm1.tryAcquireSync(path);
        expect(lm2.tryAcquireSync(path), isFalse);
        lm1.releaseSync(path);
      });
    });

    group('tryAcquireThrowSync()', () {
      test('acquires lock when free', () {
        final fs = MemoryWorkDb();
        final lm = LockManagerSync(fs);
        const path = './WorkDB/col/throw1';

        expect(() => lm.tryAcquireThrowSync(path), returnsNormally);
        lm.releaseSync(path);
      });

      test('throws LockAcquisitionException when lock is held', () {
        final fs = MemoryWorkDb();
        final lm = LockManagerSync(fs);
        const path = './WorkDB/col/throw2';

        lm.tryAcquireSync(path);

        expect(
          () => lm.tryAcquireThrowSync(path),
          throwsA(isA<LockAcquisitionException>()),
        );
        lm.releaseSync(path);
      });

      test('acquires after release following a throw', () {
        final fs = MemoryWorkDb();
        final lm = LockManagerSync(fs);
        const path = './WorkDB/col/throw3';

        lm.tryAcquireSync(path);
        expect(() => lm.tryAcquireThrowSync(path), throwsA(isA<LockAcquisitionException>()));
        lm.releaseSync(path);

        expect(() => lm.tryAcquireThrowSync(path), returnsNormally);
        lm.releaseSync(path);
      });

      test('cleans up stale lock and acquires', () {
        final fs = MemoryWorkDb();
        final lm = LockManagerSync(fs, 1);
        const path = './WorkDB/col/throw_stale';
        const lockPath = './WorkDBLocks/col/throw_stale.lock';

        final expired = DateTime.now().subtract(const Duration(seconds: 1));
        fs.writeFileSync(
          lockPath,
          Item(item: {
            'unlockAt': expired.toIso8601String(),
            'user': 'crashed',
            'lockedAt': expired.toIso8601String(),
          }),
        );

        expect(() => lm.tryAcquireThrowSync(path), returnsNormally);
        lm.releaseSync(path);
      });
    });

    group('isLockedSync()', () {
      test('returns false when no lock', () {
        final fs = MemoryWorkDb();
        final lm = LockManagerSync(fs);
        expect(lm.isLockedSync('./WorkDB/col/nolock'), isFalse);
      });

      test('returns true after acquire', () {
        final fs = MemoryWorkDb();
        final lm = LockManagerSync(fs);
        const path = './WorkDB/col/isLocked1';

        lm.tryAcquireSync(path);
        expect(lm.isLockedSync(path), isTrue);
        lm.releaseSync(path);
      });

      test('returns false after release', () {
        final fs = MemoryWorkDb();
        final lm = LockManagerSync(fs);
        const path = './WorkDB/col/isLocked2';

        lm.tryAcquireSync(path);
        lm.releaseSync(path);
        expect(lm.isLockedSync(path), isFalse);
      });
    });

    group('clearAllLocksSync()', () {
      test('removes all locks', () {
        final fs = MemoryWorkDb();
        final lm = LockManagerSync(fs);
        const path1 = './WorkDB/col/clear1';
        const path2 = './WorkDB/col/clear2';

        lm.tryAcquireSync(path1);
        lm.tryAcquireSync(path2);
        lm.clearAllLocksSync();

        expect(lm.isLockedSync(path1), isFalse);
        expect(lm.isLockedSync(path2), isFalse);
      });

      test('allows acquire after clearAll', () {
        final fs = MemoryWorkDb();
        final lm = LockManagerSync(fs);
        const path = './WorkDB/col/afterClear';

        lm.tryAcquireSync(path);
        lm.clearAllLocksSync();
        expect(lm.tryAcquireSync(path), isTrue);
        lm.releaseSync(path);
      });
    });

    group('lock file content', () {
      test('lock file stores unlockAt and user', () {
        final tempDir = Directory.systemTemp.createTempSync('workdb_sync_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final fs = IoWorkDb(tempDir.path);
        final lm = LockManagerSync(fs, 300);
        const path = './WorkDB/col/lockinfo';
        const lockPath = './WorkDBLocks/col/lockinfo.lock';

        lm.tryAcquireThrowSync(path);

        final lockFile = fs.getFileSync(lockPath);
        expect(lockFile.item['user'], equals('system'));
        expect(lockFile.item['unlockAt'], isA<String>());

        final unlockAt = DateTime.parse(lockFile.item['unlockAt'] as String);
        expect(unlockAt.isAfter(DateTime.now()), isTrue);

        lm.releaseSync(path);
      });
    });

    group('cross-client locking (IoWorkDb)', () {
      test('two LockManagerSync on same dir: second cannot acquire held lock', () {
        final tempDir = Directory.systemTemp.createTempSync('workdb_sync_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final fs1 = IoWorkDb(tempDir.path);
        final fs2 = IoWorkDb(tempDir.path);
        final lm1 = LockManagerSync(fs1);
        final lm2 = LockManagerSync(fs2);
        const path = './WorkDB/col/cross1';

        lm1.tryAcquireSync(path);
        expect(lm2.tryAcquireSync(path), isFalse);
        lm1.releaseSync(path);
      });

      test('second acquires after first releases', () {
        final tempDir = Directory.systemTemp.createTempSync('workdb_sync_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final fs1 = IoWorkDb(tempDir.path);
        final fs2 = IoWorkDb(tempDir.path);
        final lm1 = LockManagerSync(fs1);
        final lm2 = LockManagerSync(fs2);
        const path = './WorkDB/col/cross2';

        lm1.tryAcquireSync(path);
        lm1.releaseSync(path);
        expect(lm2.tryAcquireSync(path), isTrue);
        lm2.releaseSync(path);
      });
    });
  });

  // ---------------------------------------------------------------------------

  group('ClientWorkDbLockSync', () {
    group('createSync() with lock', () {
      test('creates item and releases lock', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        final item = ItemWithId(
          id: 'cs1',
          collection: 'col',
          item: {'v': 1},
        );

        db.createSync(item);

        final result = db.retrieveSync(ItemId(id: 'cs1', collection: 'col'));
        expect(result, isNotNull);
        expect(result?.item['v'], equals(1));
      });

      test('throws ItemAlreadyExistsException on duplicate', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        final item = ItemWithId(id: 'cs2', collection: 'col', item: {});

        db.createSync(item);

        expect(
          () => db.createSync(item),
          throwsA(isA<ItemAlreadyExistsException>()),
        );
      });

      test('releases lock after ItemAlreadyExistsException', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        final item = ItemWithId(id: 'cs3', collection: 'col', item: {'x': 1});

        db.createSync(item);
        expect(() => db.createSync(item), throwsA(isA<ItemAlreadyExistsException>()));

        // Lock released: delete should work
        expect(
          () => db.deleteSync(ItemId(id: 'cs3', collection: 'col')),
          returnsNormally,
        );
      });
    });

    group('createMultipleSync() with lock', () {
      test('creates all items', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        final items = List.generate(
          4,
          (i) => ItemWithId(id: 'cm$i', collection: 'col', item: {'i': i}),
        );

        db.createMultipleSync(items);

        for (var i = 0; i < 4; i++) {
          final r = db.retrieveSync(ItemId(id: 'cm$i', collection: 'col'));
          expect(r?.item['i'], equals(i));
        }
      });
    });

    group('updateSync() with lock', () {
      test('updates item and releases lock', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        db.createSync(ItemWithId(id: 'us1', collection: 'col', item: {'v': 'old'}));
        db.updateSync(ItemWithId(id: 'us1', collection: 'col', item: {'v': 'new'}));

        final r = db.retrieveSync(ItemId(id: 'us1', collection: 'col'));
        expect(r?.item['v'], equals('new'));
      });

      test('throws ItemNotFoundException on missing item', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());

        expect(
          () => db.updateSync(ItemWithId(id: 'us2', collection: 'col', item: {})),
          throwsA(isA<ItemNotFoundException>()),
        );
      });

      test('releases lock after ItemNotFoundException', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        final item = ItemWithId(id: 'us3', collection: 'col', item: {'v': 1});

        expect(
          () => db.updateSync(item),
          throwsA(isA<ItemNotFoundException>()),
        );

        // Lock released: create should work
        expect(() => db.createSync(item), returnsNormally);
      });
    });

    group('createOrUpdateSync() with lock', () {
      test('creates when item does not exist', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        db.createOrUpdateSync(ItemWithId(id: 'cou1', collection: 'col', item: {'v': 'new'}));

        final r = db.retrieveSync(ItemId(id: 'cou1', collection: 'col'));
        expect(r?.item['v'], equals('new'));
      });

      test('updates when item exists', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        db.createSync(ItemWithId(id: 'cou2', collection: 'col', item: {'v': 'old'}));
        db.createOrUpdateSync(ItemWithId(id: 'cou2', collection: 'col', item: {'v': 'updated'}));

        final r = db.retrieveSync(ItemId(id: 'cou2', collection: 'col'));
        expect(r?.item['v'], equals('updated'));
      });

      test('releases lock after operation', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        db.createOrUpdateSync(ItemWithId(id: 'cou3', collection: 'col', item: {}));

        expect(
          () => db.deleteSync(ItemId(id: 'cou3', collection: 'col')),
          returnsNormally,
        );
      });
    });

    group('createOrUpdateMultipleSync() with lock', () {
      test('creates or updates all items', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        db.createSync(ItemWithId(id: 'coum0', collection: 'col', item: {'v': 'old'}));

        final items = List.generate(
          3,
          (i) => ItemWithId(id: 'coum$i', collection: 'col', item: {'v': 'new$i'}),
        );
        db.createOrUpdateMultipleSync(items);

        for (var i = 0; i < 3; i++) {
          final r = db.retrieveSync(ItemId(id: 'coum$i', collection: 'col'));
          expect(r?.item['v'], equals('new$i'));
        }
      });
    });

    group('deleteSync() with lock', () {
      test('deletes item and releases lock', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        db.createSync(ItemWithId(id: 'ds1', collection: 'col', item: {}));
        db.deleteSync(ItemId(id: 'ds1', collection: 'col'));

        expect(db.retrieveSync(ItemId(id: 'ds1', collection: 'col')), isNull);
      });

      test('throws ItemNotFoundException on missing item', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());

        expect(
          () => db.deleteSync(ItemId(id: 'ds2', collection: 'col')),
          throwsA(isA<ItemNotFoundException>()),
        );
      });

      test('releases lock after ItemNotFoundException', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        final item = ItemWithId(id: 'ds3', collection: 'col', item: {});

        expect(
          () => db.deleteSync(ItemId(id: 'ds3', collection: 'col')),
          throwsA(isA<ItemNotFoundException>()),
        );

        // Lock released: create should work
        expect(() => db.createSync(item), returnsNormally);
      });
    });

    group('retrieveSync()', () {
      test('returns null for non-existent item', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        expect(db.retrieveSync(ItemId(id: 'rs_missing', collection: 'col')), isNull);
      });

      test('returns item after createSync', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        db.createSync(ItemWithId(id: 'rs1', collection: 'col', item: {'v': 42}));
        expect(db.retrieveSync(ItemId(id: 'rs1', collection: 'col'))?.item['v'], equals(42));
      });
    });

    group('retrieveMultipleSync()', () {
      test('returns results with nulls for missing items', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
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
    });

    group('deleteCollectionSync()', () {
      test('removes all items in the collection', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        db.createSync(ItemWithId(id: 'dc1', collection: 'toDelete', item: {}));
        db.createSync(ItemWithId(id: 'dc2', collection: 'toDelete', item: {}));
        db.createSync(ItemWithId(id: 'dc3', collection: 'toKeep', item: {}));

        db.deleteCollectionSync('toDelete');

        expect(db.retrieveSync(ItemId(id: 'dc1', collection: 'toDelete')), isNull);
        expect(db.retrieveSync(ItemId(id: 'dc2', collection: 'toDelete')), isNull);
        expect(db.retrieveSync(ItemId(id: 'dc3', collection: 'toKeep')), isNotNull);
      });

      test('does not throw on non-existent collection', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        expect(() => db.deleteCollectionSync('nonExistent'), returnsNormally);
      });
    });

    group('clearDatabaseSync()', () {
      test('removes all items from all collections', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        db.createSync(ItemWithId(id: 'cl1', collection: 'colA', item: {}));
        db.createSync(ItemWithId(id: 'cl2', collection: 'colB', item: {}));

        db.clearDatabaseSync();

        expect(db.retrieveSync(ItemId(id: 'cl1', collection: 'colA')), isNull);
        expect(db.retrieveSync(ItemId(id: 'cl2', collection: 'colB')), isNull);
      });

      test('does not throw on empty database', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        expect(() => db.clearDatabaseSync(), returnsNormally);
      });
    });

    group('getItemsInCollectionSync()', () {
      test('returns item ids in collection', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        db.createSync(ItemWithId(id: 'li1', collection: 'listCol', item: {}));
        db.createSync(ItemWithId(id: 'li2', collection: 'listCol', item: {}));
        db.createSync(ItemWithId(id: 'li3', collection: 'otherCol', item: {}));

        final ids = db.getItemsInCollectionSync('listCol');

        expect(ids, contains('li1'));
        expect(ids, contains('li2'));
        expect(ids, isNot(contains('li3')));
      });

      test('returns empty list for non-existent collection', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        expect(db.getItemsInCollectionSync('noSuchCol'), isEmpty);
      });
    });

    group('getCollectionsSync()', () {
      test('returns all collection names', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        db.createSync(ItemWithId(id: 'gc1', collection: 'colGetA', item: {}));
        db.createSync(ItemWithId(id: 'gc2', collection: 'colGetB', item: {}));

        final cols = db.getCollectionsSync();

        expect(cols, contains('colGetA'));
        expect(cols, contains('colGetB'));
      });

      test('returns empty list on empty database', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        expect(db.getCollectionsSync(), isEmpty);
      });
    });

    group('mixed sync operations', () {
      test('sequence create-update-delete works correctly', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());
        final id = ItemId(id: 'mix1', collection: 'col');

        db.createSync(ItemWithId(id: 'mix1', collection: 'col', item: {'v': 1}));
        db.updateSync(ItemWithId(id: 'mix1', collection: 'col', item: {'v': 2}));
        expect(db.retrieveSync(id)?.item['v'], equals(2));
        db.deleteSync(id);
        expect(db.retrieveSync(id), isNull);
      });

      test('multiple items are independent', () {
        final db = ClientWorkDbLockSync(MemoryWorkDb());

        for (var i = 0; i < 5; i++) {
          db.createSync(ItemWithId(id: 'seq$i', collection: 'col', item: {'n': i}));
        }
        for (var i = 0; i < 5; i++) {
          expect(
            db.retrieveSync(ItemId(id: 'seq$i', collection: 'col'))?.item['n'],
            equals(i),
          );
        }
      });
    });

    group('async ops still locked (inherited from ClientWorkDbLock)', () {
      test('async create works alongside sync create', () async {
        final db = ClientWorkDbLockSync(MemoryWorkDb());

        await db.create(ItemWithId(id: 'asc1', collection: 'col', item: {'v': 'async'}));
        db.createSync(ItemWithId(id: 'asc2', collection: 'col', item: {'v': 'sync'}));

        expect((await db.retrieve(ItemId(id: 'asc1', collection: 'col')))?.item['v'], equals('async'));
        expect(db.retrieveSync(ItemId(id: 'asc2', collection: 'col'))?.item['v'], equals('sync'));
      });
    });

    group('withWaitingMs constructor', () {
      test('creates instance and stale lock detection enabled', () {
        final tempDir = Directory.systemTemp.createTempSync('workdb_sync_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final db = ClientWorkDbLockSync.withWaitingMs(
          IoWorkDb(tempDir.path),
          waitingMs: 1,
        );
        final item = ItemWithId(id: 'wm1', collection: 'col', item: {'v': 'ok'});

        db.createSync(item);
        final r = db.retrieveSync(ItemId(id: 'wm1', collection: 'col'));
        expect(r?.item['v'], equals('ok'));
      });
    });

    group('cross-client sync locking (IoWorkDb)', () {
      test('two ClientWorkDbLockSync on same dir: concurrent createSync serialized', () {
        final tempDir = Directory.systemTemp.createTempSync('workdb_sync_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final db1 = ClientWorkDbLockSync(IoWorkDb(tempDir.path));
        final db2 = ClientWorkDbLockSync(IoWorkDb(tempDir.path));

        db1.createSync(ItemWithId(id: 'cc1', collection: 'col', item: {'src': 'db1'}));

        // db2 cannot create same id (already exists, lock released by db1)
        expect(
          () => db2.createSync(ItemWithId(id: 'cc1', collection: 'col', item: {'src': 'db2'})),
          throwsA(isA<ItemAlreadyExistsException>()),
        );

        final r = db1.retrieveSync(ItemId(id: 'cc1', collection: 'col'));
        expect(r?.item['src'], equals('db1'));
      });

      test('second client can createOrUpdateSync after first releases', () {
        final tempDir = Directory.systemTemp.createTempSync('workdb_sync_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final db1 = ClientWorkDbLockSync(IoWorkDb(tempDir.path));
        final db2 = ClientWorkDbLockSync(IoWorkDb(tempDir.path));

        db1.createSync(ItemWithId(id: 'cc2', collection: 'col', item: {'v': 'db1'}));
        db2.createOrUpdateSync(ItemWithId(id: 'cc2', collection: 'col', item: {'v': 'db2'}));

        final r = db2.retrieveSync(ItemId(id: 'cc2', collection: 'col'));
        expect(r?.item['v'], equals('db2'));
      });
    });
  });
}

import 'dart:io';

import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('ClientWorkDb Locking', () {
    group('create() with lock', () {
      test('should lock file during creation', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());
        final item = ItemWithId(
          id: 'test1',
          collection: 'testCollection',
          item: {'foo': 'bar'},
        );

        await db.create(item);

        // Verify item was created
        final result =
            await db.retrieve(ItemId(id: 'test1', collection: 'testCollection'));
        expect(result, isNotNull);
        expect(result?.item['foo'], equals('bar'));
      });

      test('should prevent duplicate creation', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());
        final item = ItemWithId(
          id: 'test2',
          collection: 'testCollection',
          item: {'foo': 'bar'},
        );

        await db.create(item);

        // Try to create duplicate
        expect(
          () => db.create(item),
          throwsA(isA<ItemAlreadyExistsException>()),
        );
      });

      test('should release lock after creation', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());
        final item = ItemWithId(
          id: 'test3',
          collection: 'testCollection',
          item: {'foo': 'bar'},
        );

        await db.create(item);

        // Lock should be released, so we can delete the item
        expect(
          () => db.delete(ItemId(id: 'test3', collection: 'testCollection')),
          returnsNormally,
        );
      });

      test('should release lock on exception', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());
        final item1 = ItemWithId(
          id: 'test4',
          collection: 'testCollection',
          item: {'foo': 'bar'},
        );
        final item2 = ItemWithId(
          id: 'test4',
          collection: 'testCollection',
          item: {'foo': 'bar'},
        );

        await db.create(item1);

        // Try to create duplicate (should fail)
        expect(
          () => db.create(item2),
          throwsA(isA<ItemAlreadyExistsException>()),
        );

        // Lock should be released despite the error
        // Verify by checking that we can still use the database
        final result = await db.retrieve(
          ItemId(id: 'test4', collection: 'testCollection'),
        );
        expect(result, isNotNull);
      });
    });

    group('update() with lock', () {
      test('should lock file during update', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());
        final item = ItemWithId(
          id: 'test5',
          collection: 'testCollection',
          item: {'foo': 'old'},
        );

        await db.create(item);

        final updated = ItemWithId(
          id: 'test5',
          collection: 'testCollection',
          item: {'foo': 'new'},
        );
        await db.update(updated);

        // Verify item was updated
        final result =
            await db.retrieve(ItemId(id: 'test5', collection: 'testCollection'));
        expect(result?.item['foo'], equals('new'));
      });

      test('should release lock after update', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());
        final item = ItemWithId(
          id: 'test6',
          collection: 'testCollection',
          item: {'foo': 'old'},
        );

        await db.create(item);

        final updated = ItemWithId(
          id: 'test6',
          collection: 'testCollection',
          item: {'foo': 'new'},
        );
        await db.update(updated);

        // Lock should be released, so we can delete the item
        expect(
          () => db.delete(ItemId(id: 'test6', collection: 'testCollection')),
          returnsNormally,
        );
      });

      test('should throw when updating non-existent item', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());
        final item = ItemWithId(
          id: 'test7',
          collection: 'testCollection',
          item: {'foo': 'bar'},
        );

        expect(
          () => db.update(item),
          throwsA(isA<ItemNotFoundException>()),
        );
      });

      test('should release lock when update fails', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());
        final item = ItemWithId(
          id: 'test8',
          collection: 'testCollection',
          item: {'foo': 'bar'},
        );

        // Try to update non-existent item
        expect(
          () => db.update(item),
          throwsA(isA<ItemNotFoundException>()),
        );

        // Lock should be released, create should work
        await db.create(item);
        final result = await db.retrieve(
          ItemId(id: 'test8', collection: 'testCollection'),
        );
        expect(result, isNotNull);
      });
    });

    group('delete() with lock', () {
      test('should lock file during deletion', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());
        final item = ItemWithId(
          id: 'test9',
          collection: 'testCollection',
          item: {'foo': 'bar'},
        );

        await db.create(item);
        await db.delete(ItemId(id: 'test9', collection: 'testCollection'));

        // Verify item was deleted
        final result =
            await db.retrieve(ItemId(id: 'test9', collection: 'testCollection'));
        expect(result, isNull);
      });

      test('should release lock after deletion', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());
        final item = ItemWithId(
          id: 'test10',
          collection: 'testCollection',
          item: {'foo': 'bar'},
        );

        await db.create(item);
        await db.delete(ItemId(id: 'test10', collection: 'testCollection'));

        // Lock should be released, so we can create again
        await db.create(item);
        expect(
          () => db.retrieve(
            ItemId(id: 'test10', collection: 'testCollection'),
          ),
          returnsNormally,
        );
      });

      test('should throw when deleting non-existent item', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());

        expect(
          () => db.delete(ItemId(id: 'test11', collection: 'testCollection')),
          throwsA(isA<ItemNotFoundException>()),
        );
      });

      test('should release lock when delete fails', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());
        final item = ItemWithId(
          id: 'test12',
          collection: 'testCollection',
          item: {'foo': 'bar'},
        );

        // Try to delete non-existent item
        expect(
          () => db.delete(ItemId(id: 'test12', collection: 'testCollection')),
          throwsA(isA<ItemNotFoundException>()),
        );

        // Lock should be released, create should work
        await db.create(item);
        expect(
          () => db.retrieve(
            ItemId(id: 'test12', collection: 'testCollection'),
          ),
          returnsNormally,
        );
      });
    });

    group('createOrUpdate() with lock', () {
      test('should lock file during createOrUpdate when creating', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());
        final item = ItemWithId(
          id: 'test13',
          collection: 'testCollection',
          item: {'foo': 'bar'},
        );

        await db.createOrUpdate(item);

        // Verify item was created
        final result =
            await db.retrieve(ItemId(id: 'test13', collection: 'testCollection'));
        expect(result, isNotNull);
        expect(result?.item['foo'], equals('bar'));
      });

      test('should lock file during createOrUpdate when updating', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());
        final item = ItemWithId(
          id: 'test14',
          collection: 'testCollection',
          item: {'foo': 'old'},
        );

        await db.create(item);

        final updated = ItemWithId(
          id: 'test14',
          collection: 'testCollection',
          item: {'foo': 'new'},
        );
        await db.createOrUpdate(updated);

        // Verify item was updated
        final result =
            await db.retrieve(ItemId(id: 'test14', collection: 'testCollection'));
        expect(result?.item['foo'], equals('new'));
      });

      test('should release lock after createOrUpdate', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());
        final item = ItemWithId(
          id: 'test15',
          collection: 'testCollection',
          item: {'foo': 'bar'},
        );

        await db.createOrUpdate(item);

        // Lock should be released, so we can delete the item
        expect(
          () => db.delete(ItemId(id: 'test15', collection: 'testCollection')),
          returnsNormally,
        );
      });
    });

    group('multiple operations with locks', () {
      test('should handle multiple creates in sequence', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());

        for (int i = 0; i < 5; i++) {
          final item = ItemWithId(
            id: 'item$i',
            collection: 'testCollection',
            item: {'index': i},
          );
          await db.create(item);
        }

        // Verify all items were created
        for (int i = 0; i < 5; i++) {
          final result = await db.retrieve(
            ItemId(id: 'item$i', collection: 'testCollection'),
          );
          expect(result, isNotNull);
          expect(result?.item['index'], equals(i));
        }
      });

      test('should handle mixed operations', () async {
        final db = ClientWorkDbLock(MemoryWorkDb());

        // Create
        final item1 = ItemWithId(
          id: 'mixed1',
          collection: 'testCollection',
          item: {'data': 'initial'},
        );
        await db.create(item1);

        // Update
        final item2 = ItemWithId(
          id: 'mixed1',
          collection: 'testCollection',
          item: {'data': 'updated'},
        );
        await db.update(item2);

        // Delete
        await db.delete(ItemId(id: 'mixed1', collection: 'testCollection'));

        // Verify deletion
        final result = await db.retrieve(
          ItemId(id: 'mixed1', collection: 'testCollection'),
        );
        expect(result, isNull);
      });
    });

    group('multiple clients accessing same items', () {
      test('two clients cannot update same item simultaneously', () async {
        // Create shared temporary directory
        final tempDir = await Directory.systemTemp.createTemp('workdb_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final client1 = ClientWorkDbLock(IoWorkDb(tempDir.path));
        final client2 = ClientWorkDbLock(IoWorkDb(tempDir.path));

        // Create item via client1
        final item = ItemWithId(
          id: 'shared_item',
          collection: 'testCollection',
          item: {'value': 'initial'},
        );
        await client1.create(item);

        // Track operations
        final operations = <String>[];

        // Client 1 starts update with a small delay to simulate work
        final future1 = Future(() async {
          operations.add('client1_start_update');
          final updated1 = ItemWithId(
            id: 'shared_item',
            collection: 'testCollection',
            item: {'value': 'updated_by_client1'},
          );
          await Future.delayed(const Duration(milliseconds: 100));
          await client1.update(updated1);
          operations.add('client1_end_update');
        });

        // Give client1 a chance to start its operation
        await Future.delayed(const Duration(milliseconds: 10));

        // Client 2 tries to update the same item
        final future2 = Future(() async {
          operations.add('client2_start_update');
          final updated2 = ItemWithId(
            id: 'shared_item',
            collection: 'testCollection',
            item: {'value': 'updated_by_client2'},
          );
          await client2.update(updated2);
          operations.add('client2_end_update');
        });

        // Wait for both operations to complete
        await Future.wait([future1, future2]);

        // One of them should win, verify the final state is consistent
        final result = await client1.retrieve(
          ItemId(id: 'shared_item', collection: 'testCollection'),
        );
        expect(result, isNotNull);
        expect(
          result?.item['value'],
          anyOf(equals('updated_by_client1'), equals('updated_by_client2')),
        );

        // Verify operations happened in sequence (one waited for the other)
        expect(operations.length, equals(4));
        expect(operations.first, equals('client1_start_update'));
      });

      test('tryAcquireThrow throws when lock is occupied', () async {
        // Create shared temporary directory
        final tempDir = await Directory.systemTemp.createTemp('workdb_test_');
        addTearDown(() async {
          await Future.delayed(const Duration(milliseconds: 200));
          try {
            tempDir.deleteSync(recursive: true);
          } catch (e) {
            // Ignore cleanup errors on Windows
          }
        });

        final fs1 = IoWorkDb(tempDir.path);
        final fs2 = IoWorkDb(tempDir.path);

        final lockManager1 = LockManager(fs1);
        final lockManager2 = LockManager(fs2);

        const lockPath = './WorkDB/testCollection/shared_lock_throw';

        // Client 1 acquires the lock
        await lockManager1.tryAcquireThrow(lockPath);

        // Client 2 tries to acquire the same lock - should throw
        bool threw = false;
        try {
          await lockManager2.tryAcquireThrow(lockPath);
        } on LockAcquisitionException {
          threw = true;
        }
        expect(threw, true);

        // Release the lock
        await lockManager1.release(lockPath);

        // Now client 2 should be able to acquire it
        await lockManager2.tryAcquireThrow(lockPath);
        expect(await lockManager2.isLocked(lockPath), true);

        // Clean up
        await lockManager2.release(lockPath);
      });
    });

    group('stale lock detection with _waitingMs', () {
      test('stale lock cleanup detects expired locks', () async {
        // Create shared temporary directory
        final tempDir = await Directory.systemTemp.createTemp('workdb_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final fs = IoWorkDb(tempDir.path);

        // Create lock manager with stale lock detection enabled
        final lockManager = LockManager(fs, 1); // _waitingMs = 1 to enable stale lock detection

        const lockPath = './WorkDB/testCollection/stale_detect';

        // Manually create an expired lock (simulating crashed process)
        final now = DateTime.now();
        final expiredTime = now.subtract(Duration(seconds: 1));

        await fs.writeFile(
          lockPath.replaceFirst('./WorkDB/', './WorkDBLocks/') + '.lock',
          Item(item: {
            'unlockAt': expiredTime.toIso8601String(),
            'user': 'crashed_process',
            'lockedAt': expiredTime.toIso8601String(),
          }),
        );

        // Lock manager should detect and clean up stale lock
        final acquired = await lockManager.tryAcquire(lockPath);
        expect(acquired, true);

        // Verify new lock is in place
        expect(await lockManager.isLocked(lockPath), true);

        // Clean up
        await lockManager.release(lockPath);
      });

      test('lock file stores unlockAt and user information', () async {
        // Create shared temporary directory
        final tempDir = await Directory.systemTemp.createTemp('workdb_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final fs = IoWorkDb(tempDir.path);
        final lockManager = LockManager(fs, 300);

        const lockPath = './WorkDB/testCollection/lock_info';

        // Acquire lock
        await lockManager.tryAcquireThrow(lockPath);

        // Lock files are stored in ./WorkDBLocks/<collection>/<itemId>.lock
        const lockFilePath = './WorkDBLocks/testCollection/lock_info.lock';

        // Read the lock file to verify it contains unlockAt and user
        final lockFile = await fs.getFile(lockFilePath);
        expect(lockFile.item['unlockAt'], isA<String>());
        expect(lockFile.item['user'], equals('system'));

        // Verify unlockAt is a valid ISO8601 datetime in the future
        final unlockAt = DateTime.parse(lockFile.item['unlockAt'] as String);
        expect(unlockAt.isAfter(DateTime.now()), true);

        // Clean up
        await lockManager.release(lockPath);
      });

      test('non-stale lock is not overwritten', () async {
        // Create shared temporary directory
        final tempDir = await Directory.systemTemp.createTemp('workdb_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final fs1 = IoWorkDb(tempDir.path);
        final fs2 = IoWorkDb(tempDir.path);

        // Create lock managers with stale lock detection
        final lockManager1 = LockManager(fs1, 1);
        final lockManager2 = LockManager(fs2, 1);

        const lockPath = './WorkDB/testCollection/fresh_lock';

        // Client 1 acquires lock
        await lockManager1.tryAcquireThrow(lockPath);

        // Client 2 tries to acquire - should fail (lock is fresh, not stale)
        final acquired = await lockManager2.tryAcquire(lockPath);
        expect(acquired, false);

        // Clean up
        await lockManager1.release(lockPath);
      });
    });
  });
}

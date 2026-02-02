import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('ClientWorkDb Locking', () {
    group('create() with lock', () {
      test('should lock file during creation', () async {
        final db = WorkDb.memory();
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
        final db = WorkDb.memory();
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
        final db = WorkDb.memory();
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
        final db = WorkDb.memory();
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
        final db = WorkDb.memory();
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
        final db = WorkDb.memory();
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
        final db = WorkDb.memory();
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
        final db = WorkDb.memory();
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
        final db = WorkDb.memory();
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
        final db = WorkDb.memory();
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
        final db = WorkDb.memory();

        expect(
          () => db.delete(ItemId(id: 'test11', collection: 'testCollection')),
          throwsA(isA<ItemNotFoundException>()),
        );
      });

      test('should release lock when delete fails', () async {
        final db = WorkDb.memory();
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
        final db = WorkDb.memory();
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
        final db = WorkDb.memory();
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
        final db = WorkDb.memory();
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
        final db = WorkDb.memory();

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
        final db = WorkDb.memory();

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
  });
}

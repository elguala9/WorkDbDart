import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

import 'test_utility.dart';

/// Runs the complete WorkDB test suite against the provided [IWorkDb] implementation.
///
/// This function contains all the standard tests that any WorkDB implementation
/// should pass. It's designed to be reusable across different implementations
/// (IO, Web, Memory, etc.).
///
/// ## Usage
///
/// ```dart
/// void main() {
///   group('Memory WorkDB', () {
///     late IWorkDb workDb;
///
///     setUp(() {
///       workDb = WorkDbFactory.createMemory();
///     });
///
///     testIWorkDb(() => workDb);
///   });
/// }
/// ```
///
/// [getWorkDb] is a function that returns the WorkDB instance to test.
/// Using a function allows for proper setup/teardown between tests.
void testIWorkDb(IWorkDb Function() getWorkDb) {
  group('WorkDB Tests', () {
    late IWorkDb workDb;

    setUp(() {
      workDb = getWorkDb();
    });

    test('should create and retrieve an item', () async {
      final itemId = ItemId(id: 'test1', collection: 'testCollection');
      final item = ItemWithId(
        id: 'test1',
        collection: 'testCollection',
        item: {'foo': 'bar'},
      );

      await workDb.create(item);
      final result = await workDb.retrieve(itemId);

      expect(result, isNotNull);
      expect(result?.item['foo'], equals('bar'));
    });

    test('should not create duplicate items', () async {
      final item = ItemWithId(
        id: 'test2',
        collection: 'testCollection',
        item: {'foo': 'baz'},
      );

      await workDb.create(item);

      expect(
        () => workDb.create(item),
        throwsA(isA<Exception>()),
      );
    });

    test('should update an item', () async {
      final itemId = ItemId(id: 'test3', collection: 'testCollection');
      final item = ItemWithId(
        id: 'test3',
        collection: 'testCollection',
        item: {'foo': 'old'},
      );

      await workDb.create(item);

      final updated = ItemWithId(
        id: 'test3',
        collection: 'testCollection',
        item: {'foo': 'new'},
      );
      await workDb.update(updated);

      final result = await workDb.retrieve(itemId);
      expect(result?.item['foo'], equals('new'));
    });

    test('should delete an item', () async {
      final itemId = ItemId(id: 'test4', collection: 'testCollection');
      final item = ItemWithId(
        id: 'test4',
        collection: 'testCollection',
        item: {'foo': 'delete'},
      );

      await workDb.create(item);
      await workDb.delete(itemId);

      final result = await workDb.retrieve(itemId);
      expect(result, isNull);
    });

    test('should create and retrieve multiple items', () async {
      final items = [
        ItemWithId(id: 'multi1', collection: 'testCollection', item: {'foo': 1}),
        ItemWithId(id: 'multi2', collection: 'testCollection', item: {'foo': 2}),
      ];

      await workDb.createMultiple(items);

      final results = await workDb.retrieveMultiple([
        ItemId(id: 'multi1', collection: 'testCollection'),
        ItemId(id: 'multi2', collection: 'testCollection'),
      ]);

      expect(results[0]?.item['foo'], equals(1));
      expect(results[1]?.item['foo'], equals(2));
    });

    test('should return null for non-existent item', () async {
      final itemId = ItemId(id: 'notfound', collection: 'testCollection');
      final result = await workDb.retrieve(itemId);
      expect(result, isNull);
    });

    test('should throw when updating non-existent item', () async {
      final item = ItemWithId(
        id: 'noitem',
        collection: 'testCollection',
        item: {'foo': 'fail'},
      );

      expect(
        () => workDb.update(item),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw when deleting non-existent item', () async {
      final itemId = ItemId(id: 'noitem', collection: 'testCollection');

      expect(
        () => workDb.delete(itemId),
        throwsA(isA<Exception>()),
      );
    });

    test('should not create item with empty id or collection', () async {
      expect(
        () => ItemWithId(id: '', collection: 'testCollection', item: {'foo': 'bad'}),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => ItemWithId(id: 'bad', collection: '', item: {'foo': 'bad'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should handle update after delete', () async {
      final itemId = ItemId(id: 'delupdate', collection: 'testCollection');
      final item = ItemWithId(
        id: 'delupdate',
        collection: 'testCollection',
        item: {'foo': 'first'},
      );

      await workDb.create(item);
      await workDb.delete(itemId);

      expect(
        () => workDb.update(item),
        throwsA(isA<Exception>()),
      );
    });

    test('should retrieve multiple with some missing', () async {
      final items = [
        ItemWithId(id: 'multiA', collection: 'testCollection', item: {'foo': 'A'}),
        ItemWithId(id: 'multiB', collection: 'testCollection', item: {'foo': 'B'}),
      ];

      await workDb.createMultiple(items);

      final ids = [
        ItemId(id: 'multiA', collection: 'testCollection'),
        ItemId(id: 'notfound', collection: 'testCollection'),
        ItemId(id: 'multiB', collection: 'testCollection'),
      ];

      final results = await workDb.retrieveMultiple(ids);

      expect(results[0]?.item['foo'], equals('A'));
      expect(results[1], isNull);
      expect(results[2]?.item['foo'], equals('B'));
    });

    test('should delete multiple items', () async {
      final items = [
        ItemWithId(id: 'del1', collection: 'testCollection', item: {'foo': 1}),
        ItemWithId(id: 'del2', collection: 'testCollection', item: {'foo': 2}),
      ];

      await workDb.createMultiple(items);

      for (final item in items) {
        await workDb.delete(ItemId(id: item.id, collection: item.collection));
      }

      final results = await workDb.retrieveMultiple([
        ItemId(id: 'del1', collection: 'testCollection'),
        ItemId(id: 'del2', collection: 'testCollection'),
      ]);

      expect(results[0], isNull);
      expect(results[1], isNull);
    });

    test('should delete a collection', () async {
      final items = [
        ItemWithId(id: 'col1', collection: 'toDelete', item: {'foo': 1}),
        ItemWithId(id: 'col2', collection: 'toDelete', item: {'foo': 2}),
        ItemWithId(id: 'col3', collection: 'toKeep', item: {'foo': 3}),
      ];

      await workDb.createMultiple(items);
      await workDb.deleteCollection('toDelete');

      final results = await workDb.retrieveMultiple([
        ItemId(id: 'col1', collection: 'toDelete'),
        ItemId(id: 'col2', collection: 'toDelete'),
        ItemId(id: 'col3', collection: 'toKeep'),
      ]);

      expect(results[0], isNull);
      expect(results[1], isNull);
      expect(results[2]?.item['foo'], equals(3));
    });

    test('should clear the database', () async {
      final items = [
        ItemWithId(id: 'db1', collection: 'colA', item: {'foo': 'A'}),
        ItemWithId(id: 'db2', collection: 'colB', item: {'foo': 'B'}),
      ];

      await workDb.createMultiple(items);
      await workDb.clearDatabase();

      final results = await workDb.retrieveMultiple([
        ItemId(id: 'db1', collection: 'colA'),
        ItemId(id: 'db2', collection: 'colB'),
      ]);

      expect(results[0], isNull);
      expect(results[1], isNull);
    });

    test('should list items in a collection', () async {
      final items = [
        ItemWithId(id: 'item10', collection: 'colListA', item: {'foo': 1}),
        ItemWithId(id: 'item20', collection: 'colListA', item: {'foo': 2}),
        ItemWithId(id: 'item30', collection: 'colListB', item: {'foo': 3}),
      ];

      await workDb.createMultiple(items);

      final idsA = await workDb.getItemsInCollection('colListA');

      expect(idsA, contains('item10'));
      expect(idsA, contains('item20'));
      expect(idsA, isNot(contains('item30')));
    });

    test('should list all collections', () async {
      final items = [
        ItemWithId(id: 'item11', collection: 'colGetA', item: {'foo': 1}),
        ItemWithId(id: 'item21', collection: 'colGetB', item: {'foo': 2}),
        ItemWithId(id: 'item31', collection: 'colGetC', item: {'foo': 3}),
      ];

      await workDb.createMultiple(items);

      final collections = await workDb.getCollections();

      expect(collections, contains('colGetA'));
      expect(collections, contains('colGetB'));
      expect(collections, contains('colGetC'));
    });

    test('should handle message data with Uint8List', () async {
      final messageData = exampleMessageData[0];
      final uniqueId = 'single_${DateTime.now().millisecondsSinceEpoch}_msg_${messageData.id}';
      final itemId = ItemId(id: uniqueId, collection: 'messages_single');

      final item = ItemWithId(
        id: uniqueId,
        collection: 'messages_single',
        item: {
          'id': messageData.id,
          'data': messageData.data.toList(), // Convert Uint8List to List<int>
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      await workDb.create(item);
      final result = await workDb.retrieve(itemId);

      expect(result, isNotNull);

      // Reconstruct MessageData from stored item
      final retrievedMessageData = MessageData(
        id: result!.item['id'] as int,
        data: Uint8List.fromList((result.item['data'] as List).cast<int>()),
      );

      // Use eqMessageData for precise comparison
      expect(eqMessageData(messageData, retrievedMessageData), isTrue);
    });

    test('should create and retrieve multiple message data items', () async {
      final testMessages = exampleMessageData.sublist(0, 5);
      final uniquePrefix = 'multi_${DateTime.now().millisecondsSinceEpoch}';

      final items = testMessages.map((msg) => ItemWithId(
        id: '${uniquePrefix}_msg_${msg.id}',
        collection: 'messages_multi',
        item: {
          'id': msg.id,
          'data': msg.data.toList(),
          'size': msg.data.length,
          'created': DateTime.now().toIso8601String(),
        },
      )).toList();

      await workDb.createMultiple(items);

      final ids = items
          .map((item) => ItemId(id: item.id, collection: item.collection))
          .toList();
      final results = await workDb.retrieveMultiple(ids);

      expect(results, hasLength(5));

      for (var i = 0; i < results.length; i++) {
        final result = results[i];
        expect(result, isNotNull);

        // Reconstruct MessageData from stored item
        final retrievedMessageData = MessageData(
          id: result!.item['id'] as int,
          data: Uint8List.fromList((result.item['data'] as List).cast<int>()),
        );

        // Use eqMessageData for precise comparison
        expect(eqMessageData(testMessages[i], retrievedMessageData), isTrue);
      }
    });

    test('should update message data', () async {
      final originalMessage = exampleMessageData[2];
      final uniqueId = 'update_${DateTime.now().millisecondsSinceEpoch}_msg_${originalMessage.id}';
      final itemId = ItemId(id: uniqueId, collection: 'messages_update');

      final item = ItemWithId(
        id: uniqueId,
        collection: 'messages_update',
        item: {
          'id': originalMessage.id,
          'data': originalMessage.data.toList(),
          'version': 1,
        },
      );

      await workDb.create(item);

      // Update with new data
      final updatedMessage = MessageData(
        id: originalMessage.id,
        data: Uint8List.fromList([100, 101, 102]),
      );

      final updatedItem = ItemWithId(
        id: uniqueId,
        collection: 'messages_update',
        item: {
          'id': updatedMessage.id,
          'data': updatedMessage.data.toList(),
          'version': 2,
          'updated': DateTime.now().toIso8601String(),
        },
      );

      await workDb.update(updatedItem);
      final result = await workDb.retrieve(itemId);

      expect(result, isNotNull);

      // Reconstruct MessageData from stored item
      final retrievedMessageData = MessageData(
        id: result!.item['id'] as int,
        data: Uint8List.fromList((result.item['data'] as List).cast<int>()),
      );

      // Use eqMessageData to verify the update
      expect(eqMessageData(updatedMessage, retrievedMessageData), isTrue);
      expect(result.item['version'], equals(2));
    });

    test('should handle large message collection operations', () async {
      // Create all example messages with unique IDs
      final uniquePrefix = 'large_${DateTime.now().millisecondsSinceEpoch}';

      final items = exampleMessageData.map((msg) => ItemWithId(
        id: '${uniquePrefix}_msg_${msg.id}',
        collection: 'largeMessages',
        item: {
          'id': msg.id,
          'data': msg.data.toList(),
          'checksum': msg.data.fold<int>(0, (sum, byte) => sum + byte),
        },
      )).toList();

      await workDb.createMultiple(items);

      // Verify all messages were created
      final messageIds = await workDb.getItemsInCollection('largeMessages');
      expect(messageIds.length, greaterThanOrEqualTo(exampleMessageData.length));

      // Delete half of the messages
      final toDelete = items.sublist(0, items.length ~/ 2);
      for (final item in toDelete) {
        await workDb.delete(ItemId(id: item.id, collection: item.collection));
      }

      // Verify remaining messages
      final remainingIds = await workDb.getItemsInCollection('largeMessages');
      expect(remainingIds.length, lessThan(messageIds.length));
    });

    test('should preserve binary data integrity', () async {
      final messageData = exampleMessageData[5];
      final itemId = ItemId(id: 'integrity_${messageData.id}', collection: 'integrity');
      final originalArray = messageData.data.toList();

      final item = ItemWithId(
        id: 'integrity_${messageData.id}',
        collection: 'integrity',
        item: {
          'originalData': originalArray,
          'metadata': {
            'length': messageData.data.length,
            'firstByte': messageData.data[0],
            'lastByte': messageData.data[messageData.data.length - 1],
          },
        },
      );

      await workDb.create(item);
      final result = await workDb.retrieve(itemId);

      expect(result, isNotNull);
      expect(result?.item['originalData'], equals(originalArray));

      final metadata = result!.item['metadata'] as Map<String, dynamic>;
      expect(metadata['length'], equals(messageData.data.length));
      expect(metadata['firstByte'], equals(messageData.data[0]));
      expect(metadata['lastByte'], equals(messageData.data[messageData.data.length - 1]));

      // Verify we can reconstruct the Uint8List
      final reconstructed = Uint8List.fromList(
        (result.item['originalData'] as List).cast<int>(),
      );
      expect(reconstructed, equals(messageData.data));
    });

    test('should validate message data equality using eqMessageData', () async {
      final testMessages = exampleMessageData.sublist(6, 9);

      // Store all test messages
      for (final msg in testMessages) {
        final item = ItemWithId(
          id: 'eq_test_${msg.id}',
          collection: 'equality_test',
          item: {
            'id': msg.id,
            'data': msg.data.toList(),
          },
        );
        await workDb.create(item);
      }

      // Retrieve and compare each message
      for (final originalMsg in testMessages) {
        final itemId = ItemId(id: 'eq_test_${originalMsg.id}', collection: 'equality_test');
        final result = await workDb.retrieve(itemId);

        expect(result, isNotNull);

        final retrievedMsg = MessageData(
          id: result!.item['id'] as int,
          data: Uint8List.fromList((result.item['data'] as List).cast<int>()),
        );

        // This will use eqMessageData and show detailed diff if they don't match
        expect(eqMessageData(originalMsg, retrievedMsg), isTrue);
      }

      // Test that different messages are correctly identified as not equal
      if (testMessages.length >= 2) {
        final firstResult = await workDb.retrieve(
          ItemId(id: 'eq_test_${testMessages[0].id}', collection: 'equality_test'),
        );
        final secondOriginal = testMessages[1];

        final firstRetrieved = MessageData(
          id: firstResult!.item['id'] as int,
          data: Uint8List.fromList((firstResult.item['data'] as List).cast<int>()),
        );

        // This should be false
        expect(eqMessageData(firstRetrieved, secondOriginal), isFalse);
      }
    });

    test('should create or update a single item (createOrUpdate)', () async {
      final itemId = ItemId(id: 'createOrUpdate1', collection: 'testCreateOrUpdate');
      final initialItem = ItemWithId(
        id: 'createOrUpdate1',
        collection: 'testCreateOrUpdate',
        item: {'value': 'initial', 'version': 1},
      );

      // First call should create the item
      await workDb.createOrUpdate(initialItem);
      var result = await workDb.retrieve(itemId);

      expect(result, isNotNull);
      expect(result?.item['value'], equals('initial'));
      expect(result?.item['version'], equals(1));

      // Second call should update the existing item
      final updatedItem = ItemWithId(
        id: 'createOrUpdate1',
        collection: 'testCreateOrUpdate',
        item: {'value': 'updated', 'version': 2},
      );

      await workDb.createOrUpdate(updatedItem);
      result = await workDb.retrieve(itemId);

      expect(result, isNotNull);
      expect(result?.item['value'], equals('updated'));
      expect(result?.item['version'], equals(2));
    });

    test('should create or update multiple items (createOrUpdateMultiple)', () async {
      final items = [
        ItemWithId(
          id: 'createOrUpdateMulti1',
          collection: 'testCreateOrUpdateMulti',
          item: {'name': 'Alice', 'status': 'new'},
        ),
        ItemWithId(
          id: 'createOrUpdateMulti2',
          collection: 'testCreateOrUpdateMulti',
          item: {'name': 'Bob', 'status': 'new'},
        ),
        ItemWithId(
          id: 'createOrUpdateMulti3',
          collection: 'testCreateOrUpdateMulti',
          item: {'name': 'Charlie', 'status': 'new'},
        ),
      ];

      // First call should create all items
      await workDb.createOrUpdateMultiple(items);

      var results = await workDb.retrieveMultiple(
        items.map((i) => ItemId(id: i.id, collection: i.collection)).toList(),
      );

      expect(results, hasLength(3));
      for (var i = 0; i < results.length; i++) {
        expect(results[i], isNotNull);
        expect(results[i]?.item['name'], equals(items[i].item['name']));
        expect(results[i]?.item['status'], equals('new'));
      }

      // Update some items
      final updatedItems = [
        ItemWithId(
          id: 'createOrUpdateMulti1',
          collection: 'testCreateOrUpdateMulti',
          item: {'name': 'Alice Updated', 'status': 'updated'},
        ),
        ItemWithId(
          id: 'createOrUpdateMulti2',
          collection: 'testCreateOrUpdateMulti',
          item: {'name': 'Bob Updated', 'status': 'updated'},
        ),
        ItemWithId(
          id: 'createOrUpdateMulti4',
          collection: 'testCreateOrUpdateMulti',
          item: {'name': 'David', 'status': 'new'}, // New item
        ),
      ];

      await workDb.createOrUpdateMultiple(updatedItems);

      // Verify updates and new creation
      final allIds = [
        ItemId(id: 'createOrUpdateMulti1', collection: 'testCreateOrUpdateMulti'),
        ItemId(id: 'createOrUpdateMulti2', collection: 'testCreateOrUpdateMulti'),
        ItemId(id: 'createOrUpdateMulti3', collection: 'testCreateOrUpdateMulti'), // Unchanged
        ItemId(id: 'createOrUpdateMulti4', collection: 'testCreateOrUpdateMulti'), // New
      ];

      results = await workDb.retrieveMultiple(allIds);

      expect(results[0]?.item['name'], equals('Alice Updated'));
      expect(results[0]?.item['status'], equals('updated'));
      expect(results[1]?.item['name'], equals('Bob Updated'));
      expect(results[1]?.item['status'], equals('updated'));
      expect(results[2]?.item['name'], equals('Charlie')); // Unchanged
      expect(results[2]?.item['status'], equals('new')); // Unchanged
      expect(results[3]?.item['name'], equals('David')); // Newly created
      expect(results[3]?.item['status'], equals('new'));
    });

    test('should handle createOrUpdate with message data', () async {
      final messageData = exampleMessageData[3];
      final uniqueId = 'createOrUpdate_${DateTime.now().millisecondsSinceEpoch}_msg_${messageData.id}';
      final itemId = ItemId(id: uniqueId, collection: 'messages_createOrUpdate');

      // First createOrUpdate - should create
      final initialItem = ItemWithId(
        id: uniqueId,
        collection: 'messages_createOrUpdate',
        item: {
          'id': messageData.id,
          'data': messageData.data.toList(),
          'operation': 'created',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      await workDb.createOrUpdate(initialItem);
      var result = await workDb.retrieve(itemId);

      expect(result, isNotNull);
      expect(result?.item['operation'], equals('created'));

      var retrievedMessageData = MessageData(
        id: result!.item['id'] as int,
        data: Uint8List.fromList((result.item['data'] as List).cast<int>()),
      );
      expect(eqMessageData(messageData, retrievedMessageData), isTrue);

      // Second createOrUpdate - should update with new data
      final updatedMessageData = MessageData(
        id: messageData.id,
        data: Uint8List.fromList([200, 201, 202, 203]),
      );

      final updatedItem = ItemWithId(
        id: uniqueId,
        collection: 'messages_createOrUpdate',
        item: {
          'id': updatedMessageData.id,
          'data': updatedMessageData.data.toList(),
          'operation': 'updated',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      await workDb.createOrUpdate(updatedItem);
      result = await workDb.retrieve(itemId);

      expect(result, isNotNull);
      expect(result?.item['operation'], equals('updated'));

      retrievedMessageData = MessageData(
        id: result!.item['id'] as int,
        data: Uint8List.fromList((result.item['data'] as List).cast<int>()),
      );
      expect(eqMessageData(updatedMessageData, retrievedMessageData), isTrue);
    });

    test('should not throw errors with createOrUpdate methods', () async {
      final itemId = ItemId(id: 'noError1', collection: 'noErrorTest');
      final item = ItemWithId(
        id: 'noError1',
        collection: 'noErrorTest',
        item: {'test': 'value'},
      );

      // These should not throw any errors
      await workDb.createOrUpdate(item);
      await workDb.createOrUpdate(item); // Duplicate should not throw

      final multiItems = [
        ItemWithId(id: 'noError2', collection: 'noErrorTest', item: {'test': 'value1'}),
        ItemWithId(id: 'noError3', collection: 'noErrorTest', item: {'test': 'value2'}),
      ];

      await workDb.createOrUpdateMultiple(multiItems);
      await workDb.createOrUpdateMultiple(multiItems); // Duplicates should not throw

      // Verify all items exist
      final results = await workDb.retrieveMultiple([
        itemId,
        ItemId(id: 'noError2', collection: 'noErrorTest'),
        ItemId(id: 'noError3', collection: 'noErrorTest'),
      ]);

      for (final result in results) {
        expect(result, isNotNull);
      }
    });

    test('should handle empty collection gracefully', () async {
      final items = await workDb.getItemsInCollection('nonExistentCollection');
      expect(items, isEmpty);
    });

    test('should handle nested JSON objects', () async {
      final item = ItemWithId(
        id: 'nested1',
        collection: 'nestedTest',
        item: {
          'level1': {
            'level2': {
              'level3': {
                'value': 'deep',
                'array': [1, 2, 3],
              },
            },
          },
          'tags': ['tag1', 'tag2', 'tag3'],
          'metadata': {
            'created': DateTime.now().toIso8601String(),
            'count': 42,
            'active': true,
          },
        },
      );

      await workDb.create(item);
      final result = await workDb.retrieve(
        ItemId(id: 'nested1', collection: 'nestedTest'),
      );

      expect(result, isNotNull);

      final level1 = result?.item['level1'] as Map<String, dynamic>;
      final level2 = level1['level2'] as Map<String, dynamic>;
      final level3 = level2['level3'] as Map<String, dynamic>;

      expect(level3['value'], equals('deep'));
      expect(level3['array'], equals([1, 2, 3]));
      expect(result?.item['tags'], equals(['tag1', 'tag2', 'tag3']));
      expect((result?.item['metadata'] as Map)['count'], equals(42));
      expect((result?.item['metadata'] as Map)['active'], isTrue);
    });

    test('should handle special characters in item data', () async {
      final item = ItemWithId(
        id: 'special1',
        collection: 'specialChars',
        item: {
          'unicode': '日本語 中文 한국어 العربية',
          'emoji': '🎉🚀💻🔥',
          'escapes': 'Line1\nLine2\tTabbed',
          'quotes': '"double" and \'single\'',
          'backslash': 'path\\to\\file',
        },
      );

      await workDb.create(item);
      final result = await workDb.retrieve(
        ItemId(id: 'special1', collection: 'specialChars'),
      );

      expect(result, isNotNull);
      expect(result?.item['unicode'], equals('日本語 中文 한국어 العربية'));
      expect(result?.item['emoji'], equals('🎉🚀💻🔥'));
      expect(result?.item['escapes'], equals('Line1\nLine2\tTabbed'));
      expect(result?.item['quotes'], equals('"double" and \'single\''));
      expect(result?.item['backslash'], equals('path\\to\\file'));
    });

    test('should handle null values in item data', () async {
      final item = ItemWithId(
        id: 'nullTest1',
        collection: 'nullValues',
        item: {
          'nullField': null,
          'validField': 'value',
          'nested': {
            'nullNested': null,
            'validNested': 123,
          },
        },
      );

      await workDb.create(item);
      final result = await workDb.retrieve(
        ItemId(id: 'nullTest1', collection: 'nullValues'),
      );

      expect(result, isNotNull);
      expect(result?.item['nullField'], isNull);
      expect(result?.item['validField'], equals('value'));
      expect((result?.item['nested'] as Map)['nullNested'], isNull);
      expect((result?.item['nested'] as Map)['validNested'], equals(123));
    });

    test('should handle numeric types correctly', () async {
      final item = ItemWithId(
        id: 'numericTest1',
        collection: 'numericTypes',
        item: {
          'integer': 42,
          'negative': -100,
          'double': 3.14159,
          'zero': 0,
          'large': 9007199254740991, // Max safe integer in JS
        },
      );

      await workDb.create(item);
      final result = await workDb.retrieve(
        ItemId(id: 'numericTest1', collection: 'numericTypes'),
      );

      expect(result, isNotNull);
      expect(result?.item['integer'], equals(42));
      expect(result?.item['negative'], equals(-100));
      expect(result?.item['double'], closeTo(3.14159, 0.00001));
      expect(result?.item['zero'], equals(0));
      expect(result?.item['large'], equals(9007199254740991));
    });

    test('should handle boolean values correctly', () async {
      final item = ItemWithId(
        id: 'boolTest1',
        collection: 'booleanTypes',
        item: {
          'trueValue': true,
          'falseValue': false,
          'nested': {
            'active': true,
            'deleted': false,
          },
        },
      );

      await workDb.create(item);
      final result = await workDb.retrieve(
        ItemId(id: 'boolTest1', collection: 'booleanTypes'),
      );

      expect(result, isNotNull);
      expect(result?.item['trueValue'], isTrue);
      expect(result?.item['falseValue'], isFalse);
      expect((result?.item['nested'] as Map)['active'], isTrue);
      expect((result?.item['nested'] as Map)['deleted'], isFalse);
    });

    test('should handle empty arrays and objects', () async {
      final item = ItemWithId(
        id: 'emptyTest1',
        collection: 'emptyStructures',
        item: {
          'emptyArray': <dynamic>[],
          'emptyObject': <String, dynamic>{},
          'nested': {
            'emptyNestedArray': <dynamic>[],
            'emptyNestedObject': <String, dynamic>{},
          },
        },
      );

      await workDb.create(item);
      final result = await workDb.retrieve(
        ItemId(id: 'emptyTest1', collection: 'emptyStructures'),
      );

      expect(result, isNotNull);
      expect(result?.item['emptyArray'], isEmpty);
      expect(result?.item['emptyObject'], isEmpty);
      expect((result?.item['nested'] as Map)['emptyNestedArray'], isEmpty);
      expect((result?.item['nested'] as Map)['emptyNestedObject'], isEmpty);
    });
  });
}

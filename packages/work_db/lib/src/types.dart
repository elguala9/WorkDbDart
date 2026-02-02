/// Type definitions for WorkDB.
///
/// These types are used throughout the WorkDB system to ensure
/// type safety and consistent data structures.
library;

/// A JSON-compatible value type.
///
/// Represents any value that can be serialized to JSON:
/// - String
/// - int/double (num)
/// - bool
/// - null
/// - Map<String, Object?> (JsonObject)
/// - List<Object?> (containing JsonValue elements)
///
/// Using `Object?` instead of `dynamic` provides better type safety:
/// - Compile-time checks prevent calling non-existent methods
/// - Forces explicit type checking/casting before use
/// - IDE provides better autocomplete and error detection
typedef JsonValue = Object?;

/// A JSON object represented as a Map with String keys.
///
/// Values can be any JSON-compatible type (String, num, bool, null,
/// List, or nested Map).
typedef JsonObject = Map<String, JsonValue>;

/// Identifies a unique item within a collection.
///
/// Every item in WorkDB is uniquely identified by the combination
/// of its [collection] name and its [id] within that collection.
class ItemId {
  /// Creates a new [ItemId] with the given [id] and [collection].
  ///
  /// Throws [ArgumentError] if [id] or [collection] is empty.
  ItemId({
    required this.id,
    required this.collection,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'ID cannot be empty');
    }
    if (collection.isEmpty) {
      throw ArgumentError.value(
        collection,
        'collection',
        'Collection cannot be empty',
      );
    }
  }

  /// The unique identifier of the item within its collection.
  final String id;

  /// The name of the collection containing this item.
  final String collection;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemId &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          collection == other.collection;

  @override
  int get hashCode => Object.hash(id, collection);

  @override
  String toString() => 'ItemId(id: $id, collection: $collection)';

  /// Creates a copy of this [ItemId] with optionally modified fields.
  ItemId copyWith({
    String? id,
    String? collection,
  }) {
    return ItemId(
      id: id ?? this.id,
      collection: collection ?? this.collection,
    );
  }
}

/// Represents an item to be stored in the database.
///
/// Contains the actual data payload as a [JsonObject].
class Item {
  /// Creates a new [Item] with the given data [item].
  const Item({required this.item});

  /// The item's data payload.
  final JsonObject item;

  static bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          runtimeType == other.runtimeType &&
          _mapsEqual(item, other.item);

  @override
  int get hashCode =>
      Object.hashAll(item.entries.map((e) => Object.hash(e.key, e.value)));

  @override
  String toString() => 'Item(item: $item)';

  /// Creates a copy of this [Item] with optionally modified fields.
  Item copyWith({JsonObject? item}) {
    return Item(item: item ?? Map.from(this.item));
  }
}

/// Represents an item retrieved from the database with metadata.
///
/// Extends [Item] with optional creation timestamp information.
class ItemOutput extends Item {
  /// Creates a new [ItemOutput] with the given [item] data
  /// and optional [createdAt] timestamp.
  const ItemOutput({
    required super.item,
    this.createdAt,
  });

  /// The ISO 8601 timestamp when this item was created.
  ///
  /// May be null if the underlying storage doesn't support timestamps.
  final String? createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ItemOutput &&
          runtimeType == other.runtimeType &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(super.hashCode, createdAt);

  @override
  String toString() => 'ItemOutput(item: $item, createdAt: $createdAt)';

  /// Creates a copy of this [ItemOutput] with optionally modified fields.
  @override
  ItemOutput copyWith({JsonObject? item, String? createdAt}) {
    return ItemOutput(
      item: item ?? Map.from(this.item),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// A combination of [ItemId] and [Item] for create/update operations.
///
/// This is a convenience class that bundles identification and data
/// together for operations that need both.
class ItemWithId {
  /// Creates a new [ItemWithId] with the given [id], [collection],
  /// and [item] data.
  ///
  /// Throws [ArgumentError] if [id] or [collection] is empty.
  ItemWithId({
    required this.id,
    required this.collection,
    required this.item,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'ID cannot be empty');
    }
    if (collection.isEmpty) {
      throw ArgumentError.value(
        collection,
        'collection',
        'Collection cannot be empty',
      );
    }
  }

  /// The unique identifier of the item.
  final String id;

  /// The collection containing this item.
  final String collection;

  /// The item's data payload.
  final JsonObject item;

  /// Converts this to an [ItemId].
  ItemId toItemId() => ItemId(id: id, collection: collection);

  /// Converts this to an [Item].
  Item toItem() => Item(item: item);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemWithId &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          collection == other.collection &&
          Item._mapsEqual(item, other.item);

  @override
  int get hashCode => Object.hash(
        id,
        collection,
        Object.hashAll(item.entries.map((e) => Object.hash(e.key, e.value))),
      );

  @override
  String toString() =>
      'ItemWithId(id: $id, collection: $collection, item: $item)';

  /// Creates a copy of this [ItemWithId] with optionally modified fields.
  ItemWithId copyWith({
    String? id,
    String? collection,
    JsonObject? item,
  }) {
    return ItemWithId(
      id: id ?? this.id,
      collection: collection ?? this.collection,
      item: item ?? Map.from(this.item),
    );
  }
}

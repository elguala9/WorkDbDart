import 'dart:typed_data';

/// Represents a message with an ID.
class MessageWithId {
  final int id;

  const MessageWithId({required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageWithId && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents message data with binary payload.
class MessageData extends MessageWithId {
  final Uint8List data;

  const MessageData({
    required super.id,
    required this.data,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is MessageData &&
          runtimeType == other.runtimeType &&
          _uint8ListEquals(data, other.data);

  static bool _uint8ListEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, Object.hashAll(data));

  @override
  String toString() => 'MessageData(id: $id, data: $data)';
}

/// Sample message data for testing.
final List<MessageData> exampleMessageData = List.generate(
  10,
  (i) => MessageData(
    id: 61 + i,
    data: Uint8List.fromList([61 + i, 62 + i, 63 + i]),
  ),
);

/// Compares two ID types for equality.
bool eqIdType(int a, int b) => a == b;

/// Compares two [MessageWithId] instances for equality.
bool eqMessageWithId(MessageWithId a, MessageWithId b) => eqIdType(a.id, b.id);

/// Compares two [MessageData] instances for deep equality.
///
/// Returns `true` if both messages have the same ID and data.
/// Logs detailed differences if they don't match.
bool eqMessageData(MessageData a, MessageData b) {
  if (!eqMessageWithId(a, b)) {
    return _notEqual(a, b);
  }

  if (a.data.length != b.data.length) {
    return _notEqual(a, b);
  }

  for (var i = 0; i < a.data.length; i++) {
    if (a.data[i] != b.data[i]) {
      return _notEqual(a, b);
    }
  }

  return true;
}

/// Helper to log differences between two objects.
bool _notEqual(dynamic a, dynamic b) {
  print('First Object: ---------');
  print(a);
  print('Second Object: ---------');
  print(b);
  return false;
}

/// Converts a [MessageData] to a JSON-compatible map.
///
/// The binary data is converted to a regular List<int>.
Map<String, dynamic> messageDataToJson(MessageData msg) {
  return {
    'id': msg.id,
    'data': msg.data.toList(),
  };
}

/// Reconstructs a [MessageData] from a JSON-compatible map.
MessageData messageDataFromJson(Map<String, dynamic> json) {
  return MessageData(
    id: json['id'] as int,
    data: Uint8List.fromList((json['data'] as List).cast<int>()),
  );
}

// lib/src/serialization/binary_codec.dart
import 'dart:typed_data';
import 'dart:convert';

class BinaryCodec {
  // Type identifiers
  static const int _typeNull = 0;
  static const int _typeMap = 1;
  static const int _typeList = 2;
  static const int _typeString = 3;
  static const int _typeInt = 4;
  static const int _typeDouble = 5;
  static const int _typeBool = 6;

  Uint8List encode(dynamic value) {
    final builder = BytesBuilder();
    _encodeValue(builder, value);
    return builder.toBytes();
  }

  dynamic decode(Uint8List bytes) {
    if (bytes.isEmpty) return null;

    final reader =
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    var offset = 0;
    return _decodeValue(reader, offset);
  }

  void _encodeValue(BytesBuilder builder, dynamic value) {
    if (value == null) {
      builder.addByte(_typeNull);
    } else if (value is Map) {
      _encodeMap(builder, value.cast<String, dynamic>());
    } else if (value is List) {
      _encodeList(builder, value);
    } else if (value is String) {
      _encodeString(builder, value);
    } else if (value is int) {
      _encodeInt(builder, value);
    } else if (value is double) {
      _encodeDouble(builder, value);
    } else if (value is bool) {
      _encodeBool(builder, value);
    } else {
      throw ArgumentError('Unsupported type: ${value.runtimeType}');
    }
  }

  dynamic _decodeValue(ByteData reader, int offset) {
    final type = reader.getUint8(offset++);

    switch (type) {
      case _typeNull:
        return null;
      case _typeMap:
        return _decodeMap(reader, offset);
      case _typeList:
        return _decodeList(reader, offset);
      case _typeString:
        return _decodeString(reader, offset);
      case _typeInt:
        return _decodeInt(reader, offset);
      case _typeDouble:
        return _decodeDouble(reader, offset);
      case _typeBool:
        return _decodeBool(reader, offset);
      default:
        throw FormatException('Unknown type ID: $type');
    }
  }

  void _encodeMap(BytesBuilder builder, Map<String, dynamic> map) {
    builder.addByte(_typeMap);
    _encodeInt(builder, map.length);

    map.forEach((key, value) {
      _encodeString(builder, key);
      _encodeValue(builder, value);
    });
  }

  Map<String, dynamic> _decodeMap(ByteData reader, int offset) {
    final length = _decodeInt(reader, offset);
    offset += 4;

    final map = <String, dynamic>{};
    for (var i = 0; i < length; i++) {
      final key = _decodeString(reader, offset);
      offset += 4 + utf8.encode(key).length;
      final value = _decodeValue(reader, offset);
      offset += _getValueSize(reader, offset);
      map[key] = value;
    }
    return map;
  }

  void _encodeList(BytesBuilder builder, List<dynamic> list) {
    builder.addByte(_typeList);
    _encodeInt(builder, list.length);

    for (final value in list) {
      _encodeValue(builder, value);
    }
  }

  List<dynamic> _decodeList(ByteData reader, int offset) {
    final length = _decodeInt(reader, offset);
    offset += 4;

    final list = <dynamic>[];
    for (var i = 0; i < length; i++) {
      final value = _decodeValue(reader, offset);
      offset += _getValueSize(reader, offset);
      list.add(value);
    }
    return list;
  }

  void _encodeString(BytesBuilder builder, String value) {
    builder.addByte(_typeString);
    final bytes = utf8.encode(value);
    _encodeInt(builder, bytes.length);
    builder.add(bytes);
  }

  String _decodeString(ByteData reader, int offset) {
    final length = _decodeInt(reader, offset);
    offset += 4;

    final bytes = Uint8List.view(
      reader.buffer,
      reader.offsetInBytes + offset,
      length,
    );
    return utf8.decode(bytes);
  }

  void _encodeInt(BytesBuilder builder, int value) {
    builder.addByte(_typeInt);
    builder.addByte(value >> 24);
    builder.addByte(value >> 16);
    builder.addByte(value >> 8);
    builder.addByte(value);
  }

  int _decodeInt(ByteData reader, int offset) {
    return reader.getInt32(offset, Endian.big);
  }

  void _encodeDouble(BytesBuilder builder, double value) {
    builder.addByte(_typeDouble);
    final bytes = ByteData(8)..setFloat64(0, value, Endian.big);
    builder.add(bytes.buffer.asUint8List());
  }

  double _decodeDouble(ByteData reader, int offset) {
    return reader.getFloat64(offset, Endian.big);
  }

  void _encodeBool(BytesBuilder builder, bool value) {
    builder.addByte(_typeBool);
    builder.addByte(value ? 1 : 0);
  }

  bool _decodeBool(ByteData reader, int offset) {
    return reader.getUint8(offset) == 1;
  }

  int _getValueSize(ByteData reader, int offset) {
    final type = reader.getUint8(offset);

    switch (type) {
      case _typeNull:
        return 1;
      case _typeMap:
        return _getMapSize(reader, offset + 1);
      case _typeList:
        return _getListSize(reader, offset + 1);
      case _typeString:
        return 5 + _decodeInt(reader, offset + 1);
      case _typeInt:
        return 5;
      case _typeDouble:
        return 9;
      case _typeBool:
        return 2;
      default:
        throw FormatException('Unknown type ID: $type');
    }
  }

  int _getMapSize(ByteData reader, int offset) {
    var size = 1; // type byte
    final length = _decodeInt(reader, offset);
    size += 4; // length

    offset += 4;
    for (var i = 0; i < length; i++) {
      // Key size
      final keyLength = _decodeInt(reader, offset);
      size += 4 + keyLength;
      offset += 4 + keyLength;

      // Value size
      final valueSize = _getValueSize(reader, offset);
      size += valueSize;
      offset += valueSize;
    }
    return size;
  }

  int _getListSize(ByteData reader, int offset) {
    var size = 1; // type byte
    final length = _decodeInt(reader, offset);
    size += 4; // length

    offset += 4;
    for (var i = 0; i < length; i++) {
      final itemSize = _getValueSize(reader, offset);
      size += itemSize;
      offset += itemSize;
    }
    return size;
  }
}

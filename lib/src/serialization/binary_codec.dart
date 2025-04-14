// lib/src/serialization/binary_codec.dart
import 'dart:typed_data';
import 'dart:convert';

import 'package:quantum_cache_db/src/serialization/reader_state.dart';

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
    final reader = ReaderState(
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length));
    return _decodeValue(reader);
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

  dynamic _decodeValue(ReaderState reader) {
    reader.checkRemaining(1);
    final type = reader.data.getUint8(reader.offset++);

    switch (type) {
      case _typeNull:
        return null;
      case _typeMap:
        return _decodeMap(reader);
      case _typeList:
        return _decodeList(reader);
      case _typeString:
        return _decodeString(reader);
      case _typeInt:
        return _decodeInt(reader);
      case _typeDouble:
        return _decodeDouble(reader);
      case _typeBool:
        return _decodeBool(reader);
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

  Map<String, dynamic> _decodeMap(ReaderState reader) {
    final length = _decodeInt(reader);
    final map = <String, dynamic>{};

    for (var i = 0; i < length; i++) {
      // KEY FIX: Use _decodeValue for keys to handle type byte
      final key = _decodeValue(reader) as String;
      final value = _decodeValue(reader);
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

  List<dynamic> _decodeList(ReaderState reader) {
    final length = _decodeInt(reader);
    final list = List<dynamic>.filled(length, null);

    for (var i = 0; i < length; i++) {
      list[i] = _decodeValue(reader);
    }
    return list;
  }

  String _decodeString(ReaderState reader) {
    final length = _decodeInt(reader);
    reader.checkRemaining(length);

    final bytes = Uint8List.view(
        reader.data.buffer, reader.data.offsetInBytes + reader.offset, length);
    reader.offset += length;
    return utf8.decode(bytes);
  }

  void _encodeString(BytesBuilder builder, String value) {
    builder.addByte(_typeString);
    final bytes = utf8.encode(value);
    _encodeInt(builder, bytes.length);
    builder.add(bytes);
  }

  void _encodeInt(BytesBuilder builder, int value) {
    if (value < 0) throw ArgumentError('Negative values not supported');

    if (value <= 0xFF) {
      builder.addByte(value);
    } else {
      builder.addByte(0xFF);
      builder.addByte((value >> 24) & 0xFF);
      builder.addByte((value >> 16) & 0xFF);
      builder.addByte((value >> 8) & 0xFF);
      builder.addByte(value & 0xFF);
    }
  }

  int _decodeInt(ReaderState reader) {
    reader.checkRemaining(1);
    final firstByte = reader.data.getUint8(reader.offset++);

    if (firstByte != 0xFF) return firstByte;

    reader.checkRemaining(4);
    final value = reader.data.getUint32(reader.offset, Endian.big);
    reader.offset += 4;
    return value;
  }

  void _encodeDouble(BytesBuilder builder, double value) {
    builder.addByte(_typeDouble);
    final bytes = ByteData(8)..setFloat64(0, value, Endian.big);
    builder.add(bytes.buffer.asUint8List());
  }

  double _decodeDouble(ReaderState reader) {
    reader.checkRemaining(8);
    final value = reader.data.getFloat64(reader.offset, Endian.big);
    reader.offset += 8;
    return value;
  }

  void _encodeBool(BytesBuilder builder, bool value) {
    builder.addByte(_typeBool);
    builder.addByte(value ? 1 : 0);
  }

  bool _decodeBool(ReaderState reader) {
    reader.checkRemaining(1);
    return reader.data.getUint8(reader.offset++) == 1;
  }
}

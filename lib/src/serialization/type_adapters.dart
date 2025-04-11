// # Type-specific optimizations

import 'dart:typed_data';

abstract class TypeAdapter<T> {
  int get typeId;
  Uint8List encode(T value);
  T decode(Uint8List bytes);
}

class IntAdapter implements TypeAdapter<int> {
  @override
  final typeId = 1;

  @override
  Uint8List encode(int value) {
    return Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.little);
  }

  @override
  int decode(Uint8List bytes) {
    return bytes.buffer.asByteData().getInt32(0, Endian.little);
  }
}

class StringAdapter implements TypeAdapter<String> {
  @override
  final typeId = 2;

  @override
  Uint8List encode(String value) {
    return Uint8List.fromList(value.codeUnits);
  }

  @override
  String decode(Uint8List bytes) {
    return String.fromCharCodes(bytes);
  }
}

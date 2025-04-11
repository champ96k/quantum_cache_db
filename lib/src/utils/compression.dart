// # Compression utilities
import 'dart:typed_data';

class FastCompression {
  static Uint8List compress(Uint8List data) {
    if (_isHighlyCompressible(data)) {
      return _runLengthEncode(data);
    }
    return data; // Fallback to uncompressed
  }

  static bool _isHighlyCompressible(Uint8List data) {
    if (data.length < 32) return false;
    final sample = data.sublist(0, 32);
    return sample.toSet().length < 5;
  }

  static Uint8List _runLengthEncode(Uint8List data) {
    final output = BytesBuilder();
    int count = 1;
    int current = data[0];

    for (int i = 1; i < data.length; i++) {
      if (data[i] == current && count < 127) {
        count++;
      } else {
        output.addByte(current | (count << 1));
        current = data[i];
        count = 1;
      }
    }
    output.addByte(current | (count << 1));

    return output.toBytes();
  }

  static Uint8List decompress(Uint8List compressed) {
    if (compressed.isEmpty) return compressed;
    if (compressed[0] & 0x01 == 0) {
      return compressed; // Wasn't compressed
    }

    final output = BytesBuilder();
    for (final byte in compressed) {
      final value = byte & 0x01;
      final count = byte >> 1;
      output.add(List.filled(count, value));
    }
    return output.toBytes();
  }
}

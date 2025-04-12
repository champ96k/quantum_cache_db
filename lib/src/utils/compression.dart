// # Compression utilities
import 'dart:math';
import 'dart:typed_data';

class FastCompression {
  static Uint8List compress(Uint8List data) {
    if (!_isHighlyCompressible(data)) return data;
    return _runLengthEncode(data);
  }

  static bool _isHighlyCompressible(Uint8List data) {
    // Improved heuristic based on entropy check
    if (data.length < 64) return false;
    final frequencies = Map<int, int>.fromIterable(data, value: (_) => 0);
    for (final byte in data) {
      frequencies[byte] = frequencies[byte]! + 1;
    }
    final entropy = frequencies.values
        .map((v) => -v / data.length * log(v / data.length))
        .reduce((a, b) => a + b);
    // Lower entropy means more compressible
    return entropy < 2.0;
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
    // Check if first byte has compression flag
    if (compressed.isEmpty || (compressed[0] & 0x80) == 0) {
      return compressed;
    }

    final output = BytesBuilder();
    for (final byte in compressed) {
      // 1-128 repetitions
      final count = (byte & 0x7F) + 1;
      // Only 0 and 1 supported
      final value = byte & 0x80 != 0 ? 1 : 0;
      output.add(List.filled(count, value));
    }
    return output.toBytes();
  }
}

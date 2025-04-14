import 'dart:typed_data';

class ReaderState {
  final ByteData data;
  int offset = 0;

  ReaderState(this.data);

  void checkRemaining(int bytesNeeded) {
    if (bytesNeeded < 0) throw ArgumentError('Negative bytes requested');
    if (offset + bytesNeeded > data.lengthInBytes) {
      throw RangeError('Buffer underflow: '
          'Offset=$offset, Requested=$bytesNeeded, '
          'Available=${data.lengthInBytes - offset}');
    }
  }
}

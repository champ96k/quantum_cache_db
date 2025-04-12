import 'dart:typed_data';

class ReaderState {
  final ByteData data;
  int offset = 0;
  ReaderState(this.data);
}

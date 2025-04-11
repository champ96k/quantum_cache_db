// lib/src/core/record_pointer.dart
class RecordPointer {
  final int position; // Byte offset in the file
  final int length; // Length of the record in bytes
  final bool compressed; // Whether the data is compressed

  const RecordPointer(this.position, this.length, [this.compressed = false]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordPointer &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          length == other.length &&
          compressed == other.compressed;

  @override
  int get hashCode => position.hashCode ^ length.hashCode ^ compressed.hashCode;

  @override
  String toString() =>
      'RecordPointer(pos: $position, len: $length, compressed: $compressed)';
}

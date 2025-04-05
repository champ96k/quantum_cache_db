class WriteAheadLogException implements Exception {
  final String message;
  WriteAheadLogException(this.message);

  @override
  String toString() => 'WriteAheadLogException: $message';
}

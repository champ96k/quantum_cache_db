class DatabaseQueryException implements Exception {
  final String message;
  DatabaseQueryException(this.message);

  @override
  String toString() => 'DatabaseQueryException: $message';
}

/// Database-specific exceptions
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}

class DatabaseInitializationException extends DatabaseException {
  DatabaseInitializationException(super.message);
}

class DatabaseWriteException extends DatabaseException {
  DatabaseWriteException(super.message);
}

class DatabaseClosedException extends DatabaseException {
  DatabaseClosedException() : super('Database is closed');
}

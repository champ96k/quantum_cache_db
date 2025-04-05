/// Unique exception class for document operations
class QuantumDocumentException implements Exception {
  final String message;
  QuantumDocumentException(this.message);

  @override
  String toString() => 'QuantumDocumentException: $message';
}

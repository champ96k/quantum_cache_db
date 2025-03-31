import 'package:quantum_cache_db/quantum_cache_db.dart';

/// Represents a document inside a collection
class Document {
  final QuantumCacheDB _db;
  final String collection;
  final String docId;

  Document(this._db, this.collection, this.docId);

  /// Sets a document in the database
  Future<void> set(Map<String, dynamic> data) async {
    await _db.setDocument(collection, docId, data);
  }

  /// Retrieves a document
  Map<String, dynamic>? get() {
    return _db.getDocument(collection, docId);
  }
}

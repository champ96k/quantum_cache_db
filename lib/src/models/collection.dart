import 'package:quantum_cache_db/quantum_cache_db.dart';
import 'package:quantum_cache_db/src/models/document.dart';
import 'package:quantum_cache_db/src/models/query_model.dart';

/// Represents a collection of documents
class Collection {
  final QuantumCacheDB _db;
  final String name;

  Collection(this._db, this.name);

  /// Returns a document reference
  Document doc(String docId) {
    return Document(_db, name, docId);
  }

  /// Queries the collection
  Query where(String field, String operator, dynamic value) {
    return Query(name).where(field, operator, value);
  }
}

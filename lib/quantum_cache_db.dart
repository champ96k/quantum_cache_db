import 'package:quantum_cache_db/src/core/query/query_condition.dart';

import 'src/models/collection/collection.dart';

abstract class QuantumCacheDB {
  Future<void> init();

  // Key-Value operations
  Future<void> set(String key, dynamic value);
  dynamic get(String key);
  Future<void> delete(String key);
  Stream<dynamic> watchKey(String key);

  // Document operations
  Future<void> setDocument(
      String collection, String docId, Map<String, dynamic> data);

  Map<String, dynamic>? getDocument(String collection, String docId);

  Future<void> deleteDocument(String collection, String docId);

  Stream<dynamic> watchCollection(String collection);

  // Query operations
  Future<List<String>> query(
      String collection, List<QueryCondition> conditions);

  // Collection reference
  QuantumCollection collection(String collection);

  Future<void> close();
}

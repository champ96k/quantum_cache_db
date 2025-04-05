import 'dart:collection';
import 'dart:convert';

/// A high-performance in-memory cache with both key-value and document storage
class InMemoryCache {
  // Using HashMap for O(1) average case performance
  final _kvStore = HashMap<String, dynamic>();

  // Nested structure: Collection -> DocumentID -> DocumentData
  final _collections = HashMap<String, HashMap<String, dynamic>>();

  /// Stores a key-value pair with O(1) time complexity
  void setKV(String key, dynamic value) {
    _kvStore[key] = value;
  }

  /// Retrieves a value by key with O(1) time complexity
  dynamic getKV(String key) => _kvStore[key];

  /// Removes a key-value pair with O(1) time complexity
  void removeKV(String key) {
    _kvStore.remove(key);
  }

  /// Checks if a key exists with O(1) time complexity
  bool containsKey(String key) => _kvStore.containsKey(key);

  /// Stores a document in the specified collection with O(1) time complexity
  void setDocument(String collection, String docId, Map<String, dynamic> data) {
    _collections.putIfAbsent(collection, () => HashMap());
    _collections[collection]![docId] = Map<String, dynamic>.from(data);
  }

  /// Retrieves a document with O(1) time complexity
  Map<String, dynamic>? getDocument(String collection, String docId) {
    final collectionDocs = _collections[collection];
    if (collectionDocs == null) return null;
    return collectionDocs[docId]?['data'] != null
        ? Map<String, dynamic>.from(collectionDocs[docId]!)
        : null;
  }

  /// Removes a document with O(1) time complexity
  void removeDocument(String collection, String docId) {
    _collections[collection]?.remove(docId);
  }

  /// Checks if a document exists with O(1) time complexity
  bool containsDocument(String collection, String docId) {
    return _collections[collection]?.containsKey(docId) ?? false;
  }

  /// Returns all documents in a collection with O(n) time complexity
  List<Map<String, dynamic>> getAllDocuments(String collection) {
    final docs = _collections[collection]?.values.toList() ?? [];
    return docs.map((doc) => Map<String, dynamic>.from(doc)).toList();
  }

  /// Clears all cached data with O(1) time complexity
  void clear() {
    _kvStore.clear();
    _collections.clear();
  }

  /// Returns the number of stored keys with O(1) time complexity
  int get keyCount => _kvStore.length;

  /// Returns the number of collections with O(1) time complexity
  int get collectionCount => _collections.length;

  /// Returns the total document count across all collections with O(n) time complexity
  int get totalDocumentCount {
    return _collections.values
        .fold(0, (sum, collection) => sum + collection.length);
  }

  /// Returns a serializable representation of the key-value store
  Map<String, dynamic> get kvCache => Map<String, dynamic>.from(_kvStore);

  /// Returns a serializable representation of all collections
  Map<String, dynamic> get collectionCache {
    return Map.fromEntries(
      _collections.entries.map((e) => MapEntry(
            e.key,
            Map<String, dynamic>.from(e.value),
          )),
    );
  }

  /// Returns memory usage statistics
  Map<String, int> get memoryStats {
    final encoder = JsonUtf8Encoder();
    return {
      'kv_store_size': encoder.convert(_kvStore).length,
      'collections_size': encoder.convert(_collections).length,
      'total_size': encoder.convert(_kvStore).length +
          encoder.convert(_collections).length,
    };
  }
}

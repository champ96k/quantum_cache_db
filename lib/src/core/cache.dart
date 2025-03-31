// # In-Memory Cache

import 'dart:collection';

class InMemoryCache {
  final kvCache = HashMap<String, dynamic>();
  final collectionCache = HashMap<String, Map<String, dynamic>>();

  // Key-Value Cache
  void setKV(String key, dynamic value) {
    kvCache[key] = value;
  }

  dynamic getKV(String key) {
    return kvCache[key];
  }

  void removeKV(String key) {
    kvCache.remove(key);
  }

  // Document Cache
  void setDocument(String collection, String docId, Map<String, dynamic> data) {
    collectionCache.putIfAbsent(collection, () => {});
    collectionCache[collection]![docId] = data;
  }

  Map<String, dynamic>? getDocument(String collection, String docId) {
    return collectionCache[collection]?[docId];
  }

  void removeDocument(String collection, String docId) {
    collectionCache[collection]?.remove(docId);
  }

  void clear() {
    kvCache.clear();
    collectionCache.clear();
  }
}

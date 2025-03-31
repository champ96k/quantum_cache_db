import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:quantum_cache_db/src/core/cache.dart';
import 'package:quantum_cache_db/src/core/quantum_db.dart';
import 'package:quantum_cache_db/src/core/wal.dart';
import 'package:quantum_cache_db/src/core/encryption.dart';
import 'package:quantum_cache_db/src/models/collection.dart';

class QuantumCacheDB {
  final String dbPath;
  final InMemoryCache _cache = InMemoryCache();
  late WriteAheadLog _wal;
  late Encryption _encryption;
  final StreamController<String> _streamController =
      StreamController.broadcast();

  final QuantumQueryEngine _queryEngine = QuantumQueryEngine();

  QuantumCacheDB(this.dbPath, String encryptionKey) {
    try {
      _wal = WriteAheadLog('$dbPath.wal');
      _encryption = Encryption(encryptionKey);
    } catch (e) {
      print('Error initializing QuantumCacheDB: $e');
      rethrow;
    }
  }

  Future<void> init() async {
    try {
      final file = File(dbPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final decryptedData = _encryption.decrypt(content);
        final data = jsonDecode(decryptedData);

        for (var entry in data['keyValueStore'].entries) {
          _cache.setKV(entry.key, entry.value);
        }
        for (var collection in data['collections'].entries) {
          for (var doc in collection.value.entries) {
            _cache.setDocument(collection.key, doc.key, doc.value);
          }
        }
      }
    } catch (e) {
      print('Error during initialization: $e');
      rethrow;
    }
  }

  Future<void> set(String key, dynamic value) async {
    try {
      final encryptedValue = _encryption.encrypt(jsonEncode(value));
      await _wal.logWrite('set', key, encryptedValue);
      _cache.setKV(key, encryptedValue);
      _streamController.add("key:$key");
      await _persist();
    } catch (e) {
      print('Error setting key $key: $e');
      rethrow;
    }
  }

  dynamic get(String key) {
    try {
      final encryptedValue = _cache.getKV(key);
      if (encryptedValue != null) {
        return jsonDecode(_encryption.decrypt(encryptedValue));
      }
      return null;
    } catch (e) {
      print('Error getting key $key: $e');
      rethrow;
    }
  }

  Future<void> delete(String key) async {
    try {
      _wal.logWrite('delete', key, null);
      _cache.removeKV(key);
      _streamController.add("key:$key");
      await _persist();
    } catch (e) {
      print('Error deleting key $key: $e');
      rethrow;
    }
  }

  Stream<dynamic> watchKey(String key) {
    return _streamController.stream.where((event) => event == "key:$key");
  }

  Future<void> setDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    final encryptedData = _encryption.encrypt(jsonEncode(data));
    _wal.logWrite('setDocument', "$collection/$docId", encryptedData);
    _cache.setDocument(collection, docId, {"data": encryptedData});
    _queryEngine.indexField(
        collection, "indexedField", data['indexedField'], docId);
    _streamController.add("collection:$collection");
    await _persist();
  }

  /// Fast query using Indexing & Multi-threading
  Future<List<String>> query(dynamic key) async {
    return await _queryEngine.runQuery(key);
  }

  Map<String, dynamic>? getDocument(String collection, String docId) {
    final storedData = _cache.getDocument(collection, docId);
    if (storedData != null && storedData.containsKey("data")) {
      return jsonDecode(_encryption.decrypt(storedData["data"]));
    }
    return null;
  }

  Future<void> deleteDocument(String collection, String docId) async {
    _wal.logWrite('deleteDocument', "$collection/$docId", null);
    _cache.removeDocument(collection, docId);
    _streamController.add("collection:$collection");
    await _persist();
  }

  Stream<dynamic> watchCollection(String collection) {
    return _streamController.stream
        .where((event) => event == "collection:$collection");
  }

  Future<void> _persist() async {
    final file = File(dbPath);
    final data = {
      "keyValueStore": _cache.kvCache,
      "collections": _cache.collectionCache,
    };
    final encryptedData = _encryption.encrypt(jsonEncode(data));
    await file.writeAsString(encryptedData);
  }

  /// Returns a collection reference for easy querying
  Collection collection(String collection) {
    return Collection(this, collection);
  }
}

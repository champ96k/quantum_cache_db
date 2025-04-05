import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:quantum_cache_db/quantum_cache_db.dart';
import 'package:quantum_cache_db/src/core/cache/in_memory_cache.dart';
import 'package:quantum_cache_db/src/core/encryption/encryption.dart';
import 'package:quantum_cache_db/src/core/query/query_condition.dart';
import 'package:quantum_cache_db/src/core/wal/wal.dart';
import 'package:quantum_cache_db/src/core/query/quantum_query_engine.dart';
import 'package:quantum_cache_db/src/error/database_exception.dart';
import 'package:quantum_cache_db/src/error/database_query_exception.dart';
import 'package:quantum_cache_db/src/models/collection/collection.dart';
import 'package:quantum_cache_db/src/models/document/document.dart';

/// The concrete implementation of QuantumCacheDB
class QuantumCacheDBImpl implements QuantumCacheDB {
  final String dbPath;
  final String encryptionKey;
  final InMemoryCache _cache;
  late final WriteAheadLog _wal;
  late final Encryption _encryption;
  final QuantumQueryEngine _queryEngine;
  final StreamController<String> _changeStream;
  bool _isInitialized = false;
  bool _isClosed = false;

  QuantumCacheDBImpl({
    required this.dbPath,
    required this.encryptionKey,
  })  : _cache = InMemoryCache(),
        _queryEngine = QuantumQueryEngine(),
        _changeStream = StreamController.broadcast() {
    _wal = WriteAheadLog('$dbPath.wal');
    _encryption = Encryption(encryptionKey);
  }

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final file = File(dbPath);
      if (await file.exists()) {
        final encryptedData = await file.readAsString();
        final jsonData = _encryption.decrypt(encryptedData);
        final data = jsonDecode(jsonData) as Map<String, dynamic>;

        // Load key-value store
        final kvStore = data['kv'] as Map<String, dynamic>? ?? {};
        kvStore.forEach((key, value) {
          _cache.setKV(key, value);
        });

        // Load collections
        final collections = data['collections'] as Map<String, dynamic>? ?? {};
        collections.forEach((collection, docs) {
          (docs as Map<String, dynamic>).forEach((docId, docData) {
            _cache.setDocument(collection, docId, docData);
          });
        });
      }

      _isInitialized = true;
    } catch (e) {
      throw DatabaseInitializationException('Init failed: ${e.toString()}');
    }
  }

  @override
  Future<void> set(String key, dynamic value) async {
    _checkIfClosed();
    try {
      final encryptedValue = _encryption.encrypt(jsonEncode(value));
      await _wal.logWrite('set', key, encryptedValue);
      _cache.setKV(key, encryptedValue);
      _changeStream.add('key:$key');
      await _persist();
    } catch (e) {
      throw DatabaseWriteException('Failed to set key $key: ${e.toString()}');
    }
  }

  @override
  dynamic get(String key) {
    _checkIfClosed();
    final encryptedValue = _cache.getKV(key);
    return encryptedValue != null
        ? jsonDecode(_encryption.decrypt(encryptedValue))
        : null;
  }

  @override
  Future<void> delete(String key) async {
    _checkIfClosed();
    try {
      await _wal.logWrite('delete', key, null);
      _cache.removeKV(key);
      _changeStream.add('key:$key');
      await _persist();
    } catch (e) {
      throw DatabaseWriteException(
          'Failed to delete key $key: ${e.toString()}');
    }
  }

  @override
  Stream<dynamic> watchKey(String key) {
    _checkIfClosed();
    return _changeStream.stream
        .where((event) => event == 'key:$key')
        .asyncMap((_) => get(key));
  }

  @override
  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    _checkIfClosed();
    try {
      final encryptedData = _encryption.encrypt(jsonEncode(data));
      await _wal.logWrite('setDoc', '$collection/$docId', encryptedData);
      _cache.setDocument(collection, docId, {'data': encryptedData});

      // Index the document
      _queryEngine.indexDocument(
          collection,
          QuantumDocument(
            id: docId,
            data: data,
          ));

      _changeStream.add('collection:$collection');
      await _persist();
    } catch (e) {
      throw Exception('Failed to set document: ${e.toString()}');
    }
  }

  @override
  Map<String, dynamic>? getDocument(String collection, String docId) {
    _checkIfClosed();
    final doc = _cache.getDocument(collection, docId);
    if (doc == null) return null;

    try {
      return jsonDecode(_encryption.decrypt(doc['data']));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteDocument(String collection, String docId) async {
    _checkIfClosed();
    try {
      await _wal.logWrite('deleteDoc', '$collection/$docId', null);
      _cache.removeDocument(collection, docId);
      _changeStream.add('collection:$collection');
      await _persist();
    } catch (e) {
      throw DatabaseWriteException(
        'Failed to delete document $docId from $collection: ${e.toString()}',
      );
    }
  }

  @override
  Stream<dynamic> watchCollection(String collection) {
    _checkIfClosed();
    return _changeStream.stream
        .where((event) => event == 'collection:$collection')
        .asyncMap((_) => _getAllDocuments(collection));
  }

  @override
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    await _wal.close();
    await _changeStream.close();
  }

  Future<void> _persist() async {
    final data = {
      'kv': _cache.kvCache,
      'collections': _cache.collectionCache,
    };
    await File(dbPath).writeAsString(_encryption.encrypt(jsonEncode(data)));
  }

  Future<List<Map<String, dynamic>>> _getAllDocuments(String collection) async {
    final docs = _cache.collectionCache[collection] ?? {};
    return docs.entries.map((entry) {
      try {
        return jsonDecode(_encryption.decrypt(entry.value['data']));
      } catch (e) {
        return <String, dynamic>{};
      }
    }).toList();
  }

  void _checkIfClosed() {
    if (_isClosed) throw DatabaseClosedException();
  }

  @override
  QuantumCollection collection(String collection) {
    _checkIfClosed();
    return QuantumCollection(collection,
        name: collection, queryEngine: _queryEngine);
  }

  @override
  Future<List<String>> query(
      String collection, List<QueryCondition> conditions) async {
    _checkIfClosed();
    try {
      final results =
          _queryEngine.findByRange(collection, conditions.toString());

      return results.toList();
    } catch (e) {
      throw DatabaseQueryException('Query failed: ${e.toString()}');
    }
  }
}

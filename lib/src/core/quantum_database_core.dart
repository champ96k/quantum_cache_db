import 'dart:async';
import 'dart:convert';
import 'package:quantum_cache_db/src/core/encryption/encryption.dart';
import 'package:quantum_cache_db/src/core/query/quantum_query_engine.dart';
import 'package:quantum_cache_db/src/models/collection/collection.dart';
import 'package:quantum_cache_db/src/models/document/document.dart';

import 'package:quantum_cache_db/src/utils/storage_service.dart';

class QuantumDatabaseCore {
  final Map<String, QuantumCollection> _collections = {};
  final QuantumQueryEngine _queryEngine = QuantumQueryEngine();
  final Encryption _encryption;
  final StorageService _storage;
  bool _isClosed = false;

  QuantumDatabaseCore({
    required String dbPath,
    required String encryptionKey,
  })  : _encryption = Encryption(encryptionKey),
        _storage = StorageService(dbPath);

  Future<void> initialize() async {
    if (_isClosed) throw StateError('Database is closed');
    await _storage.initialize();
    await _loadExistingData();
  }

  Future<QuantumCollection> createCollection(String name) async {
    _checkIfClosed();
    if (_collections.containsKey(name)) {
      throw ArgumentError('Collection $name already exists');
    }
    final collection = QuantumCollection(
      name,
      name: name,
      queryEngine: _queryEngine,
    );
    _collections[name] = collection;
    return collection;
  }

  QuantumCollection getCollection(String name) {
    _checkIfClosed();
    final collection = _collections[name];
    if (collection == null) {
      throw ArgumentError('Collection $name does not exist');
    }
    return collection;
  }

  Future<void> persist() async {
    _checkIfClosed();
    final data = <String, dynamic>{};
    for (final entry in _collections.entries) {
      data[entry.key] = entry.value.getAll();
    }
    await _storage.saveData(_encryption.encrypt(jsonEncode(data)));
  }

  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    await persist();
    for (final collection in _collections.values) {
      await collection.close();
    }
    await _storage.close();
  }

  Future<void> _loadExistingData() async {
    final encryptedData = await _storage.loadData();
    if (encryptedData == null) return;

    final jsonData = jsonDecode(_encryption.decrypt(encryptedData));
    for (final entry in (jsonData as Map<String, dynamic>).entries) {
      final collection = await createCollection(entry.key);
      final documents = (entry.value as List)
          .map((doc) => QuantumDocument.fromJson(jsonEncode(doc)))
          .toList();
      collection.indexedFields.intersection(documents.toSet());
    }
  }

  void _checkIfClosed() {
    if (_isClosed) throw StateError('Database is closed');
  }
}

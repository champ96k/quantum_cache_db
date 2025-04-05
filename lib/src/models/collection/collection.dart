import 'dart:async';

import 'package:quantum_cache_db/src/core/query/quantum_query_engine.dart';
import 'package:quantum_cache_db/src/models/collection/collection_event.dart';
import 'package:quantum_cache_db/src/models/collection/event_type.dart';
import 'package:quantum_cache_db/src/models/document/document.dart';

class QuantumCollection {
  final String name;
  final QuantumQueryEngine _queryEngine;
  final Map<String, QuantumDocument> _documents = {};
  final StreamController<CollectionEvent> _streamController =
      StreamController.broadcast();
  final Map<String, List<String>> _indexes = {};

  QuantumCollection(
    String collection, {
    required this.name,
    required QuantumQueryEngine queryEngine,
  }) : _queryEngine = queryEngine;

  Future<void> set(QuantumDocument doc) async {
    final isUpdate = _documents.containsKey(doc.id);
    _documents[doc.id] = doc;
    _updateIndexes(doc.id, doc.data);
    _queryEngine.indexDocument(name, doc);
    _streamController.add(CollectionEvent(
      type: isUpdate ? EventType.updated : EventType.added,
      documentId: doc.id,
      collection: name,
      document: doc,
    ));
  }

  QuantumDocument? get(String id) => _documents[id];
  bool contains(String id) => _documents.containsKey(id);

  Future<void> remove(String id) async {
    final doc = _documents.remove(id);
    if (doc != null) {
      _removeFromIndexes(id);
      _queryEngine.removeFromIndex(name, id, doc.data);
      _streamController.add(CollectionEvent(
        type: EventType.removed,
        documentId: id,
        collection: name,
        document: doc,
      ));
    }
  }

  void createIndex(String field) {
    _indexes[field] = [];
    for (final entry in _documents.entries) {
      if (entry.value.data.containsKey(field)) {
        _indexes[field]!.add(entry.key);
      }
    }
    _queryEngine.createIndex(name, field);
  }

  List<QuantumDocument> findByIndex(String field, dynamic value) {
    final docIds = _queryEngine.findByValue(name, field, value);
    return docIds.map((id) => _documents[id]!).toList();
  }

  Future<void> setAll(List<QuantumDocument> docs) async {
    for (final doc in docs) {
      await set(doc);
    }
  }

  List<QuantumDocument> getAll() => _documents.values.toList();
  List<QuantumDocument> where(bool Function(QuantumDocument) test) =>
      _documents.values.where(test).toList();

  Stream<CollectionEvent> get changes => _streamController.stream;
  Stream<QuantumDocument> get documentStream =>
      changes.where((e) => e.document != null).map((e) => e.document!);

  int get count => _documents.length;
  Set<String> get indexedFields => _indexes.keys.toSet();

  Future<void> clear() async {
    _documents.clear();
    _indexes.clear();
    _streamController.add(CollectionEvent(
      type: EventType.cleared,
      collection: name,
    ));
  }

  Future<void> close() async {
    await _streamController.close();
  }

  void _updateIndexes(String id, Map<String, dynamic> data) {
    for (final field in _indexes.keys) {
      if (data.containsKey(field)) {
        if (!_indexes[field]!.contains(id)) {
          _indexes[field]!.add(id);
        }
      } else {
        _indexes[field]!.remove(id);
      }
    }
  }

  void _removeFromIndexes(String id) {
    for (final ids in _indexes.values) {
      ids.remove(id);
    }
  }
}

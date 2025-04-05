import 'dart:collection';

import 'package:quantum_cache_db/src/models/document/document.dart';

class QuantumQueryEngine {
  final Map<String, Map<String, Map<String, Set<String>>>> _indexes = {};
  final Map<String, SplayTreeMap<dynamic, Set<String>>> _rangeIndexes = {};

  void createIndex(String collection, String field) {
    _indexes.putIfAbsent(collection, () => {}).putIfAbsent(field, () => {});
  }

  void createRangeIndex(String collection, String field) {
    _rangeIndexes['$collection.$field'] = SplayTreeMap();
  }

  void indexDocument(String collection, QuantumDocument doc) {
    doc.data.forEach((field, value) {
      if (_indexes[collection]?.containsKey(field) == true) {
        final valueMap = _indexes[collection]![field]!;
        final valueKey = value.toString();
        valueMap.putIfAbsent(valueKey, () => <String>{});
        valueMap[valueKey]!.add(doc.id);
      }

      final rangeKey = '$collection.$field';
      if (_rangeIndexes.containsKey(rangeKey)) {
        _rangeIndexes[rangeKey]!.putIfAbsent(value, () => <String>{});
        _rangeIndexes[rangeKey]![value]!.add(doc.id);
      }
    });
  }

  void removeFromIndex(
      String collection, String docId, Map<String, dynamic> data) {
    data.forEach((field, value) {
      _indexes[collection]?[field]?[value.toString()]?.remove(docId);
      _rangeIndexes['$collection.$field']?[value]?.remove(docId);
    });
  }

  Set<String> findByValue(String collection, String field, dynamic value) {
    return _indexes[collection]?[field]?[value.toString()] ?? <String>{};
  }

  Set<String> findByRange(
    String collection,
    String field, {
    dynamic greaterThan,
    dynamic lessThan,
    dynamic greaterOrEqual,
    dynamic lessOrEqual,
  }) {
    final results = <String>{};
    final index = _rangeIndexes['$collection.$field'];
    if (index == null) return results;

    for (final entry in index.entries) {
      final key = entry.key;
      if (greaterThan != null && key <= greaterThan) continue;
      if (greaterOrEqual != null && key < greaterOrEqual) continue;
      if (lessThan != null && key >= lessThan) continue;
      if (lessOrEqual != null && key > lessOrEqual) continue;
      results.addAll(entry.value);
    }

    return results;
  }
}

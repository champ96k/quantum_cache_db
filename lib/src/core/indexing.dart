import 'dart:collection';

/// A B-Tree inspired index for fast key lookups.
class Index {
  final Map<String, Map<String, SplayTreeMap<dynamic, String>>> _index = {};

  /// Inserts a new key-documentId mapping into the index.
  void insert(String collection, String field, dynamic value, String docId) {
    if (value == null || value is! Comparable) {
      print(
          "⚠️ Skipping indexing for '$field' due to null/non-comparable value.");
      return;
    }

    // Ensure collection exists
    _index.putIfAbsent(collection, () => {});

    // Ensure field map exists
    _index[collection]!
        .putIfAbsent(field, () => SplayTreeMap<dynamic, String>());

    // Retrieve the correct index map
    final indexMap = _index[collection]![field]!;

    // Insert the value into the index
    indexMap[value] = docId;
  }

  /// Retrieves the documentId for a given indexed key.
  String? get(String collection, String field, dynamic key) {
    return _index[collection]?[field]?[key];
  }

  /// Retrieves all document IDs where keys are within a range.
  List<String> rangeQuery(
      String collection, String field, dynamic start, dynamic end) {
    final indexMap = _index[collection]?[field];
    if (indexMap == null) return [];

    return indexMap.entries
        .where((entry) =>
            entry.key.compareTo(start) >= 0 && entry.key.compareTo(end) <= 0)
        .map((entry) => entry.value)
        .toList();
  }

  /// Deletes an indexed entry.
  void delete(String collection, String field, dynamic key) {
    _index[collection]?[field]?.remove(key);
  }
}

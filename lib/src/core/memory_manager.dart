// # Memory mapping and caching

import 'dart:typed_data';

import 'package:mutex/mutex.dart';
import 'package:quantum_cache_db/quantum_cache_db.dart';

class MemoryManager {
  final HashIndex _primaryIndex = HashIndex();
  final int _pageSize = 4096;
  final Mutex _cacheMutex = Mutex();
  final FileManager _fileManager;
  final Map<String, BTreeIndex> _secondaryIndexes = {};
  final IsolatePool _isolates;

  final LRUCache<int, Uint8List> _pageCache = LRUCache(maxSize: 100);

  MemoryManager(this._fileManager, this._isolates);

  Future<void> load(Uint8List data) async {
    await _cacheMutex.protect(() async {
      _pageCache.put(0, data);
    });
  }

  bool hasIndex(String field) => _secondaryIndexes.containsKey(field);

  Future<Uint8List?> getRecord(String key) async {
    final pointer = await _primaryIndex.get(key);
    if (pointer == null) return null;

    return await _cacheMutex.protect(() async {
      final pageNumber = pointer.position ~/ _pageSize;
      var page = _pageCache.get(pageNumber);
      if (page == null) {
        page = await _fileManager.readPage(pageNumber);
        _pageCache.put(pageNumber, page);
      }

      final offset = pointer.position % _pageSize;
      if (offset + pointer.length > page.length) return null;

      final offsetInBytes = offset;
      final length = offset + pointer.length;

      Uint8List data =
          Uint8List.view(page.buffer, offsetInBytes, length - offsetInBytes);
      return pointer.compressed ? FastCompression.decompress(data) : data;
    });
  }

  Future<void> updateIndex(
      String key, dynamic value, RecordPointer pointer) async {
    await _primaryIndex.put(key, pointer);

    // Update secondary indexes
    if (value is Map<String, dynamic>) {
      for (final entry in _secondaryIndexes.entries) {
        final field = entry.key;
        final index = entry.value;
        final fieldValue = value[field] as Comparable?;
        if (fieldValue != null) {
          index.insert(fieldValue, pointer);
        }
      }
    }
  }

  Future<int> get cacheSize async {
    return await _cacheMutex.protect(() async {
      return _pageCache.values.fold<int>(0, (sum, page) => sum + page.length);
    });
  }

  void createSecondaryIndex(String field) {
    _secondaryIndexes[field] = BTreeIndex();
  }

  Stream<Uint8List> executeQuery(Query query) async* {
    switch (query.type) {
      case QueryType.exact:
        yield* _executeExactQuery(query as ExactQuery);
        break;
      case QueryType.range:
        yield* _executeRangeQuery(query as RangeQuery);
        break;
    }
  }

  Stream<Uint8List> _executeExactQuery(ExactQuery query) async* {
    final pointer = await _primaryIndex.get(query.key);
    if (pointer != null) {
      yield await _fileManager.read(pointer.position, pointer.length);
    }
  }

  Stream<Uint8List> _executeRangeQuery(RangeQuery query) async* {
    final index = _secondaryIndexes[query.field];
    if (index == null) throw Exception('Index not found for ${query.field}');

    await for (final pointer in index.rangeScan(query.min, query.max)) {
      yield await _fileManager.read(pointer.position, pointer.length);
    }
  }

  Future<void> deleteRecord(String key) async {
    // Implementation to mark record as deleted
    // (This would depend on your storage format)
  }

  Future<void> deleteIndex(String key) async {
    final pointer = await _primaryIndex.get(key);
    if (pointer != null) {
      await _primaryIndex.remove(key);

      // Get the full record to update secondary indexes
      final recordData =
          await _fileManager.read(pointer.position, pointer.length);
      final record = await _isolates.decode(recordData);

      // Remove from secondary indexes
      for (final entry in _secondaryIndexes.entries) {
        final field = entry.key;
        final index = entry.value;
        final fieldValue = record[field] as Comparable?;

        if (fieldValue != null) {
          // Pass both the field value and pointer to remove
          index.remove(fieldValue, pointer);
        }
      }
    }
  }
}

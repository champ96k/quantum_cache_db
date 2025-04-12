// # Memory mapping and caching

import 'dart:typed_data';

import 'package:mutex/mutex.dart';
import 'package:quantum_cache_db/src/core/file_manager.dart';
import 'package:quantum_cache_db/src/core/lru_cache.dart';
import 'package:quantum_cache_db/src/indexing/hash_index.dart';
import 'package:quantum_cache_db/src/core/record_pointer.dart';
import 'package:quantum_cache_db/src/utils/compression.dart';

class MemoryManager {
  final HashIndex _primaryIndex = HashIndex();
  final int _pageSize = 4096;
  final Mutex _cacheMutex = Mutex();
  final FileManager _fileManager;
  MemoryManager(this._fileManager);
  final LRUCache<int, Uint8List> _pageCache = LRUCache(maxSize: 100);

  Future<void> load(Uint8List data) async {
    await _cacheMutex.protect(() async {
      _pageCache.put(0, data);
    });
  }

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

      final data = page.sublist(offset, offset + pointer.length);
      return pointer.compressed ? FastCompression.decompress(data) : data;
    });
  }

  Future<void> updateIndex(String key, RecordPointer pointer) async {
    await _primaryIndex.put(key, pointer);
  }

  Future<int> get cacheSize async {
    return await _cacheMutex.protect(() async {
      return _pageCache.values.fold<int>(0, (sum, page) => sum + page.length);
    });
  }
}

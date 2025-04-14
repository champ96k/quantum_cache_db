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

  int get pageSize => _pageSize;

  Future<void> load(Uint8List data) async {
    await _cacheMutex.protect(() async {
      int offset = 0;
      int pageNumber = 0;
      while (offset < data.length) {
        int end = offset + _pageSize;
        if (end > data.length) {
          end = data.length;
        }
        Uint8List pageData = data.sublist(offset, end);
        _pageCache.put(pageNumber, pageData);
        offset = end;
        pageNumber++;
      }
    });
  }

  Future<Uint8List?> getRecord(String key) async {
    final pointer = await _primaryIndex.get(key);
    if (pointer == null) return null;

    return await _cacheMutex.protect(() async {
      final pageNumber = pointer.position ~/ pageSize;
      var page = _pageCache.get(pageNumber);

      if (page == null) {
        page = await _fileManager.readPage(pageNumber);
        _pageCache.put(pageNumber, page);
      }

      final offset = pointer.position % pageSize;
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

  Future<void> invalidatePages(int startPage, int endPage) async {
    await _cacheMutex.protect(() async {
      for (int page = startPage; page <= endPage; page++) {
        _pageCache.remove(page);
      }
    });
  }
}

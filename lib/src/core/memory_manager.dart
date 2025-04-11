// # Memory mapping and caching

import 'dart:typed_data';

import 'package:mutex/mutex.dart';
import 'package:quantum_cache_db/src/indexing/hash_index.dart';
import 'package:quantum_cache_db/src/core/record_pointer.dart';
import 'package:quantum_cache_db/src/utils/compression.dart';

class MemoryManager {
  final HashIndex _primaryIndex = HashIndex();
  final Map<int, Uint8List> _pageCache = {};
  final int _pageSize = 4096;
  final Mutex _cacheMutex = Mutex();

  Future<void> load(Uint8List data) async {
    await _cacheMutex.protect(() async {
      if (data.isNotEmpty) {
        _pageCache[0] = data;
      } else {
        _pageCache[0] = Uint8List(0);
      }
    });
  }

  Future<Uint8List?> getRecord(String key) async {
    final pointer = await _primaryIndex.get(key);
    if (pointer == null) return null;

    return await _cacheMutex.protect(() async {
      final pageNumber = pointer.position ~/ _pageSize;
      var page = _pageCache[pageNumber];

      // Initialize page if doesn't exist or is too small
      if (page == null ||
          page.length < pointer.position % _pageSize + pointer.length) {
        page = Uint8List(_pageSize);
        _pageCache[pageNumber] = page;
      }

      final offset = pointer.position % _pageSize;
      if (offset + pointer.length > page.length) {
        return null; // Invalid pointer
      }

      final recordBytes = page.sublist(offset, offset + pointer.length);
      return pointer.compressed
          ? FastCompression.decompress(recordBytes)
          : recordBytes;
    });
  }

  Future<void> updateIndex(String key, RecordPointer pointer) async {
    await _primaryIndex.put(key, pointer);
  }

  Future<int> get cacheSize async {
    return await _cacheMutex.protect(() {
      // Perform calculation synchronously within protected block
      int total = 0;
      for (final page in _pageCache.values) {
        total += page.length;
      }
      return Future.value(total);
    });
  }
}

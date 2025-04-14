// # Low-level storage operations

import 'package:mutex/mutex.dart';
import 'package:quantum_cache_db/src/core/file_manager.dart';
import 'package:quantum_cache_db/src/core/memory_manager.dart';
import 'package:quantum_cache_db/src/core/record_pointer.dart';
import 'package:quantum_cache_db/src/utils/isolate_pool.dart';

class QuantumCacheDB {
  final FileManager _files;
  late final MemoryManager _memory;
  final IsolatePool _isolates;
  final Mutex _writeMutex = Mutex();

  QuantumCacheDB(String path, {int isolateCount = 2})
      : _files = FileManager(path),
        _isolates = IsolatePool() {
    _memory = MemoryManager(_files);
    _isolates.initialize(isolateCount);
  }

  Future<void> init() async {
    await _files.initialize();
    final activeFileData = await _files.activeFile;
    await _memory.load(activeFileData);
  }

  Future<void> put(String key, dynamic value) async {
    await _writeMutex.protect(() async {
      final encoded = await _isolates.encode(value);
      final position = await _files.append(encoded);
      // Invalidate affected pages in cache
      final startPage = position ~/ _memory.pageSize;
      final endPage = (position + encoded.length - 1) ~/ _memory.pageSize;
      await _memory.invalidatePages(startPage, endPage);
      await _memory.updateIndex(key, RecordPointer(position, encoded.length));
    });
  }

  Future<dynamic> get(String key) async {
    final record = await _memory.getRecord(key);
    return record != null ? await _isolates.decode(record) : null;
  }

  Future<void> compact() async {
    await _writeMutex.protect(() async {
      // Implement compaction algorithm
    });
  }
}

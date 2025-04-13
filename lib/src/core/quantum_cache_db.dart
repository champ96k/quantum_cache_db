// # Low-level storage operations

import 'package:mutex/mutex.dart';
import 'package:quantum_cache_db/quantum_cache_db.dart';

class QuantumCacheDB {
  final MemoryManager _memory;
  final FileManager _files;
  final IsolatePool _isolates;
  final Mutex _writeMutex = Mutex();

  QuantumCacheDB(String path, {int isolateCount = 2})
      : _memory = MemoryManager(FileManager(path), IsolatePool()),
        _files = FileManager(path),
        _isolates = IsolatePool() {
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
      final pointer = RecordPointer(position, encoded.length);

      // Auto-detect indexes
      if (value is Map<String, dynamic>) {
        for (final field in value.keys) {
          if (!_memory.hasIndex(field)) {
            _memory.createSecondaryIndex(field);
          }
          _memory.updateIndex(field, value[field], pointer);
        }
      }
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

  Stream<dynamic> query(Query query) async* {
    await for (final data in _memory.executeQuery(query)) {
      yield _isolates.decode(data);
    }
  }

  void createIndex(String field) {
    _memory.createSecondaryIndex(field);
  }

  Future<void> delete(String key) async {
    await _writeMutex.protect(() async {
      await _memory.deleteIndex(key);
      await _files.deleteRecord(key);
    });
  }

  Future<void> close() async {
    await _files.close();
    await _isolates.dispose();
  }
}

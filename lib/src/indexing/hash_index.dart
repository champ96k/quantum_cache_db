// lib/src/indexing/hash_index.dart
import 'dart:collection';

import 'package:mutex/mutex.dart';
import 'package:quantum_cache_db/src/core/record_pointer.dart';

class HashIndex {
  final HashMap<String, RecordPointer> _index = HashMap();
  final Mutex _mutex = Mutex();

  Future<void> put(String key, RecordPointer pointer) async {
    _index[key] = pointer;
  }

  Future<RecordPointer?> get(String key) async {
    return _index[key];
  }

  Future<bool> containsKey(String key) async {
    return await _mutex.protect(() async => _index.containsKey(key));
  }

  Future<void> remove(String key) async {
    await _mutex.protect(() async {
      _index.remove(key);
    });
  }

  Future<void> clear() async {
    await _mutex.protect(() async {
      _index.clear();
    });
  }

  Future<int> get size async {
    return await _mutex.protect(() async => _index.length);
  }

  Map<String, RecordPointer> getAll() {
    return Map.from(_index);
  }
}

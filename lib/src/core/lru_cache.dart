import 'dart:collection';

class LRUCache<K, V> {
  final LinkedHashMap<K, V> _cache = LinkedHashMap();
  final int maxSize;

  LRUCache({required this.maxSize});

  V? get(K key) {
    if (_cache.containsKey(key)) {
      final value = _cache.remove(key);
      _cache[key] = value as V;
      return value;
    }
    return null;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
    _cache[key] = value;
  }

  List<V> get values => _cache.values.toList();
}

// # B-tree implementation
import 'package:quantum_cache_db/src/core/record_pointer.dart';
import 'package:quantum_cache_db/src/query/any_comparable.dart';

class BTreeIndex<T extends Comparable> {
  final Map<AnyComparable, List<RecordPointer>> _index = {};

  void insert(dynamic value, RecordPointer pointer) {
    final key = AnyComparable.from(value);
    _index.putIfAbsent(key, () => []).add(pointer);
  }

  Stream<RecordPointer> rangeScan(dynamic minVal, dynamic maxVal) async* {
    final min = AnyComparable.from(minVal);
    final max = AnyComparable.from(maxVal);

    final keys = _index.keys
        .where((k) => k.compareTo(min) >= 0 && k.compareTo(max) <= 0)
        .toList()
      ..sort();

    for (final key in keys) {
      yield* Stream.fromIterable(_index[key]!);
    }
  }

  void remove(T fieldValue, RecordPointer pointer) {
    if (_index.containsKey(fieldValue)) {
      _index[fieldValue]!.removeWhere((p) => p.position == pointer.position);
      if (_index[fieldValue]!.isEmpty) {
        _index.remove(fieldValue);
      }
    }
  }
}

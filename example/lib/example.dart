// bin/benchmark.dart
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:quantum_cache_db/quantum_cache_db.dart';

void main() async {
  final db = QuantumCacheDB(
      path.join(Directory.systemTemp.path, 'benchmark_ultrafast_complex.db'));
  await db.init();

  for (int i = 0; i < 10; i++) {
    await db.put('user_$i', {
      'id': i,
      'name': 'User $i',
      'preferences': {
        'darkMode': i % 2 == 0,
        'notifications': true,
      },
      'tags': ['user', 'test', 'item$i'],
    });
  }

  print("10 records added");

  for (int i = 0; i < 10; i++) {
    final value = await db.get('user_$i');
    print("User$i: $value");
  }
}

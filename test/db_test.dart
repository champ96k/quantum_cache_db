// bin/main.dart
import 'dart:io';
import 'package:quantum_cache_db/quantum_cache_db.dart';

void main() async {
  // Clean up any previous test file
  final testFile = File('test.db');
  if (await testFile.exists()) await testFile.delete();

  // Initialize the database
  final db = QuantumCacheDB('test.db');
  await db.init();

  try {
    // Test with small dataset first
    print('Testing with 10000 records...');
    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < 10000; i++) {
      await db.put('key_$i', {
        'index': i,
        'name': 'Item $i',
        'timestamp': DateTime.now().millisecondsSinceEpoch
      });
    }
    print('Write 10000 records: ${stopwatch.elapsedMilliseconds}ms');

    // Verify reads work
    stopwatch.reset();
    for (var i = 0; i < 10000; i++) {
      final value = await db.get('key_$i');
      assert(value != null, 'Failed to read key_$i');
    }
    print('Read 10000 records: ${stopwatch.elapsedMilliseconds}ms');

    // Now test with larger dataset
    print('\nTesting with 10000 records...');
    stopwatch.reset();
    for (var i = 0; i < 10000; i++) {
      await db.put('bulk_$i', {
        'index': i,
        'data': 'X' * 10000, // 100-byte payload
      });
    }
    print('Write 10000 records: ${stopwatch.elapsedMilliseconds}ms');

    // Clean up
    await testFile.delete();
    print('Database test completed successfully');
  } catch (e) {
    print('Error during test: $e');
    rethrow;
  }
}

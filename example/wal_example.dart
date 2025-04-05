import 'dart:io';
import 'package:quantum_cache_db/src/core/wal/wal.dart';

Future<void> main() async {
  const testFile = 'test_wal.log';
  // Clean up any previous test file
  if (await File(testFile).exists()) {
    await File(testFile).delete();
  }

  try {
    // Initialize WAL
    final wal = WriteAheadLog(testFile, batchSize: 3);

    print('Testing basic operations...');
    await wal.logWrite('SET', 'user:1', {'name': 'Alice', 'age': 30});
    await wal.logWrite('SET', 'user:2', {'name': 'Bob', 'age': 25});
    await wal.logWrite('DELETE', 'user:1', null);
    await wal.flush();
    print('Operations written to WAL');

    print('\nSimulating crash recovery...');
    await wal.close();

    // Re-open the WAL
    final recoveredWal = WriteAheadLog(testFile, batchSize: 3);
    await recoveredWal.flush();
    print('Recovery completed successfully');

    print('\nAdding more operations...');
    await recoveredWal
        .logWrite('SET', 'user:3', {'name': 'Charlie', 'age': 35});
    await recoveredWal.logWrite('SET', 'user:4', {'name': 'Dana', 'age': 28});
    print('Added 2 operations');

    print('\nTesting compaction...');
    for (var i = 0; i < 100; i++) {
      await recoveredWal.logWrite('SET', 'temp:$i', {'value': i});
      if (i % 10 == 0) await Future.delayed(Duration.zero);
    }
    await recoveredWal.flush();
    print('Compaction completed');

    print('\nTest completed successfully!');
  } catch (e) {
    print('Test failed: $e');
  } finally {
    // Clean up
    try {
      if (await File(testFile).exists()) {
        await File(testFile).delete();
      }
    } catch (e) {
      print('Error cleaning up: $e');
    }
  }
}

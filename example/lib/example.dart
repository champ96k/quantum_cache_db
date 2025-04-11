// bin/benchmark.dart
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:quantum_cache_db/quantum_cache_db.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as path;

const int numberOfOperations = 2000;
const bool showDebugOutput = false;

void main() async {
  print('=== Database Benchmark ($numberOfOperations ops) ===\n');

  // Clean up previous test files
  await _cleanupTestFiles();

  // Run benchmarks
  await _runBenchmark('Hive', benchmarkHive);
  await _runBenchmark('SQLite', benchmarkSqlite);
  await _runBenchmark('QuantumCacheDB', benchmarkUltraFastDB);
  await _runBenchmark('QuantumCacheDB (complex)', benchmarkUltraFastDBComplex);

  print('\n=== Benchmark Complete ===');
}

Future<void> _cleanupTestFiles() async {
  final files = [
    path.join(Directory.systemTemp.path, 'benchmark_hive'),
    path.join(Directory.systemTemp.path, 'benchmark_sqlite.db'),
    path.join(Directory.systemTemp.path, 'benchmark_isar'),
    path.join(Directory.systemTemp.path, 'benchmark_ultrafast.db'),
  ];

  for (final file in files) {
    try {
      if (await File(file).exists()) await File(file).delete();
      if (await Directory(file).exists()) {
        await Directory(file).delete(recursive: true);
      }
    } catch (e) {
      if (showDebugOutput) print('Cleanup error for $file: $e');
    }
  }
}

Future<void> _runBenchmark(
    String name, Future<void> Function() benchmarkFn) async {
  print('Running $name...');
  final stopwatch = Stopwatch()..start();
  try {
    await benchmarkFn();
  } catch (e) {
    print('Error in $name: $e');
    rethrow;
  } finally {
    stopwatch.stop();
    print('$name completed in: ${stopwatch.elapsedMilliseconds}ms\n');
  }
}

Future<void> benchmarkHive() async {
  Hive.init(Directory.systemTemp.path);
  final box = await Hive.openBox('benchmark_hive');

  // Write test
  for (int i = 0; i < numberOfOperations; i++) {
    await box.put('key_$i', 'value_$i');
    if (showDebugOutput && i % 500 == 0) print('Hive write $i');
  }

  // Read test
  for (int i = 0; i < numberOfOperations; i++) {
    final value = box.get('key_$i');
    if (showDebugOutput && i % 500 == 0) print('Hive read $i: $value');
  }

  await box.close();
}

Future<void> benchmarkSqlite() async {
  final db =
      sqlite3.open(path.join(Directory.systemTemp.path, 'benchmark_sqlite.db'));

  db.execute('''
    CREATE TABLE IF NOT EXISTS benchmark (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key TEXT UNIQUE,
      value TEXT
    )
  ''');

  // Write test
  final stmt =
      db.prepare('INSERT OR REPLACE INTO benchmark (key, value) VALUES (?, ?)');
  for (int i = 0; i < numberOfOperations; i++) {
    stmt.execute(['key_$i', 'value_$i']);
    if (showDebugOutput && i % 500 == 0) print('SQLite write $i');
  }
  stmt.dispose();

  // Read test
  final readStmt = db.prepare('SELECT value FROM benchmark WHERE key = ?');
  for (int i = 0; i < numberOfOperations; i++) {
    final result = readStmt.select(['key_$i']);
    if (showDebugOutput && i % 500 == 0) {
      print('SQLite read $i: ${result.first}');
    }
  }
  readStmt.dispose();

  db.dispose();
}

Future<void> benchmarkUltraFastDB() async {
  final db = QuantumCacheDB(
      path.join(Directory.systemTemp.path, 'benchmark_ultrafast.db'));
  await db.init();

  // Write test
  for (int i = 0; i < numberOfOperations; i++) {
    await db.put('key_$i', 'value_$i');
    if (showDebugOutput && i % 500 == 0) print('QuantumCacheDB write $i');
  }

  // Read test
  for (int i = 0; i < numberOfOperations; i++) {
    final value = await db.get('key_$i');
    if (showDebugOutput && i % 500 == 0) {
      print('QuantumCacheDB read $i: $value');
    }
  }
}

Future<void> benchmarkUltraFastDBComplex() async {
  final db = QuantumCacheDB(
      path.join(Directory.systemTemp.path, 'benchmark_ultrafast_complex.db'));
  await db.init();

  // Write test with complex data
  for (int i = 0; i < numberOfOperations; i++) {
    await db.put('user_$i', {
      'id': i,
      'name': 'User $i',
      'preferences': {
        'darkMode': i % 2 == 0,
        'notifications': true,
      },
      'tags': ['user', 'test', 'item$i'],
    });
    if (showDebugOutput && i % 500 == 0) {
      print('QuantumCacheDB complex write $i');
    }
  }

  // Read test
  for (int i = 0; i < numberOfOperations; i++) {
    final value = await db.get('user_$i');
    if (showDebugOutput && i % 500 == 0) {
      print('QuantumCacheDB complex read $i: ${value?['name']}');
    }
  }
}

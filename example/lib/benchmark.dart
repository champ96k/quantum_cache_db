// bin/benchmark.dart
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:quantum_cache_db/quantum_cache_db.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as path;

const int numberOfOperations = 10000;
const bool showDebugOutput = false;

class BenchmarkResult {
  final String dbName;
  final int writeTime;
  final int readTime;
  final int fileSize;

  BenchmarkResult(this.dbName, this.writeTime, this.readTime, this.fileSize);
}

void main() async {
  print('=== Database Benchmark ($numberOfOperations ops) ===\n');

  // Clean up previous test files
  await _cleanupTestFiles();

  // Run benchmarks and collect results
  final results = <BenchmarkResult>[];
  results.add(await benchmarkHive());
  results.add(await benchmarkSqlite());
  results.add(await benchmarkUltraFastDB());
  results.add(await benchmarkUltraFastDBComplex());
  results.add(await benchmarkQuantumQuery());

  // Print results
  _printResultsTable(results);

  print('\n=== Benchmark Complete ===');
}

void _printResultsTable(List<BenchmarkResult> results) {
  print('| Database           | Write (ms) | Read (ms) | File Size (KB) |');
  print('|--------------------|------------|-----------|----------------|');

  for (final result in results) {
    final writeTime =
        result.writeTime >= 0 ? result.writeTime.toString() : 'ERROR';
    final readTime =
        result.readTime >= 0 ? result.readTime.toString() : 'ERROR';
    final fileSize = result.fileSize >= 0
        ? (result.fileSize / 1024).toStringAsFixed(1)
        : 'ERROR';

    print('| ${result.dbName.padRight(18)} | '
        '${writeTime.padLeft(9)} | '
        '${readTime.padLeft(8)} | '
        '${fileSize.padLeft(13)} |');
  }
}

Future<void> _cleanupTestFiles() async {
  final files = [
    path.join(Directory.systemTemp.path, 'benchmark_hive'),
    path.join(Directory.systemTemp.path, 'benchmark_sqlite.db'),
    path.join(Directory.systemTemp.path, 'benchmark_ultrafast.db'),
    path.join(Directory.systemTemp.path, 'benchmark_ultrafast_complex.db'),
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

Future<BenchmarkResult> benchmarkHive() async {
  final stopwatch = Stopwatch();
  final hivePath = path.join(Directory.systemTemp.path, 'benchmark_hive');
  try {
    Hive.init(hivePath);
    final box = await Hive.openBox('benchmark_hive');

    // Write test
    stopwatch.start();
    for (int i = 0; i < numberOfOperations; i++) {
      await box.put('key_$i', 'value_$i');
    }
    final writeTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // Read test
    stopwatch.start();
    for (int i = 0; i < numberOfOperations; i++) {
      box.get('key_$i');
    }
    final readTime = stopwatch.elapsedMilliseconds;

    await box.close();

    // Calculate total size of Hive files
    int fileSize = 0;
    final hiveDir = Directory(hivePath);
    if (await hiveDir.exists()) {
      await for (var entity in hiveDir.list(recursive: true)) {
        if (entity is File) {
          fileSize += await entity.length();
        }
      }
    }

    return BenchmarkResult('Hive', writeTime, readTime, fileSize);
  } catch (e) {
    print('Hive error: $e');
    return BenchmarkResult('Hive', -1, -1, -1);
  }
}

Future<BenchmarkResult> benchmarkSqlite() async {
  final stopwatch = Stopwatch();
  final dbPath = path.join(Directory.systemTemp.path, 'benchmark_sqlite.db');
  try {
    final db = sqlite3.open(dbPath);

    db.execute('''
      CREATE TABLE IF NOT EXISTS benchmark (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE,
        value TEXT
      )
    ''');

    // Write test
    stopwatch.start();
    final stmt = db
        .prepare('INSERT OR REPLACE INTO benchmark (key, value) VALUES (?, ?)');
    for (int i = 0; i < numberOfOperations; i++) {
      stmt.execute(['key_$i', 'value_$i']);
    }
    final writeTime = stopwatch.elapsedMilliseconds;
    stmt.dispose();
    stopwatch.reset();

    // Read test
    stopwatch.start();
    final readStmt = db.prepare('SELECT value FROM benchmark WHERE key = ?');
    for (int i = 0; i < numberOfOperations; i++) {
      readStmt.select(['key_$i']);
    }
    final readTime = stopwatch.elapsedMilliseconds;
    readStmt.dispose();

    db.dispose();

    final fileSize = await File(dbPath).length();
    return BenchmarkResult('SQLite', writeTime, readTime, fileSize);
  } catch (e) {
    print('SQLite error: $e');
    return BenchmarkResult('SQLite', -1, -1, -1);
  }
}

// New query benchmark function
Future<BenchmarkResult> benchmarkQuantumQuery() async {
  final stopwatch = Stopwatch();
  final dbPath =
      path.join(Directory.systemTemp.path, 'benchmark_quantum_query.db');
  try {
    final db = QuantumCacheDB(dbPath);
    await db.init();

    // Write test data
    stopwatch.start();
    for (int i = 0; i < numberOfOperations; i++) {
      await db.put('qry_$i', {
        'id': i,
        'data': 'Query test data $i',
      });
    }
    final writeTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // Query test
    stopwatch.start();
    for (int i = 0; i < numberOfOperations; i++) {
      await db.get('qry_$i');
    }
    final readTime = stopwatch.elapsedMilliseconds;

    final fileSize = await File(dbPath).length();
    return BenchmarkResult('Quantum Query', writeTime, readTime, fileSize);
  } catch (e) {
    print('Quantum Query error: $e');
    return BenchmarkResult('Quantum Query', -1, -1, -1);
  }
}

Future<BenchmarkResult> benchmarkUltraFastDB() async {
  final stopwatch = Stopwatch();
  final dbPath = path.join(Directory.systemTemp.path, 'benchmark_ultrafast.db');
  try {
    final db = QuantumCacheDB(dbPath);
    await db.init();

    // Write test
    stopwatch.start();
    for (int i = 0; i < numberOfOperations; i++) {
      await db.put('key_$i', 'value_$i');
    }
    final writeTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // Read test
    stopwatch.start();
    for (int i = 0; i < numberOfOperations; i++) {
      await db.get('key_$i');
    }
    final readTime = stopwatch.elapsedMilliseconds;

    final fileSize = await File(dbPath).length();
    return BenchmarkResult('QuantumCacheDB', writeTime, readTime, fileSize);
  } catch (e) {
    print('QuantumCacheDB error: $e');
    return BenchmarkResult('QuantumCacheDB', -1, -1, -1);
  }
}

Future<BenchmarkResult> benchmarkUltraFastDBComplex() async {
  final stopwatch = Stopwatch();
  final dbPath =
      path.join(Directory.systemTemp.path, 'benchmark_ultrafast_complex.db');
  try {
    final db = QuantumCacheDB(dbPath);
    await db.init();

    // Write test
    stopwatch.start();
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
    }
    final writeTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // Read test
    stopwatch.start();
    for (int i = 0; i < numberOfOperations; i++) {
      await db.get('user_$i');
    }
    final readTime = stopwatch.elapsedMilliseconds;

    final fileSize = await File(dbPath).length();
    return BenchmarkResult('Quantum (complex)', writeTime, readTime, fileSize);
  } catch (e) {
    print('QuantumCacheDB (complex) error: $e');
    return BenchmarkResult('QuantumCacheDB (complex)', -1, -1, -1);
  }
}

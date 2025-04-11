// bin/benchmark.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:hive/hive.dart';

// Our pure Dart database implementation
class QuantumCacheDB {
  final Map<String, Uint8List> _storage = {};
  final Map<String, RecordPointer> _index = {};

  Future<void> init() async {
    // Initialization logic
  }

  Future<void> put(String key, dynamic value) async {
    final encoded = _encode(value);
    _storage[key] = encoded;
    _index[key] = RecordPointer(0, encoded.length); // Simplified for benchmark
  }

  Future<dynamic> get(String key) async {
    final bytes = _storage[key];
    return bytes != null ? _decode(bytes) : null;
  }

  Uint8List _encode(dynamic value) {
    return Uint8List.fromList(utf8.encode(json.encode(value)));
  }

  dynamic _decode(Uint8List bytes) {
    return json.decode(utf8.decode(bytes));
  }
}

class RecordPointer {
  final int position;
  final int length;
  RecordPointer(this.position, this.length);
}

Future<void> main() async {
  // Clean up previous test files
  await _cleanupFiles();

  print('=== Pure Dart Database Benchmark ===\n');

  // 1. Benchmark QuantumCacheDB
  final ultraFastResult = await _runBenchmark(
    'QuantumCacheDB',
    () => QuantumCacheDB(),
    (db) => db.init(),
  );

  // 2. Benchmark Hive
  final hiveResult = await _runBenchmark(
    'Hive',
    () => _HiveWrapper(),
    (db) => db.init(),
  );

  // Print results
  _printResults([ultraFastResult, hiveResult]);
}

class _HiveWrapper {
  late Box box;

  Future<void> init() async {
    Hive.init(Directory.current.path);
    box = await Hive.openBox('benchmark_hive');
  }

  Future<void> put(String key, dynamic value) async {
    await box.put(key, value);
  }

  Future<dynamic> get(String key) async {
    return await box.get(key);
  }

  Future<void> close() async {
    await box.close();
  }
}

class BenchmarkResult {
  final String dbName;
  final int writeTime;
  final int readTime;
  final int memoryUsage;

  BenchmarkResult(this.dbName, this.writeTime, this.readTime, this.memoryUsage);
}

Future<void> _cleanupFiles() async {
  try {
    await Directory.current.list().forEach((entity) {
      if (entity is File && entity.path.endsWith('.hive')) {
        entity.deleteSync();
      }
    });
  } catch (e) {
    print('Error cleaning up files: $e');
  }
}

Future<BenchmarkResult> _runBenchmark(
  String dbName,
  Function() dbFactory,
  Future<void> Function(dynamic) initDb,
) async {
  print('Running benchmark for $dbName...');
  final db = dbFactory();
  await initDb(db);

  // Test data
  final testData = List.generate(
      100000,
      (i) => {
            'index': i,
            'name': 'Item $i',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'data': 'X' * 100, // 100-byte payload
          });

  // Write benchmark
  final writeStopwatch = Stopwatch()..start();
  for (var i = 0; i < testData.length; i++) {
    await db.put('key_$i', testData[i]);
  }
  final writeTime = writeStopwatch.elapsedMilliseconds;

  // Read benchmark
  final readStopwatch = Stopwatch()..start();
  for (var i = 0; i < testData.length; i++) {
    await db.get('key_$i');
  }
  final readTime = readStopwatch.elapsedMilliseconds;

  // Clean up
  if (db is _HiveWrapper) await db.close();

  return BenchmarkResult(
    dbName,
    writeTime,
    readTime,
    ProcessInfo.currentRss,
  );
}

void _printResults(List<BenchmarkResult> results) {
  print('| Database     | Write (ms) | Read (ms) | Memory (MB) |');
  print('|--------------|------------|-----------|-------------|');

  for (final result in results) {
    print('| ${result.dbName.padRight(12)} | '
        '${result.writeTime.toString().padLeft(9)} | '
        '${result.readTime.toString().padLeft(8)} | '
        '${(result.memoryUsage / (1024 * 1024)).toStringAsFixed(2).padLeft(10)} |');
  }

  print('\nBenchmark completed!');
}

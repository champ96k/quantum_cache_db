// ignore_for_file: avoid_print

import 'dart:io';
import 'package:hive/hive.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:quantum_cache_db/quantum_cache_db.dart';

const int numberOfOperations = 5000;

void main() async {
  print("For input $numberOfOperations");
  await benchmarkHive();
  await benchmarkSqlite();
  await benchmarkQuantumCacheDB();
  await benchmarkQuantumCacheDBWithStorage();
}

Future<void> benchmarkHive() async {
  final stopwatch = Stopwatch()..start();

  Hive.init(Directory.systemTemp.path);
  var box = await Hive.openBox('testBox');

  for (int i = 0; i < numberOfOperations; i++) {
    await box.put('key_$i', 'value_$i');
  }

  for (int i = 0; i < numberOfOperations; i++) {
    box.get('key_$i');
    // print("Value: $value");
  }

  await box.close();
  stopwatch.stop();
  print('Hive completed in: ${stopwatch.elapsedMilliseconds}ms');
}

Future<void> benchmarkSqlite() async {
  final stopwatch = Stopwatch()..start();

  var db = sqlite3.open('${Directory.systemTemp.path}/test.db');
  db.execute(
      'CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY, value TEXT)');

  for (int i = 0; i < numberOfOperations; i++) {
    db.execute('INSERT INTO test (value) VALUES (?)', ['value_$i']);
  }

  for (int i = 0; i < numberOfOperations; i++) {
    db.select('SELECT value FROM test WHERE id = ?', [i + 1]);
  }

  db.dispose();
  stopwatch.stop();
  print('SQLite completed in: ${stopwatch.elapsedMilliseconds}ms');
}

Future<void> benchmarkQuantumCacheDB() async {
  final stopwatch = Stopwatch()..start();

  var db = QuantumCacheDB(
      '${Directory.systemTemp.path}/quantum_cache.db', 'secret_key');

  for (int i = 0; i < numberOfOperations; i++) {
    await db.set('key_$i', 'value_$i');
  }

  for (int i = 0; i < numberOfOperations; i++) {
    db.get('key_$i');
  }

  stopwatch.stop();
  print('QuantumCacheDB completed in: ${stopwatch.elapsedMilliseconds}ms');
}

Future<void> benchmarkQuantumCacheDBWithStorage() async {
  final stopwatch = Stopwatch()..start();

  var db = QuantumCacheDB(
      '${Directory.systemTemp.path}/quantum_cache.db', 'secret_key');

  for (int i = 0; i < numberOfOperations; i++) {
    await db.set('key_$i', 'value_$i');
    await db.collection("users").doc("key_${i + 1}").set({
      "name": "Alice ${i + 1}",
      "age": 30 * i,
      "city": "New York",
    });
  }

  for (int i = 0; i < numberOfOperations; i++) {
    db.collection("users").doc("key_${i + 1}").get();
  }

  stopwatch.stop();
  print(
      'QuantumCacheDB collection completed in: ${stopwatch.elapsedMilliseconds}ms');
}

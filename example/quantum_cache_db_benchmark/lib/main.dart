import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quantum_cache_db/quantum_cache_db.dart';

void main() async {
  // Initialize Hive
  await Hive.initFlutter();
  await QuantumCacheDB("my_database.db", "mySecretKey").init();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BenchmarkScreen(),
    );
  }
}

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  String results = 'Press the button to start benchmarking...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Benchmarking'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(results),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await benchmarkDatabases();
              },
              child: const Text('Run Benchmark'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> benchmarkDatabases() async {
    // Prepare Hive
    var hiveBox = await Hive.openBox('benchmarkBox');

    // Prepare SQLite
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String dbPath = '${appDocDir.path}/benchmark.db';
    Database sqliteDb =
        await openDatabase(dbPath, version: 1, onCreate: (db, version) {
      db.execute(
          'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER, city TEXT)');
    });

    // Prepare QuantumCacheDB
    QuantumCacheDB quantumDB = QuantumCacheDB('quantumCache.db', 'mySecretKey');
    await quantumDB.init();

    // Run Insert Benchmark
    String insertResults = await benchmarkInsert(hiveBox, sqliteDb, quantumDB);

    // Run Query Benchmark
    String queryResults = await benchmarkQuery(hiveBox, sqliteDb, quantumDB);

    setState(() {
      results = '$insertResults\n$queryResults';
    });
  }

  Future<String> benchmarkInsert(
      Box hiveBox, Database sqliteDb, QuantumCacheDB quantumDB) async {
    const int numRecords =
        1000; // Adjust the number of records for your benchmark

    Stopwatch stopwatch = Stopwatch();

    // Insert data into Hive
    stopwatch.start();
    for (int i = 0; i < numRecords; i++) {
      hiveBox.put(i.toString(),
          {'name': 'User $i', 'age': 20 + (i % 50), 'city': 'City $i'});
    }
    int hiveInsertTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // Insert data into SQLite
    stopwatch.start();
    for (int i = 0; i < numRecords; i++) {
      await sqliteDb.insert('users',
          {'name': 'User $i', 'age': 20 + (i % 50), 'city': 'City $i'});
    }
    int sqliteInsertTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // Insert data into QuantumCacheDB
    stopwatch.start();
    for (int i = 0; i < numRecords; i++) {
      await quantumDB.collection('users').doc(i.toString()).set({
        'name': 'User $i',
        'age': 20 + (i % 50),
        'city': 'City $i',
      });
    }
    int quantumInsertTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    return 'Insert Times:\nHive: ${hiveInsertTime}ms\nSQLite: ${sqliteInsertTime}ms\nQuantumCacheDB: ${quantumInsertTime}ms';
  }

  Future<String> benchmarkQuery(
      Box hiveBox, Database sqliteDb, QuantumCacheDB quantumDB) async {
    const int numRecords =
        1000; // Adjust the number of records for your benchmark

    Stopwatch stopwatch = Stopwatch();

    // Query data from Hive
    stopwatch.start();
    for (int i = 0; i < numRecords; i++) {
      final user = hiveBox.get(i.toString());
      debugPrint("User: $user");
    }
    int hiveQueryTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // Query data from SQLite
    stopwatch.start();
    for (int i = 0; i < numRecords; i++) {
      final List<Map<String, Object?>> result =
          await sqliteDb.query('users', where: 'id = ?', whereArgs: [i]);
      debugPrint("Result: $result");
    }
    int sqliteQueryTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // Query data from QuantumCacheDB
    stopwatch.start();
    for (int i = 0; i < numRecords; i++) {
      final user = quantumDB.collection('users').doc(i.toString()).get();
      debugPrint("User Info: $user");
    }
    int quantumQueryTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    return 'Query Times:\nHive: ${hiveQueryTime}ms\nSQLite: ${sqliteQueryTime}ms\nQuantumCacheDB: ${quantumQueryTime}ms';
  }
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:quantum_cache_db/quantum_cache_db.dart';

void main() {
  late QuantumCacheDB db;
  late Directory tempDir;

  setUpAll(() async {
    // Use a temporary directory for testing
    tempDir = await Directory.systemTemp.createTemp('quantum_cache_test');
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    db = QuantumCacheDB(dbName: 'test_db');
    // Wait a bit for initialization to complete
    await Future.delayed(const Duration(milliseconds: 100));
  });

  tearDown(() async {
    // Clean up test files
    final testDir = Directory(path.join(tempDir.path, 'test_db'));
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  test('set and get operations work correctly', () async {
    const key = 'test_key';
    const value = {'name': 'Test', 'value': 42};

    // Test set operation
    await db.set(key, value);

    // Test get operation
    final retrievedValue = await db.get(key);
    expect(retrievedValue, equals(value));
  });

  test('update operation works correctly', () async {
    const key = 'test_key';
    const initialValue = {'name': 'Test', 'value': 42};
    const updates = {'value': 43, 'newField': 'new'};

    // Set initial value
    await db.set(key, initialValue);

    // Update value
    await db.update(key, updates);

    // Check updated value
    final updatedValue = await db.get(key);
    expect(
        updatedValue,
        equals({
          'name': 'Test',
          'value': 43,
          'newField': 'new',
        }));
  });

  test('delete operation works correctly', () async {
    const key = 'test_key';
    const value = {'name': 'Test'};

    // Set value
    await db.set(key, value);

    // Delete value
    await db.delete(key);

    // Check value is deleted
    final retrievedValue = await db.get(key);
    expect(retrievedValue, isNull);
  });

  test('stream subscription works correctly', () async {
    const key = 'test_key';
    const value1 = {'name': 'Test1'};
    const value2 = {'name': 'Test2'};

    // Set up stream
    final stream = db.on(key);
    final values = <dynamic>[];
    final subscription = stream.listen((value) => values.add(value));

    // Set value
    await db.set(key, value1);
    await Future.delayed(Duration.zero); // Allow stream to process

    // Update value
    await db.set(key, value2);
    await Future.delayed(Duration.zero); // Allow stream to process

    // Delete value
    await db.delete(key);
    await Future.delayed(Duration.zero); // Allow stream to process

    // Cancel subscription
    await subscription.cancel();

    // Check stream values
    expect(values, equals([value1, value2, null]));
  });
}

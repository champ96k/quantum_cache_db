import 'dart:async';
import 'package:quantum_cache_db/quantum_cache_db.dart';

Future<void> main() async {
  late QuantumCacheDB db;
  late StreamSubscription subscription;

  try {
    print('Starting QuantumCacheDB example...');

    // Create a new database instance
    db = QuantumCacheDB(
      dbName: 'example_db',
      // For Flutter apps, you can use:
      // storage: FlutterStorage(),
    );

    // Wait for initialization to complete
    print('Waiting for database initialization...');
    await Future.delayed(const Duration(milliseconds: 100));

    // Set a value
    print('\n1. Setting initial value...');
    await db.set('users/user123', {
      'name': 'John Doe',
      'email': 'john@example.com',
      'age': 30,
    });

    // Get a value
    print('\n2. Getting value...');
    final user = await db.get('users/user123');
    print('User data: $user');

    // Update a value
    print('\n3. Updating value...');
    await db.update('users/user123', {
      'age': 31,
      'phone': '+1234567890',
    });

    // Get the updated value
    print('\n4. Getting updated value...');
    final updatedUser = await db.get('users/user123');
    print('Updated user data: $updatedUser');

    // Listen to changes
    print('\n5. Setting up change listener...');
    subscription = db.on('users/user123').listen((data) {
      print('User data changed: $data');
    });

    // Delete a value
    print('\n6. Deleting value...');
    await db.delete('users/user123');

    // Wait a bit to ensure all operations complete
    await Future.delayed(const Duration(milliseconds: 100));

    print('\nExample completed successfully!');
  } catch (e, stackTrace) {
    print('Error occurred: $e');
    print('Stack trace: $stackTrace');
  } finally {
    // Cancel the subscription
    await subscription.cancel();
    // Always close the database
    await db.close();
  }
}

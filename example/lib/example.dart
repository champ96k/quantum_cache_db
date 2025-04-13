import 'package:quantum_cache_db/quantum_cache_db.dart';

void main() async {
  final db = QuantumCacheDB('example.db');
  await db.init();

  try {
    print('Creating indexes...');
    db.createIndex('name');
    db.createIndex('age');
    db.createIndex('isActive');
    db.createIndex('createdAt');

    print('\n── Inserting Records ──');
    final now = DateTime.now();

    await db.put('user1', {
      'name': 'Alice',
      'age': 28,
      'isActive': true,
      'createdAt': now,
      'tags': ['admin', 'verified']
    });

    await db.put('user2', {
      'name': 'Bob',
      'age': 35,
      'isActive': false,
      'createdAt': now.subtract(Duration(days: 10)),
      'tags': ['user']
    });

    await db.put('user3', {
      'name': 'Charlie',
      'age': 42,
      'isActive': true,
      'createdAt': now.subtract(Duration(days: 5)),
      'tags': ['manager', 'verified']
    });

    final user3 = await db.get('user3');
    print("User 3 details: $user3");

    print('\n── Fetching Single Record ──');
    final user1 = await db.get('user1');
    print('User1: ${user1?['name']} (Age: ${user1?['age']})');

    // Exact query
    print('\nExact Query:');
    final exactResult = await db.query(ExactQuery('user2')).first;
    print('Found user: ${exactResult['name']}');

    // Age range query
    print('\nAge Range Query (30-40):');
    final adults = db.query(RangeQuery('age', 30, 40));
    await adults
        .forEach((user) => print('${user['name']} (${user['age']} years old)'));

    // Boolean query
    print('\nActive Users Query:');
    final activeUsers = db.query(RangeQuery('isActive', true, true));
    print(
        'Active users: ${await activeUsers.map((u) => u['name']).join(', ')}');

    // Date range query
    print('\nRecent Users (last 7 days):');
    final recentUsers =
        db.query(RangeQuery('createdAt', now.subtract(Duration(days: 7)), now));
    await recentUsers.forEach(
        (user) => print('${user['name']} joined on ${user['createdAt']}'));

    // String range query
    print('\nNames A-M:');
    final aToM = db.query(RangeQuery('name', 'A', 'M'));
    print(await aToM.map((u) => u['name']).join(', '));

    // ──────────────── UPDATE OPERATION ────────────────
    print('\n── Updating Record ──');
    await db.put('user1', {
      ...user1!,
      'age': 29,
      'tags': ['admin', 'verified', 'premium']
    });
    print('Updated user1 age to 29');

    // ──────────────── DELETE OPERATION ────────────────
    print('\n── Deleting Record ──');
    await db.delete('user3');
    final deletedUser = await db.get('user3');
    print('User3 exists after deletion: ${deletedUser != null}');
  } catch (e) {
    print('Operation failed: $e');
  } finally {
    await db.close();
    print('\nDatabase closed');
  }
}

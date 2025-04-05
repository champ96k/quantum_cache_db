// import 'package:quantum_cache_db/src/core/query/quantum_query_engine.dart';
// import 'package:quantum_cache_db/src/models/collection/collection.dart';
// import 'package:quantum_cache_db/src/models/document/document.dart';

// void main() async {
//   final queryEngine = QuantumQueryEngine();
//   final users = QuantumCollection(
//     name: 'users',
//     queryEngine: queryEngine,
//   );

//   // Create index
//   users.createIndex('age');
//   queryEngine.createRangeIndex('users', 'age');

//   // Add documents
//   await users.set(QuantumDocument(
//     id: 'user1',
//     data: {'name': 'Alice', 'age': 30},
//   ));

//   await users.set(QuantumDocument(
//     id: 'user2',
//     data: {'name': 'Bob', 'age': 25},
//   ));

//   // Query examples
//   print('All users:');
//   users.getAll().forEach((user) => print('- ${user.data['name']}'));

//   print('\nUsers aged 30:');
//   users
//       .findByIndex('age', 30)
//       .forEach((user) => print('- ${user.data['name']}'));

//   // Listen to changes
//   users.changes.listen((event) {
//     print('\nChange detected: $event');
//   });

//   // Update a document
//   await users.set(QuantumDocument(
//     id: 'user1',
//     data: {'name': 'Alice Smith', 'age': 31},
//   ));

//   await users.close();
// }

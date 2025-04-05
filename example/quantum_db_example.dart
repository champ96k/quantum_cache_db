// import 'package:quantum_cache_db/src/core/query/quantum_query_engine.dart';
// import 'package:quantum_cache_db/src/core/query/query_condition.dart';
// import 'package:quantum_cache_db/src/models/document/document.dart';

// void main() async {
//   // Initialize components
//   final queryEngine = QuantumQueryEngine();
//   const collectionName = 'users';

//   // Create indexes
//   queryEngine.createIndex(collectionName, 'name');
//   queryEngine.createRangeIndex(collectionName, 'age');
//   queryEngine.createIndex(collectionName, 'status');

//   // Create sample documents
//   final documents = [
//     QuantumDocument(
//       id: 'user1',
//       data: {'name': 'Alice', 'age': 30, 'status': 'active'},
//     ),
//     QuantumDocument(
//       id: 'user2',
//       data: {'name': 'Bob', 'age': 25, 'status': 'pending'},
//     ),
//     QuantumDocument(
//       id: 'user3',
//       data: {'name': 'Charlie', 'age': 35, 'status': 'active'},
//     ),
//   ];

//   // Index all documents
//   print('Indexing documents...');
//   for (final doc in documents) {
//     queryEngine.indexDocument(collectionName, doc);
//     print('- Indexed ${doc.id}');
//   }

//   // Query examples
//   print('\nQuery 1: Active users');
//   final activeUsers = queryEngine.findWhere(collectionName, [
//     QueryCondition(field: 'status', value: 'active'),
//   ]);
//   printResults(activeUsers);

//   print('\nQuery 2: Users aged 25-30');
//   final age25to30 = queryEngine.findWhere(collectionName, [
//     QueryCondition(field: 'age', greaterOrEqual: 25, lessOrEqual: 30),
//   ]);
//   printResults(age25to30);

//   print('\nQuery 3: Active users over 30');
//   final activeOver30 = queryEngine.findWhere(collectionName, [
//     QueryCondition(field: 'status', value: 'active'),
//     QueryCondition(field: 'age', greaterThan: 30),
//   ]);
//   printResults(activeOver30);
// }

// void printResults(Set<String> docIds) {
//   if (docIds.isEmpty) {
//     print('No results found');
//     return;
//   }

//   for (final id in docIds) {
//     print('- Found document: $id');
//   }
// }

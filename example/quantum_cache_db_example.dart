import 'package:quantum_cache_db/quantum_cache_db.dart';

void main() async {
  // Initialize Database with an Encryption Key
  QuantumCacheDB db = QuantumCacheDB("my_database.db", "mySecretKey");

  // Wait for the database to initialize
  await db.init();

  print("🔥 Database Initialized!");

  // Insert a document into the "users" collection
  await db.collection("users").doc("123").set({
    "name": "Alice",
    "age": 30,
    "city": "New York",
  });

  print("✅ Document Added!");

  // Retrieve the document
  Map<String, dynamic>? user = db.collection("users").doc("123").get();
  print("📌 Retrieved User Data: $user");

  // Query users where age > 25
  List<Map<String, dynamic>> users =
      db.collection("users").where("age", ">", 25).get([
    {"name": "Alice", "age": 30},
    {"name": "Bob", "age": 22},
    {"name": "Charlie", "age": 35}
  ]);

  print("🔍 Users older than 25: $users");
}

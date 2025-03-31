// # Database core logic
import 'dart:async';
import 'dart:isolate';
import 'package:quantum_cache_db/src/core/indexing.dart';

class QuantumQueryEngine {
  final Index _index = Index();

  /// Inserts an index for a document field.
  void indexField(
      String collection, String field, dynamic value, String docId) {
    if (value == null || value is! Comparable) {
      print(
          "⚠️ Skipping indexing for '$field' as it is null or not comparable.");
      return; // Skip indexing if value is null or not comparable
    }
    _index.insert(collection, field, value, docId);
  }

  /// Runs a query in a separate Isolate (background thread).
  Future<List<String>> runQuery(dynamic key) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_queryWorker, [receivePort.sendPort, key, _index]);
    return await receivePort.first;
  }

  /// Worker function for running queries in an Isolate.
  static void _queryWorker(List<dynamic> args) {
    SendPort sendPort = args[0];
    dynamic key = args[1];
    String collection = args[2];
    String field = args[3];
    Index index = args[4];

    // Ensure the key exists before trying to get it
    String? result = index.get(collection, field, key);

    // Send back the result (List of String)
    sendPort.send(result != null ? [result] : []);
  }
}

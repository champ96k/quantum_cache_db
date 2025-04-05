import 'package:quantum_cache_db/src/models/collection/event_type.dart';
import 'package:quantum_cache_db/src/models/document/document.dart';

/// Unique event type for collection changes
class CollectionEvent {
  final EventType type;
  final String collection;
  final String? documentId;
  final QuantumDocument? document;

  CollectionEvent({
    required this.type,
    required this.collection,
    this.documentId,
    this.document,
  });

  @override
  String toString() {
    return 'CollectionEvent[${type.name.toUpperCase()}] '
        'collection: $collection, '
        'document: ${documentId ?? document?.id}';
  }
}

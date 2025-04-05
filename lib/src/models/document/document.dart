import 'dart:convert';

/// A unique document model for QuantumCacheDB with advanced metadata handling
class QuantumDocument {
  final String id;
  final Map<String, dynamic> data;
  final Map<String, dynamic> _metadata;
  static const _reservedFields = {
    '_id',
    '_createdAt',
    '_updatedAt',
    '_version'
  };

  QuantumDocument({
    required this.id,
    Map<String, dynamic> data = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
    int version = 1,
  })  : data = Map.from(data),
        _metadata = {
          '_createdAt': createdAt ?? DateTime.now(),
          '_updatedAt': updatedAt ?? DateTime.now(),
          '_version': version,
        } {
    _validateFieldNames();
  }

  factory QuantumDocument.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return QuantumDocument(
      id: map['_id'] as String,
      data: Map.from(map)..removeWhere((k, _) => _reservedFields.contains(k)),
      createdAt: DateTime.parse(map['_createdAt'] as String),
      updatedAt: DateTime.parse(map['_updatedAt'] as String),
      version: map['_version'] as int,
    );
  }

  String toJson() {
    return jsonEncode({
      '_id': id,
      ...data,
      '_createdAt': _metadata['_createdAt'].toIso8601String(),
      '_updatedAt': _metadata['_updatedAt'].toIso8601String(),
      '_version': _metadata['_version'],
    });
  }

  void _validateFieldNames() {
    for (final field in data.keys) {
      if (field.startsWith('_') && !_reservedFields.contains(field)) {
        throw ArgumentError('Field names cannot start with underscore: $field');
      }
    }
  }
}

class Query {
  final String collection;
  String? field;
  String? operator;
  dynamic value;

  Query(this.collection);

  /// Adds a filter condition
  Query where(String field, String operator, dynamic value) {
    this.field = field;
    this.operator = operator;
    this.value = value;
    return this;
  }

  /// Executes the query
  List<Map<String, dynamic>> get(List<Map<String, dynamic>> docs) {
    if (field == null || operator == null) return docs;

    return docs.where((doc) {
      if (!doc.containsKey(field)) return false;
      dynamic fieldValue = doc[field];

      switch (operator) {
        case '==':
          return fieldValue == value;
        case '!=':
          return fieldValue != value;
        case '>':
          return fieldValue is Comparable && fieldValue.compareTo(value) > 0;
        case '>=':
          return fieldValue is Comparable && fieldValue.compareTo(value) >= 0;
        case '<':
          return fieldValue is Comparable && fieldValue.compareTo(value) < 0;
        case '<=':
          return fieldValue is Comparable && fieldValue.compareTo(value) <= 0;
        default:
          return false;
      }
    }).toList();
  }
}

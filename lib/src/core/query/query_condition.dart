class QueryCondition {
  final String field;
  final dynamic value;
  final dynamic greaterThan;
  final dynamic lessThan;
  final dynamic greaterOrEqual;
  final dynamic lessOrEqual;

  QueryCondition({
    required this.field,
    this.value,
    this.greaterThan,
    this.lessThan,
    this.greaterOrEqual,
    this.lessOrEqual,
  }) : assert(value != null ||
            greaterThan != null ||
            lessThan != null ||
            greaterOrEqual != null ||
            lessOrEqual != null);

  bool get isRangeQuery =>
      greaterThan != null ||
      lessThan != null ||
      greaterOrEqual != null ||
      lessOrEqual != null;
}

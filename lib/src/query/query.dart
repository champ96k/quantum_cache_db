enum QueryType { exact, range }

abstract class Query {
  final QueryType type;
  const Query(this.type);
}

class ExactQuery extends Query {
  final String key;
  const ExactQuery(this.key) : super(QueryType.exact);
}

class RangeQuery extends Query {
  final String field;
  final dynamic min;
  final dynamic max;
  const RangeQuery(this.field, this.min, this.max) : super(QueryType.range);
}

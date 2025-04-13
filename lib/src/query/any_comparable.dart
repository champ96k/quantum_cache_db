abstract class AnyComparable implements Comparable<AnyComparable> {
  final dynamic value;

  const AnyComparable(this.value);

  factory AnyComparable.from(dynamic value) {
    if (value is num) return NumberComparable(value);
    if (value is String) return StringComparable(value);
    if (value is bool) return BoolComparable(value);
    if (value is DateTime) return DateTimeComparable(value);
    throw ArgumentError('Unsupported type: ${value.runtimeType}');
  }

  @override
  int compareTo(AnyComparable other);
}

class NumberComparable extends AnyComparable {
  const NumberComparable(num super.value);

  @override
  int compareTo(AnyComparable other) =>
      (value as num).compareTo(other.value as num);
}

class StringComparable extends AnyComparable {
  const StringComparable(String super.value);

  @override
  int compareTo(AnyComparable other) =>
      (value as String).compareTo(other.value as String);
}

class BoolComparable extends AnyComparable {
  const BoolComparable(bool super.value);

  @override
  int compareTo(AnyComparable other) {
    final a = value as bool;
    final b = other.value as bool;
    return a == b
        ? 0
        : a
            ? 1
            : -1;
  }
}

class DateTimeComparable extends AnyComparable {
  const DateTimeComparable(DateTime super.value);

  @override
  int compareTo(AnyComparable other) {
    final otherDate = other.value as DateTime;
    return (value as DateTime).compareTo(otherDate);
  }
}

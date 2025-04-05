import 'dart:async';

/// Simple lock implementation for mutual exclusion
class Lock {
  Future<void> _lock = Future.value();

  Future<T> synchronized<T>(FutureOr<T> Function() computation) async {
    final previous = _lock;
    final completer = Completer<void>();
    _lock = completer.future;

    await previous;
    try {
      return await computation();
    } finally {
      completer.complete();
    }
  }
}

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:quantum_cache_db/quantum_cache_db.dart';

class IsolatePool {
  final List<Isolate> _isolates = [];
  final List<SendPort> _ports = [];
  final ReceivePort _mainReceive = ReceivePort();
  int _nextOperationId = 0;
  final Map<int, Completer<dynamic>> _pendingOperations = {};

  Future<void> initialize(int poolSize) async {
    for (var i = 0; i < poolSize; i++) {
      final receive = ReceivePort();
      final isolate = await Isolate.spawn(
        _isolateEntry,
        receive.sendPort,
        errorsAreFatal: true,
        debugName: 'DBIsolate_$i',
      );
      _isolates.add(isolate);

      final completer = Completer<SendPort>();
      receive.listen((message) {
        if (message is SendPort) {
          completer.complete(message);
        } else if (message is Map<String, dynamic>) {
          _handleIsolateResponse(message);
        }
      });

      final sendPort = await completer.future;
      _ports.add(sendPort);
    }
  }

  void _handleIsolateResponse(Map<String, dynamic> response) {
    final completer = _pendingOperations.remove(response['id']);
    if (response.containsKey('error')) {
      completer?.completeError(response['error']);
    } else {
      completer?.complete(response['result']);
    }
  }

  static void _isolateEntry(SendPort mainSendPort) {
    final receive = ReceivePort();
    mainSendPort.send(receive.sendPort);

    receive.listen((message) async {
      if (message is Map<String, dynamic>) {
        try {
          final operation = message['operation'];
          final params = message['params'];

          // Supported operations
          dynamic result;
          switch (operation) {
            case 'encode':
              result = BinaryCodec().encode(params);
              break;
            case 'decode':
              result = BinaryCodec().decode(params as Uint8List);
              break;
            default:
              throw UnsupportedError('Unknown operation: $operation');
          }

          mainSendPort.send({
            'id': message['id'],
            'result': result,
          });
        } catch (e) {
          mainSendPort.send({
            'id': message['id'],
            'error': e.toString(),
          });
        }
      }
    });
  }

  Future<dynamic> _execute(String operation, dynamic params) async {
    final completer = Completer<dynamic>();
    final id = _nextOperationId++;
    _pendingOperations[id] = completer;

    final sendPort = _ports.removeLast();
    sendPort.send({
      'id': id,
      'operation': operation,
      'params': params,
    });

    _ports.add(sendPort);
    return completer.future;
  }

  Future<Uint8List> encode(dynamic value) async {
    return await _execute('encode', value);
  }

  Future<dynamic> decode(Uint8List data) async {
    return await _execute('decode', data);
  }

  Future<void> dispose() async {
    for (final isolate in _isolates) {
      isolate.kill();
    }
    _mainReceive.close();
  }
}

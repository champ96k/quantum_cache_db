import 'dart:io';
import 'dart:convert';
import 'dart:async';

class WriteAheadLog {
  final String logPath;
  late IOSink _logSink;
  bool _isClosed = false;
  late StreamController<String> _writeQueue;

  WriteAheadLog(this.logPath) {
    _initializeLogSink();
    _writeQueue = StreamController<String>();
    _writeQueue.stream.listen((logEntry) async {
      // Ensure only one write operation is performed at a time
      if (!_isClosed) {
        try {
          _logSink.writeln(logEntry);
          await _logSink.flush();
        } catch (e) {
          // print('Error during write: $e');
        }
      }
    });
  }

  void _initializeLogSink() {
    final logFile = File(logPath);

    if (logFile.existsSync()) {
      _logSink = logFile.openWrite(mode: FileMode.append);
    } else {
      _logSink = logFile.openWrite(mode: FileMode.writeOnly);
    }
  }

  Future<void> logWrite(String operation, String key, dynamic value) async {
    if (_isClosed) {
      throw StateError("Cannot write to a closed Write-Ahead Log.");
    }

    final logEntry = jsonEncode({
      'op': operation,
      'key': key,
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Add the log entry to the queue for asynchronous processing
    _writeQueue.add(logEntry);
  }

  Future<List<Map<String, dynamic>>> readLogs() async {
    final logFile = File(logPath);
    if (!await logFile.exists()) return [];

    final lines = await logFile.readAsLines();
    return lines
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
  }

  Future<void> clearLogs() async {
    final logFile = File(logPath);
    await logFile.writeAsString('');
  }

  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;

    await _writeQueue.close();
    await _logSink.flush();
    await _logSink.close();
  }
}

// # Write-Ahead Logging
import 'dart:io';
import 'dart:convert';

class WriteAheadLog {
  final String logPath;
  late IOSink _logSink;

  WriteAheadLog(this.logPath) {
    final logFile = File(logPath);
    _logSink = logFile.openWrite(mode: FileMode.append);
  }

  void logWrite(String operation, String key, dynamic value) {
    final logEntry = jsonEncode({
      'op': operation,
      'key': key,
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _logSink.writeln(logEntry);
    _logSink.flush();
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

  void close() {
    _logSink.close();
  }
}

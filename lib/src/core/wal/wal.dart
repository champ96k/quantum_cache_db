// ignore_for_file: prefer_final_fields

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:quantum_cache_db/src/core/wal/lock.dart';
import 'package:quantum_cache_db/src/error/write_ahead_log_exception.dart';

class WriteAheadLog {
  final String logPath;
  final StreamController<List<dynamic>> _operationQueue;
  bool _isClosed = false;
  final _operationLock = Lock();
  final int maxLogSize;
  final int batchSize;
  final List<List<dynamic>> _currentBatch = [];
  Timer? _batchTimer;
  Completer<void> _initCompleter = Completer<void>();
  RandomAccessFile? _logFile;
  bool _isProcessing = false;

  WriteAheadLog(
    this.logPath, {
    this.maxLogSize = 1024 * 1024,
    this.batchSize = 16,
  }) : _operationQueue = StreamController<List<dynamic>>() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _operationLock.synchronized(() async {
        final file = File(logPath);
        _logFile = await file.open(mode: FileMode.writeOnlyAppend);

        _operationQueue.stream.listen((operation) {
          _currentBatch.add(operation);
          _maybeProcessBatch();
        }, onDone: () async {
          if (!_isClosed) await close();
        }, onError: _handleError);

        if (await file.length() > 0) {
          await _recover();
        }
        _initCompleter.complete();
      });
    } catch (e) {
      _initCompleter.completeError(e);
      throw WriteAheadLogException('Failed to initialize WAL: ${e.toString()}');
    }
  }

  void _maybeProcessBatch() {
    if (_isProcessing || _isClosed) return;

    if (_currentBatch.length >= batchSize) {
      _processBatch();
    } else {
      _batchTimer ??= Timer(const Duration(milliseconds: 10), () {
        _batchTimer = null;
        if (_currentBatch.isNotEmpty && !_isProcessing) {
          _processBatch();
        }
      });
    }
  }

  Future<void> _processBatch() async {
    if (_isClosed || _currentBatch.isEmpty || _isProcessing) return;
    _isProcessing = true;

    final batch = List<List<dynamic>>.from(_currentBatch);
    _currentBatch.clear();

    try {
      batch.sort((a, b) => (a[1] as int).compareTo(b[1] as int));

      await _operationLock.synchronized(() async {
        if (_logFile == null) return;

        for (final entry in batch) {
          await _logFile!.writeString('${entry[0]}\n');
        }
        await _logFile!.flush();

        if (await _logFile!.length() > maxLogSize) {
          await _compact();
        }
      });
    } catch (e) {
      _handleError(e);
    } finally {
      _isProcessing = false;
      if (_currentBatch.isNotEmpty) {
        _maybeProcessBatch();
      }
    }
  }

  Future<void> logWrite(String operation, String key, dynamic value) async {
    if (_isClosed) throw WriteAheadLogException('WAL is closed');

    final entry = {
      'op': operation,
      'key': key,
      'value': value,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'crc': _calculateCrc(operation, key, value),
    };

    await _operationLock.synchronized(() async {
      if (!_operationQueue.isClosed) {
        _operationQueue.add([jsonEncode(entry), entry['ts']]);
      }
    });
  }

  Future<void> _recover() async {
    final tempPath = '$logPath.tmp';
    final tempFile = File(tempPath);

    try {
      // Create temp file only if it doesn't exist
      if (!await tempFile.exists()) {
        await tempFile.create();
      }

      final lines = await _readLogLines();
      for (final line in lines) {
        try {
          final entry = jsonDecode(line) as Map<String, dynamic>;
          if (_validateEntry(entry)) {
            await tempFile.writeAsString('$line\n', mode: FileMode.append);
          }
        } catch (_) {}
      }

      await _logFile?.close();
      await tempFile.rename(logPath);
      _logFile = await File(logPath).open(mode: FileMode.writeOnlyAppend);
    } catch (e) {
      // Don't throw if temp file doesn't exist
      if (e is! PathNotFoundException) {
        rethrow;
      }
    } finally {
      // Only try to delete if file exists
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<List<String>> _readLogLines() async {
    final file = File(logPath);
    if (!await file.exists()) return [];

    return await file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();
  }

  Future<void> _compact() async {
    final tempPath = '$logPath.tmp';
    final tempFile = File(tempPath);

    try {
      if (!await tempFile.exists()) {
        await tempFile.create();
      }

      final lines = await _readLogLines();
      var lastValidPos = 0;

      for (final line in lines) {
        try {
          final entry = jsonDecode(line) as Map<String, dynamic>;
          if (_validateEntry(entry)) {
            await tempFile.writeAsString('$line\n', mode: FileMode.append);
            lastValidPos += line.length + 1;
          }
        } catch (_) {}
      }

      final currentSize = await _logFile?.length() ?? 0;
      if (lastValidPos < currentSize) {
        await _logFile?.truncate(lastValidPos);
      }
    } finally {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  bool _validateEntry(Map<String, dynamic> entry) {
    try {
      return _calculateCrc(
            entry['op'] as String,
            entry['key'] as String,
            entry['value'],
          ) ==
          entry['crc'];
    } catch (e) {
      return false;
    }
  }

  int _calculateCrc(String op, String key, dynamic value) {
    return '$op$key$value'.hashCode;
  }

  void _handleError(dynamic error) {
    if (!_operationQueue.isClosed) {
      _operationQueue.addError(error);
    }
  }

  Future<void> flush() async {
    await _initCompleter.future;
    if (_isClosed || _logFile == null) return;

    await _operationLock.synchronized(() async {
      if (_currentBatch.isNotEmpty) {
        await _processBatch();
      }
      await _logFile!.flush();
    });
  }

  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;

    await _operationLock.synchronized(() async {
      _batchTimer?.cancel();
      try {
        if (!_operationQueue.isClosed) {
          await _operationQueue.close();
        }
        await flush();
        await _logFile?.close();
      } catch (e) {
        _handleError(e);
      }
    });
  }
}

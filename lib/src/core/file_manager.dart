// # File system operations

import 'dart:io';
import 'dart:typed_data';

class FileManager {
  final String _path;
  RandomAccessFile? _file;
  int _logicalSize = 0;

  FileManager(this._path);

  Future<void> initialize() async {
    final file = File(_path);
    final exists = await file.exists();

    _file = await file.open(mode: FileMode.append);
    _logicalSize = await _file!.length();

    if (!exists) {
      // Initialize with empty header if new file
      await _file!.writeFrom(Uint8List(128));
      _logicalSize = 128;
    }
  }

  Future<Uint8List> get activeFile async {
    if (_file == null) throw StateError('File not initialized');
    await _file!.setPosition(0);
    return await _file!.read(_logicalSize);
  }

  Future<int> append(Uint8List data) async {
    final position = _logicalSize;
    await _file!.setPosition(position);
    await _file!.writeFrom(data);
    _logicalSize += data.length;
    return position;
  }

  Future<void> close() async {
    await _file?.close();
    _file = null;
  }

  Future<int> get length async => _logicalSize;
  String get path => _path;

  Future<Uint8List> readPage(int pageNumber) async {
    const pageSize = 4096;
    final start = pageNumber * pageSize;
    if (start >= _logicalSize) return Uint8List(0);

    final end = start + pageSize;
    final length = (end > _logicalSize) ? _logicalSize - start : pageSize;
    await _file!.setPosition(start);
    return await _file!.read(length);
  }
}

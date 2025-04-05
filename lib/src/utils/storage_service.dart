import 'dart:io';

class StorageService {
  final String _dbPath;
  RandomAccessFile? _file;

  StorageService(this._dbPath);

  Future<void> initialize() async {
    _file = await File(_dbPath).open(mode: FileMode.append);
  }

  Future<void> saveData(String data) async {
    await _file?.writeString(data);
    await _file?.flush();
  }

  Future<String?> loadData() async {
    final file = File(_dbPath);
    if (!await file.exists()) return null;
    return await file.readAsString();
  }

  Future<void> close() async {
    await _file?.close();
  }
}

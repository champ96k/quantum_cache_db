import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'storage_interface.dart';

class FlutterStorage implements StorageInterface {
  @override
  Future<String> getApplicationDocumentsDirectory() async {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  @override
  Future<bool> directoryExists(String path) async {
    return await Directory(path).exists();
  }

  @override
  Future<void> createDirectory(String path, {bool recursive = false}) async {
    await Directory(path).create(recursive: recursive);
  }

  @override
  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  @override
  Future<String> readFileAsString(String path) async {
    return await File(path).readAsString();
  }

  @override
  Future<void> writeFileAsString(String path, String contents) async {
    await File(path).writeAsString(contents);
  }

  @override
  Future<void> deleteFile(String path) async {
    await File(path).delete();
  }
}

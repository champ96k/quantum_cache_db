import 'dart:io';
import 'package:path/path.dart' as path;
import 'storage_interface.dart';

class DartStorage implements StorageInterface {
  @override
  Future<String> getApplicationDocumentsDirectory() async {
    // For pure Dart, use a dedicated directory in the user's home directory
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    final dbDir = path.join(homeDir, '.quantum_cache');

    // Create the directory if it doesn't exist
    if (!await Directory(dbDir).exists()) {
      await Directory(dbDir).create(recursive: true);
    }

    return dbDir;
  }

  @override
  Future<bool> directoryExists(String path) async {
    final exists = await Directory(path).exists();
    print('Directory exists check: $path -> $exists');
    return exists;
  }

  @override
  Future<void> createDirectory(String path, {bool recursive = false}) async {
    print('Creating directory: $path (recursive: $recursive)');
    await Directory(path).create(recursive: recursive);
  }

  @override
  Future<bool> fileExists(String path) async {
    final exists = await File(path).exists();
    print('File exists check: $path -> $exists');
    return exists;
  }

  @override
  Future<String> readFileAsString(String path) async {
    print('Reading file: $path');
    final content = await File(path).readAsString();
    print('File content: $content');
    return content;
  }

  @override
  Future<void> writeFileAsString(String path, String contents) async {
    print('Writing to file: $path');
    print('Content to write: $contents');
    await File(path).writeAsString(contents);
  }

  @override
  Future<void> deleteFile(String path) async {
    print('Deleting file: $path');
    await File(path).delete();
  }
}

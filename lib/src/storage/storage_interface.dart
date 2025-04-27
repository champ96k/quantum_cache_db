abstract class StorageInterface {
  Future<String> getApplicationDocumentsDirectory();
  Future<bool> directoryExists(String path);
  Future<void> createDirectory(String path, {bool recursive = false});
  Future<bool> fileExists(String path);
  Future<String> readFileAsString(String path);
  Future<void> writeFileAsString(String path, String contents);
  Future<void> deleteFile(String path);
}

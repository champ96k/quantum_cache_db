import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'dart:typed_data';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// The main database class that handles all core operations
class QuantumCacheDB {
  final String _dbName;
  late final Directory _dbDirectory;
  final Mutex _writeMutex = Mutex();

  /// Page size in bytes (4KB)
  static const int pageSize = 4096;

  /// Cache size in pages (default 1000 pages = ~4MB)
  static const int defaultCacheSize = 1000;

  /// Memory-mapped file for the main data file
  late final RandomAccessFile _dataFile;

  /// Cache for frequently accessed pages
  final Map<int, Uint8List> _pageCache = {};

  /// Queue for background operations
  final Queue<Future<void>> _backgroundQueue = Queue();

  QuantumCacheDB(this._dbName);

  /// Initialize the database
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _dbDirectory = Directory(path.join(appDir.path, _dbName));

    if (!await _dbDirectory.exists()) {
      await _dbDirectory.create(recursive: true);
    }

    final dataFilePath = path.join(_dbDirectory.path, 'data.qcdb');
    _dataFile = await File(dataFilePath).open(mode: FileMode.append);
  }

  /// Write data to the database
  Future<void> write(Uint8List data) async {
    await _writeMutex.protect(() async {
      await _dataFile.writeFrom(data);
      await _dataFile.flush();
    });
  }

  /// Read data from the database
  Future<Uint8List> read(int offset, int length) async {
    final pageNumber = offset ~/ pageSize;
    final pageOffset = offset % pageSize;

    // Check cache first
    if (_pageCache.containsKey(pageNumber)) {
      final page = _pageCache[pageNumber]!;
      return page.sublist(pageOffset, pageOffset + length);
    }

    // Read from file and cache
    await _dataFile.setPosition(offset);
    final buffer = await _dataFile.read(length);
    _cachePage(pageNumber, buffer);

    return buffer;
  }

  /// Cache a page in memory
  void _cachePage(int pageNumber, Uint8List data) {
    if (_pageCache.length >= defaultCacheSize) {
      // Simple LRU eviction - remove first entry
      _pageCache.remove(_pageCache.keys.first);
    }
    _pageCache[pageNumber] = data;
  }

  /// Close the database
  Future<void> close() async {
    await _dataFile.close();
  }
}

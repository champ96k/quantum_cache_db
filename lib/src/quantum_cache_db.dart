import 'dart:async';
import 'dart:convert';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'storage/storage_interface.dart';
import 'storage/dart_storage.dart';

/// The main database class that handles all operations
class QuantumCacheDB {
  final String _dbName;
  String _dbPath = '';
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, StreamController<dynamic>> _streamControllers = {};
  final Mutex _mutex = Mutex();
  bool _isInitialized = false;
  final StorageInterface _storage;
  final List<StreamSubscription> _subscriptions = [];
  final Completer<void> _initializationCompleter = Completer<void>();

  /// Creates a new instance of QuantumCacheDB
  /// [dbName] is the name of the database (defaults to 'quantum_cache')
  /// [storage] is the storage implementation to use (defaults to DartStorage)
  QuantumCacheDB({
    String dbName = 'quantum_cache',
    StorageInterface? storage,
  })  : _dbName = dbName,
        _storage = storage ?? DartStorage() {
    print('QuantumCacheDB initialized with dbName: $dbName');
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) {
      _initializationCompleter.complete();
      return;
    }

    print('Initializing database...');
    try {
      final appDir = await _storage.getApplicationDocumentsDirectory();
      _dbPath = path.join(appDir, _dbName);
      print('Database path: $_dbPath');

      // Create database directory if it doesn't exist
      if (!await _storage.directoryExists(_dbPath)) {
        print('Creating database directory...');
        await _storage.createDirectory(_dbPath, recursive: true);
      }

      _isInitialized = true;
      _initializationCompleter.complete();
      print('Database initialized successfully');
    } catch (e, stackTrace) {
      print('Error initializing database: $e');
      print('Stack trace: $stackTrace');
      _initializationCompleter.completeError(e, stackTrace);
      rethrow;
    }
  }

  /// Sets a value for a given key
  Future<void> set(String key, dynamic value) async {
    print('Setting value for key: $key');
    try {
      await _initializationCompleter.future;
      await _mutex.protect(() async {
        // Update memory cache
        _memoryCache[key] = value;
        print('Updated memory cache for key: $key');

        // Write to file
        final filePath = path.join(_dbPath, _encodeKey(key));
        print('Writing to file: $filePath');
        await _storage.writeFileAsString(filePath, jsonEncode(value));

        // Notify listeners
        _notifyListeners(key, value);
      });
    } catch (e, stackTrace) {
      print('Error setting value: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Gets a value for a given key
  Future<dynamic> get(String key) async {
    print('Getting value for key: $key');
    try {
      await _initializationCompleter.future;
      // Check memory cache first
      if (_memoryCache.containsKey(key)) {
        print('Found in memory cache: ${_memoryCache[key]}');
        return _memoryCache[key];
      }

      // Read from file
      final filePath = path.join(_dbPath, _encodeKey(key));
      print('Reading from file: $filePath');
      if (!await _storage.fileExists(filePath)) {
        print('File does not exist');
        return null;
      }

      final content = await _storage.readFileAsString(filePath);
      final value = jsonDecode(content);
      print('Retrieved value: $value');

      // Update memory cache
      _memoryCache[key] = value;

      return value;
    } catch (e, stackTrace) {
      print('Error getting value: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Updates a value for a given key
  Future<void> update(String key, Map<String, dynamic> updates) async {
    print('Updating value for key: $key');
    try {
      await _initializationCompleter.future;
      await _mutex.protect(() async {
        print('Acquired mutex for update operation');

        // Get current value
        final currentValue = await get(key);
        if (currentValue == null) {
          throw Exception('Key $key does not exist');
        }

        if (currentValue is! Map) {
          throw Exception('Cannot update non-map value');
        }

        // Create updated value
        final updatedValue = Map<String, dynamic>.from(currentValue)
          ..addAll(updates);
        print('Updated value: $updatedValue');

        // Update memory cache
        _memoryCache[key] = updatedValue;
        print('Updated memory cache for key: $key');

        // Write to file
        final filePath = path.join(_dbPath, _encodeKey(key));
        print('Writing to file: $filePath');
        await _storage.writeFileAsString(filePath, jsonEncode(updatedValue));

        // Notify listeners
        _notifyListeners(key, updatedValue);
        print('Completed update operation');
      });
    } catch (e, stackTrace) {
      print('Error updating value: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Deletes a value for a given key
  Future<void> delete(String key) async {
    print('Deleting value for key: $key');
    try {
      await _initializationCompleter.future;
      await _mutex.protect(() async {
        // Remove from memory cache
        _memoryCache.remove(key);
        print('Removed from memory cache');

        // Delete file
        final filePath = path.join(_dbPath, _encodeKey(key));
        if (await _storage.fileExists(filePath)) {
          print('Deleting file: $filePath');
          await _storage.deleteFile(filePath);
        }

        // Notify listeners
        _notifyListeners(key, null);
      });
    } catch (e, stackTrace) {
      print('Error deleting value: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Listens to changes for a given key
  Stream<dynamic> on(String key) {
    print('Setting up listener for key: $key');
    if (!_streamControllers.containsKey(key)) {
      _streamControllers[key] = StreamController<dynamic>.broadcast();
    }
    return _streamControllers[key]!.stream;
  }

  /// Closes the database and cleans up resources
  Future<void> close() async {
    print('Closing database...');
    try {
      // Cancel all subscriptions
      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();

      // Close all stream controllers
      for (final controller in _streamControllers.values) {
        await controller.close();
      }
      _streamControllers.clear();

      // Clear memory cache
      _memoryCache.clear();

      print('Database closed successfully');
    } catch (e, stackTrace) {
      print('Error closing database: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Encodes a key to a safe filename
  String _encodeKey(String key) {
    final encoded = const Uuid().v5(Uuid.NAMESPACE_URL, key);
    print('Encoded key: $key -> $encoded');
    return encoded;
  }

  /// Notifies all listeners of a change
  void _notifyListeners(String key, dynamic value) {
    print('Notifying listeners for key: $key');
    if (_streamControllers.containsKey(key)) {
      _streamControllers[key]!.add(value);
    }
  }
}

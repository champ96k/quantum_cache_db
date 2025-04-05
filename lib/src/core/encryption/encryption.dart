import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart';
import 'package:quantum_cache_db/src/error/encryption_exception.dart';

/// Handles AES-256 encryption/decryption with CBC mode and PKCS7 padding
class Encryption {
  static const _ivLength = 16;
  static const _keyLength = 32; // 256-bit
  final Uint8List _key;
  final Uint8List _iv;

  /// Creates an encryption handler with a passphrase
  /// [passphrase] will be hashed using SHA-256 to create a 256-bit key
  Encryption(String passphrase)
      : _key = _deriveKey(passphrase),
        _iv = _generateIV() {
    _validateKeyAndIV();
  }

  /// Encrypts a string and returns base64-encoded result
  String encrypt(String plaintext) {
    try {
      final cipher = _createCipher(true);
      final paddedText = _padData(plaintext);
      final encrypted = cipher.process(paddedText);
      return base64Encode(encrypted);
    } catch (e) {
      throw EncryptionException('Encryption failed: ${e.toString()}');
    }
  }

  /// Decrypts a base64-encoded string
  String decrypt(String ciphertext) {
    try {
      final cipher = _createCipher(false);
      final encrypted = base64Decode(ciphertext);
      final decrypted = cipher.process(encrypted);
      return _unpadData(decrypted);
    } catch (e) {
      throw EncryptionException('Decryption failed: ${e.toString()}');
    }
  }

  static Uint8List _deriveKey(String passphrase) {
    // Create SHA-256 hash of the passphrase
    final hash = crypto.sha256.convert(utf8.encode(passphrase)).bytes;

    // If hash is shorter than required, extend it with additional hashing
    if (hash.length < _keyLength) {
      final extended = Uint8List(_keyLength);
      extended.setRange(0, hash.length, hash);
      extended.setRange(
          hash.length,
          _keyLength,
          crypto.sha256
              .convert(hash)
              .bytes
              .sublist(0, _keyLength - hash.length));
      return extended;
    }

    return Uint8List.fromList(hash.sublist(0, _keyLength));
  }

  static Uint8List _generateIV() {
    final rng = FortunaRandom();
    final seed = Uint8List(32);
    rng.seed(KeyParameter(seed));
    return rng.nextBytes(_ivLength);
  }

  PaddedBlockCipherImpl _createCipher(bool forEncryption) {
    final cipher =
        PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()));
    cipher.init(
      forEncryption,
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(_key), _iv),
        null,
      ),
    );
    return cipher;
  }

  Uint8List _padData(String data) {
    final bytes = utf8.encode(data);
    final blockSize = AESEngine().blockSize;
    final padLength = blockSize - (bytes.length % blockSize);
    final padded = Uint8List(bytes.length + padLength);
    padded.setRange(0, bytes.length, bytes);
    padded.fillRange(bytes.length, padded.length, padLength);
    return padded;
  }

  String _unpadData(Uint8List data) {
    final padLength = data.last;
    final textLength = data.length - padLength;
    return utf8.decode(data.sublist(0, textLength));
  }

  void _validateKeyAndIV() {
    if (_key.length != _keyLength) {
      throw EncryptionException('Invalid key length: ${_key.length} bytes');
    }
    if (_iv.length != _ivLength) {
      throw EncryptionException('Invalid IV length: ${_iv.length} bytes');
    }
  }
}

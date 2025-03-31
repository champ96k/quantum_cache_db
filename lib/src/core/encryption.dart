// Implement AES-256 Encryption
// We'll use PointyCastle for AES encryption.

import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart' as crypto;

class Encryption {
  final Uint8List key;
  final Uint8List iv;

  Encryption(String passphrase)
      : key = _deriveKey(passphrase),
        iv = Uint8List(16); // Fixed IV for now

  static Uint8List _deriveKey(String passphrase) {
    final hash = crypto.sha256.convert(utf8.encode(passphrase)).bytes;
    return Uint8List.fromList(hash.sublist(0, 32)); // 256-bit key
  }

  Uint8List _process(Uint8List input, bool encrypt) {
    final cipher = PaddedBlockCipher("AES/CBC/PKCS7")
      ..init(
          encrypt,
          PaddedBlockCipherParameters(
              ParametersWithIV(KeyParameter(key), iv), null));
    return cipher.process(input);
  }

  String encrypt(String plainText) {
    final encrypted =
        _process(Uint8List.fromList(utf8.encode(plainText)), true);
    return base64Encode(encrypted);
  }

  String decrypt(String encryptedText) {
    final decrypted = _process(base64Decode(encryptedText), false);
    return utf8.decode(decrypted);
  }
}

import 'package:quantum_cache_db/src/core/encryption/encryption.dart';

void main() {
  try {
    print('Encryption started');

    // Use a strong passphrase (minimum 16 characters recommended)
    const passphrase = 'my-very-secure-passphrase-1234!';
    const originalText = 'This is a secret message';

    final encryptor = Encryption(passphrase);

    print('Original text: $originalText');

    // Encrypt
    final encrypted = encryptor.encrypt(originalText);
    print('Encrypted: $encrypted');

    // Decrypt
    final decrypted = encryptor.decrypt(encrypted);
    print('Decrypted: $decrypted');

    // Verify
    if (decrypted != originalText) {
      throw Exception('Decryption failed - texts do not match');
    }

    print('Encryption test completed successfully!');
  } catch (e) {
    print('Error: $e');
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reset/core/services/backup/crypto_helper.dart';

void main() {
  group('CryptoHelper', () {
    test('generateSalt returns 16 bytes', () {
      final salt = CryptoHelper.generateSalt();
      expect(salt.length, 16);
    });

    test('generateNonce returns 12 bytes', () {
      final nonce = CryptoHelper.generateNonce();
      expect(nonce.length, 12);
    });

    test('generateSalt produces different values', () {
      final s1 = CryptoHelper.generateSalt();
      final s2 = CryptoHelper.generateSalt();
      expect(s1, isNot(equals(s2)));
    });

    test('deriveKey returns 32 bytes', () {
      final salt = CryptoHelper.generateSalt();
      final key = CryptoHelper.deriveKey('testpassword', salt);
      expect(key.length, 32);
    });

    test('deriveKey is deterministic for same password and salt', () {
      final salt = CryptoHelper.generateSalt();
      final k1 = CryptoHelper.deriveKey('mypassword', salt);
      final k2 = CryptoHelper.deriveKey('mypassword', salt);
      expect(k1, equals(k2));
    });

    test('deriveKey differs for different passwords', () {
      final salt = CryptoHelper.generateSalt();
      final k1 = CryptoHelper.deriveKey('password1', salt);
      final k2 = CryptoHelper.deriveKey('password2', salt);
      expect(k1, isNot(equals(k2)));
    });

    test('deriveKey differs for different salts', () {
      final s1 = CryptoHelper.generateSalt();
      final s2 = CryptoHelper.generateSalt();
      final k1 = CryptoHelper.deriveKey('samepassword', s1);
      final k2 = CryptoHelper.deriveKey('samepassword', s2);
      expect(k1, isNot(equals(k2)));
    });

    test('encrypt and decrypt roundtrip', () {
      final salt = CryptoHelper.generateSalt();
      final nonce = CryptoHelper.generateNonce();
      final key = CryptoHelper.deriveKey('testpass123', salt);
      final plaintext = Uint8List.fromList(utf8.encode('Hello, Daily Reset!'));

      final ciphertext = CryptoHelper.encrypt(plaintext, key, nonce);
      final decrypted = CryptoHelper.decrypt(ciphertext, key, nonce);

      expect(decrypted, equals(plaintext));
      expect(utf8.decode(decrypted), 'Hello, Daily Reset!');
    });

    test('wrong password fails to decrypt', () {
      final salt = CryptoHelper.generateSalt();
      final nonce = CryptoHelper.generateNonce();
      final key1 = CryptoHelper.deriveKey('correctpassword', salt);
      final key2 = CryptoHelper.deriveKey('wrongpassword', salt);
      final plaintext = Uint8List.fromList(utf8.encode('Secret data'));

      final ciphertext = CryptoHelper.encrypt(plaintext, key1, nonce);

      expect(
        () => CryptoHelper.decrypt(ciphertext, key2, nonce),
        throwsA(isA<Exception>()),
      );
    });

    test('wrong nonce fails to decrypt', () {
      final salt = CryptoHelper.generateSalt();
      final nonce1 = CryptoHelper.generateNonce();
      final nonce2 = CryptoHelper.generateNonce();
      final key = CryptoHelper.deriveKey('testpass', salt);
      final plaintext = Uint8List.fromList(utf8.encode('Test data'));

      final ciphertext = CryptoHelper.encrypt(plaintext, key, nonce1);

      expect(
        () => CryptoHelper.decrypt(ciphertext, key, nonce2),
        throwsA(isA<Exception>()),
      );
    });

    test('encrypted data differs from plaintext', () {
      final salt = CryptoHelper.generateSalt();
      final nonce = CryptoHelper.generateNonce();
      final key = CryptoHelper.deriveKey('testpass', salt);
      final plaintext = Uint8List.fromList(utf8.encode('AAAAAAAAAAAAAAAA'));

      final ciphertext = CryptoHelper.encrypt(plaintext, key, nonce);

      expect(ciphertext, isNot(equals(plaintext)));
    });

    test('handles empty plaintext', () {
      final salt = CryptoHelper.generateSalt();
      final nonce = CryptoHelper.generateNonce();
      final key = CryptoHelper.deriveKey('testpass', salt);
      final plaintext = Uint8List(0);

      final ciphertext = CryptoHelper.encrypt(plaintext, key, nonce);
      final decrypted = CryptoHelper.decrypt(ciphertext, key, nonce);

      expect(decrypted, equals(plaintext));
    });

    test('full backup roundtrip simulation', () {
      final salt = CryptoHelper.generateSalt();
      final nonce = CryptoHelper.generateNonce();
      final password = 'my-secure-passphrase';
      final key = CryptoHelper.deriveKey(password, salt);

      // Simulate backup data
      final backupData = jsonEncode({
        'streak': {'currentStreak': 7, 'bestStreak': 14},
        'favoriteQuotes': ['1', '5', '23'],
        'isPremium': true,
      });
      final plaintext = Uint8List.fromList(utf8.encode(backupData));

      // Encrypt
      final output = Uint8List(salt.length + nonce.length);
      output.setRange(0, salt.length, salt);
      output.setRange(salt.length, output.length, nonce);
      final ciphertext = CryptoHelper.encrypt(plaintext, key, nonce);
      final fullOutput = Uint8List(salt.length + nonce.length + ciphertext.length);
      fullOutput.setRange(0, salt.length, salt);
      fullOutput.setRange(salt.length, salt.length + nonce.length, nonce);
      fullOutput.setRange(salt.length + nonce.length, fullOutput.length, ciphertext);

      // Decrypt (simulate restore)
      final restoredSalt = fullOutput.sublist(0, 16);
      final restoredNonce = fullOutput.sublist(16, 28);
      final restoredCiphertext = fullOutput.sublist(28);
      final restoredKey = CryptoHelper.deriveKey(password, restoredSalt);
      final restoredPlaintext = CryptoHelper.decrypt(restoredCiphertext, restoredKey, restoredNonce);
      final restoredJson = jsonDecode(utf8.decode(restoredPlaintext)) as Map<String, dynamic>;

      expect(restoredJson['streak']['currentStreak'], 7);
      expect(restoredJson['favoriteQuotes'], ['1', '5', '23']);
      expect(restoredJson['isPremium'], true);
    });
  });
}
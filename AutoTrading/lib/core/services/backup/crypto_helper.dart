import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class CryptoHelper {
  static final _random = Random.secure();

  static Uint8List generateSalt() => Uint8List.fromList(List.generate(16, (_) => _random.nextInt(256)));
  static Uint8List generateNonce() => Uint8List.fromList(List.generate(12, (_) => _random.nextInt(256)));

  static Uint8List deriveKey(String password, Uint8List salt) {
    final generator = KeyDerivator('SHA-256/HMAC/PBKDF2')
      ..init(Pbkdf2Parameters(salt, 100000, 32));
    return generator.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// Async version that runs PBKDF2 in an isolate to avoid blocking the UI thread.
  static Future<Uint8List> deriveKeyAsync(String password, Uint8List salt) {
    return Isolate.run(() => deriveKey(password, salt));
  }

  static Uint8List encrypt(Uint8List plaintext, Uint8List key, Uint8List nonce) {
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(
        KeyParameter(key),
        128,
        nonce,
        Uint8List(0),
      ));
    return cipher.process(plaintext);
  }

  static Uint8List decrypt(Uint8List ciphertext, Uint8List key, Uint8List nonce) {
    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(
        KeyParameter(key),
        128,
        nonce,
        Uint8List(0),
      ));
    return cipher.process(ciphertext);
  }
}
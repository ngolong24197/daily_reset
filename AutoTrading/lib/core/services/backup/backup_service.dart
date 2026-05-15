import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../../models/streak.dart';
import 'crypto_helper.dart';
import '../persistence/persistence_service.dart';

class BackupService {
  final PersistenceService _persistence;
  static const int _formatVersion = 1;

  BackupService(this._persistence);

  Future<String> exportBackup(String password) async {
    final data = <String, dynamic>{
      'version': _formatVersion,
      'streak': _persistence.streak.toJson(),
      'favoriteQuotes': _persistence.getFavoriteQuotes(),
      // Note: isPremium is intentionally excluded — it must only come from
      // verified store purchases, not from backup files.
      'exportDate': DateTime.now().toIso8601String(),
    };

    final jsonString = jsonEncode(data);
    final jsonBytes = utf8.encode(jsonString);

    final salt = CryptoHelper.generateSalt();
    final key = await CryptoHelper.deriveKeyAsync(password, salt);
    final nonce = CryptoHelper.generateNonce();
    final encrypted = CryptoHelper.encrypt(Uint8List.fromList(jsonBytes), key, nonce);

    // Format: [16-byte salt][12-byte nonce][ciphertext+tag]
    final output = Uint8List(salt.length + nonce.length + encrypted.length);
    output.setRange(0, salt.length, salt);
    output.setRange(salt.length, salt.length + nonce.length, nonce);
    output.setRange(salt.length + nonce.length, output.length, encrypted);

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/daily_reset_backup_${DateTime.now().millisecondsSinceEpoch}.drb';
    final file = File(filePath);
    await file.writeAsBytes(output);

    return filePath;
  }

  Future<bool> importBackup(String password, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();
      if (bytes.length < 28) return false; // Minimum: 16 salt + 12 nonce

      final salt = bytes.sublist(0, 16);
      final nonce = bytes.sublist(16, 28);
      final ciphertext = bytes.sublist(28);

      final key = await CryptoHelper.deriveKeyAsync(password, salt);
      final decrypted = CryptoHelper.decrypt(ciphertext, key, nonce);

      final jsonString = utf8.decode(decrypted);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Check format version
      final version = data['version'] as int? ?? 0;
      if (version > _formatVersion) {
        return false; // Unsupported version
      }

      // Restore streak data
      final streakData = StreakData.fromJson(data['streak'] as Map<String, dynamic>);
      await _persistence.saveStreak(streakData);

      // Restore favorites
      final favorites = List<String>.from(data['favoriteQuotes'] as List? ?? []);
      await _persistence.settingsBox.put('favoriteQuotes', favorites);

      // Note: isPremium is NOT restored from backup. Premium status must come
      // from verified store purchases only.

      return true;
    } on FormatException {
      return false; // Decryption failed (wrong password)
    } catch (_) {
      return false;
    }
  }
}
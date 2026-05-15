import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudBackupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<bool> uploadFavorites(List<String> favoriteQuoteIds) async {
    if (_uid == null) return false;
    try {
      await _db.collection('users').doc(_uid).set({
        'favoriteQuoteIds': favoriteQuoteIds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadReflections(List<Map<String, dynamic>> reflections) async {
    if (_uid == null) return false;
    try {
      final batch = _db.batch();
      final ref = _db.collection('users').doc(_uid).collection('reflections');
      for (final entry in reflections) {
        batch.set(ref.doc(entry['date'] as String), {
          'mood': entry['mood'],
          'journalText': entry['journalText'],
          'createdAt': entry['createdAt'],
        });
      }
      await _db.collection('users').doc(_uid).set({
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> downloadFavorites() async {
    if (_uid == null) return [];
    try {
      final doc = await _db.collection('users').doc(_uid).get();
      if (!doc.exists) return [];
      final data = doc.data()!;
      return List<String>.from(data['favoriteQuoteIds'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> downloadReflections() async {
    if (_uid == null) return [];
    try {
      final snapshot = await _db.collection('users').doc(_uid).collection('reflections').get();
      return snapshot.docs.map((doc) => {
        'date': doc.id,
        ...doc.data(),
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> uploadAll({
    required List<String> favoriteQuoteIds,
    required List<Map<String, dynamic>> reflections,
  }) async {
    if (_uid == null) return false;
    try {
      await uploadFavorites(favoriteQuoteIds);
      await uploadReflections(reflections);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<CloudRestoreResult> downloadAll() async {
    try {
      final favorites = await downloadFavorites();
      final reflections = await downloadReflections();
      return CloudRestoreResult(
        success: true,
        favoriteQuoteIds: favorites,
        reflections: reflections,
      );
    } catch (e) {
      return CloudRestoreResult(
        success: false,
        favoriteQuoteIds: [],
        reflections: [],
        error: e.toString(),
      );
    }
  }
}

class CloudRestoreResult {
  final bool success;
  final List<String> favoriteQuoteIds;
  final List<Map<String, dynamic>> reflections;
  final String? error;

  CloudRestoreResult({
    required this.success,
    required this.favoriteQuoteIds,
    required this.reflections,
    this.error,
  });
}
// lib/services/scan_limit_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScanLimitService {
  static const int maxScansPerUser = 6;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if user has scans remaining
  /// Returns true if user can scan, false if limit reached
  Future<bool> canUserScan() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        // Initialize user document with scanCount = 0
        await _firestore.collection('users').doc(userId).set({
          'scanCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return true;
      }

      final data = userDoc.data();
      final scanCount = data?['scanCount'] as int? ?? 0;

      return scanCount < maxScansPerUser;
    } catch (e) {
      print('Error checking scan limit: $e');
      return false;
    }
  }

  /// Get remaining scans for current user
  Future<int> getRemainingScans() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return maxScansPerUser;
      }

      final data = userDoc.data();
      final scanCount = data?['scanCount'] as int? ?? 0;

      return (maxScansPerUser - scanCount).clamp(0, maxScansPerUser);
    } catch (e) {
      print('Error getting remaining scans: $e');
      return 0;
    }
  }

  /// Increment scan count (called after successful AI analysis)
  /// Returns true if increment successful, false otherwise
  Future<bool> incrementScanCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final userRef = _firestore.collection('users').doc(userId);

      // Use transaction to ensure atomic increment and validation
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        final currentCount = userDoc.exists
            ? (userDoc.data()?['scanCount'] as int? ?? 0)
            : 0;

        // Check limit before incrementing
        if (currentCount >= maxScansPerUser) {
          throw Exception('Scan limit reached');
        }

        // Increment count
        transaction.set(userRef, {
          'scanCount': currentCount + 1,
          'lastScanAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      return true;
    } catch (e) {
      print('Error incrementing scan count: $e');
      return false;
    }
  }

  /// Get current scan count for user
  Future<int> getCurrentScanCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return 0;

      final data = userDoc.data();
      return data?['scanCount'] as int? ?? 0;
    } catch (e) {
      print('Error getting scan count: $e');
      return 0;
    }
  }
}

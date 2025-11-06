// lib/services/leaderboard_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? photoURL;
  final int ecoScore;
  final int rank;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.photoURL,
    required this.ecoScore,
    required this.rank,
    this.isCurrentUser = false,
  });
}

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate eco score for a specific user
  /// Formula: (scans × 8) + (posts × 5) + (weight × 4)
  Future<int> calculateEcoScore(String userId) async {
    try {
      // Get user's devices from correct path: users/{userId}/devices
      final devicesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .get();

      final deviceCount = devicesSnapshot.docs.length;

      // Calculate total weight
      double totalWeight = 0;
      for (var doc in devicesSnapshot.docs) {
        final data = doc.data();
        final weight = (data['estWeightKg'] ?? data['weightKg'] ?? 0.0) as num;
        totalWeight += weight.toDouble();
      }

      // Get user's posts
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();

      final postCount = postsSnapshot.docs.length;

      // Calculate eco score (no clamping to allow scores above 100)
      final fromScans = deviceCount * 8.0;
      final fromPosts = postCount * 5.0;
      final fromWeight = totalWeight * 4.0;

      final ecoScore = (fromScans + fromPosts + fromWeight);
      return ecoScore.round();
    } catch (e) {
      print('Error calculating eco score for user $userId: $e');
      return 0;
    }
  }

  /// Get all users with their eco scores, sorted by score
  Future<List<LeaderboardEntry>> getGlobalLeaderboard({
    required String currentUserId,
    int limit = 100,
  }) async {
    try {
      // Get all users collection
      final usersSnapshot = await _firestore.collection('users').get();

      // Calculate eco scores for all users
      final List<LeaderboardEntry> entries = [];

      for (var userDoc in usersSnapshot.docs) {
        try {
          final userId = userDoc.id;
          final userData = userDoc.data();

          // Get user info from Firestore Auth data
          String userName = 'Anonymous';
          String? photoURL;

          // Try to get from devices subcollection first
          final devicesSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('devices')
              .limit(1)
              .get();

          if (devicesSnapshot.docs.isNotEmpty) {
            final deviceData = devicesSnapshot.docs.first.data();
            userName =
                deviceData['userName'] as String? ??
                userData['displayName'] as String? ??
                'Anonymous';
            photoURL =
                deviceData['photoURL'] as String? ??
                userData['photoURL'] as String?;
          } else {
            // Fallback to user document data
            userName =
                userData['displayName'] as String? ??
                userData['email'] as String? ??
                'Anonymous';
            photoURL = userData['photoURL'] as String?;
          }

          // Calculate eco score
          final ecoScore = await calculateEcoScore(userId);

          // Only add users with non-zero eco scores
          if (ecoScore > 0) {
            entries.add(
              LeaderboardEntry(
                userId: userId,
                userName: userName,
                photoURL: photoURL,
                ecoScore: ecoScore,
                rank: 0, // Will be set after sorting
                isCurrentUser: userId == currentUserId,
              ),
            );
          }
        } catch (e) {
          print('Error processing user ${userDoc.id}: $e');
        }
      }

      // Sort by eco score descending
      entries.sort((a, b) => b.ecoScore.compareTo(a.ecoScore));

      // Assign ranks
      final rankedEntries = <LeaderboardEntry>[];
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        rankedEntries.add(
          LeaderboardEntry(
            userId: entry.userId,
            userName: entry.userName,
            photoURL: entry.photoURL,
            ecoScore: entry.ecoScore,
            rank: i + 1,
            isCurrentUser: entry.isCurrentUser,
          ),
        );
      }

      // Limit results
      return rankedEntries.take(limit).toList();
    } catch (e) {
      print('Error getting global leaderboard: $e');
      return [];
    }
  }

  /// Get current user's rank
  Future<int> getUserRank(String userId) async {
    try {
      final leaderboard = await getGlobalLeaderboard(
        currentUserId: userId,
        limit: 1000, // Get more entries to find user's rank
      );

      final entry = leaderboard.firstWhere(
        (e) => e.userId == userId,
        orElse: () => LeaderboardEntry(
          userId: userId,
          userName: 'You',
          ecoScore: 0,
          rank: 0,
        ),
      );

      return entry.rank;
    } catch (e) {
      print('Error getting user rank: $e');
      return 0;
    }
  }

  /// Get leaderboard with user's position highlighted
  /// Returns top N users + current user if not in top N
  Future<List<LeaderboardEntry>> getLeaderboardWithUser({
    required String currentUserId,
    int topCount = 20,
  }) async {
    try {
      final allEntries = await getGlobalLeaderboard(
        currentUserId: currentUserId,
        limit: 1000,
      );

      if (allEntries.isEmpty) return [];

      // Get top entries
      final topEntries = allEntries.take(topCount).toList();

      // Check if current user is in top entries
      final userInTop = topEntries.any((e) => e.isCurrentUser);

      if (userInTop) {
        return topEntries;
      }

      // Find current user's entry
      final userEntry = allEntries.firstWhere(
        (e) => e.isCurrentUser,
        orElse: () => LeaderboardEntry(
          userId: currentUserId,
          userName: 'You',
          ecoScore: 0,
          rank: allEntries.length + 1,
          isCurrentUser: true,
        ),
      );

      // Add user entry at the end
      return [...topEntries, userEntry];
    } catch (e) {
      print('Error getting leaderboard with user: $e');
      return [];
    }
  }
}

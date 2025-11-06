// lib/services/post_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;
  String? get _userName => _auth.currentUser?.displayName ?? 'Anonymous';
  String? get _userPhotoUrl => _auth.currentUser?.photoURL;

  // Create a new post
  Future<bool> createPost(PostModel post) async {
    try {
      await _firestore.collection('posts').doc(post.id).set(post.toMap());
      return true;
    } catch (e) {
      print('Error creating post: $e');
      return false;
    }
  }

  // Get all posts (stream for real-time updates)
  Stream<List<PostModel>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PostModel.fromMap(doc.data());
          }).toList();
        });
  }

  // Get posts by user ID (without orderBy to avoid index requirement)
  Stream<List<PostModel>> getPostsByUser(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs.map((doc) {
            return PostModel.fromMap(doc.data());
          }).toList();
          // Sort in memory to avoid Firestore index requirement
          posts.sort((a, b) => b.postedAt.compareTo(a.postedAt));
          return posts;
        });
  }

  // Get a single post by ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      if (doc.exists) {
        return PostModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }

  // Toggle like on a post
  Future<bool> toggleLike(String postId) async {
    try {
      final userId = _userId;
      if (userId == null) return false;

      final postRef = _firestore.collection('posts').doc(postId);
      final doc = await postRef.get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final likes = data['likes'] ?? 0;

      if (likedBy.contains(userId)) {
        // Unlike
        likedBy.remove(userId);
        await postRef.update({
          'likedBy': likedBy,
          'likes': likes > 0 ? likes - 1 : 0,
        });
      } else {
        // Like
        likedBy.add(userId);
        await postRef.update({'likedBy': likedBy, 'likes': likes + 1});
      }

      return true;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  // Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  // Increment comment count
  Future<bool> incrementCommentCount(String postId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      await postRef.update({'comments': FieldValue.increment(1)});
      return true;
    } catch (e) {
      print('Error incrementing comment count: $e');
      return false;
    }
  }
}

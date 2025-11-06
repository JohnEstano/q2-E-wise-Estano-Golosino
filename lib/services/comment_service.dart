// lib/services/comment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Add a comment to a post
  Future<bool> addComment(CommentModel comment) async {
    try {
      // Add comment to comments collection
      await _firestore
          .collection('comments')
          .doc(comment.id)
          .set(comment.toMap());

      // Increment comment count on the post
      await _firestore.collection('posts').doc(comment.postId).update({
        'comments': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  // Get comments for a post (stream for real-time updates)
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .handleError((error) {
          print('Error getting comments: $error');
          return <CommentModel>[];
        })
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return CommentModel.fromMap(doc.data());
                } catch (e) {
                  print('Error parsing comment: $e');
                  return null;
                }
              })
              .whereType<CommentModel>()
              .toList();
        });
  }

  // Delete a comment
  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      // Delete comment
      await _firestore.collection('comments').doc(commentId).delete();

      // Decrement comment count on the post
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }
}

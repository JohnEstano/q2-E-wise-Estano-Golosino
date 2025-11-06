// lib/models/post_model.dart
import 'device.dart';

class PostModel {
  String id;
  String userId;
  String userName;
  String? userPhotoUrl;
  Device device;
  String description;
  DateTime postedAt;
  int likes;
  int comments;
  List<String> likedBy;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.device,
    required this.description,
    required this.postedAt,
    this.likes = 0,
    this.comments = 0,
    List<String>? likedBy,
  }) : likedBy = likedBy ?? [];

  // Convert PostModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'device': device.toMap(),
      'description': description,
      'postedAt': postedAt.toIso8601String(),
      'likes': likes,
      'comments': comments,
      'likedBy': likedBy,
    };
  }

  // Create PostModel from Firestore Map
  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      userPhotoUrl: map['userPhotoUrl'],
      device: Device.fromMap(map['device'] ?? {}),
      description: map['description'] ?? '',
      postedAt: map['postedAt'] != null
          ? DateTime.parse(map['postedAt'])
          : DateTime.now(),
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      likedBy: map['likedBy'] != null ? List<String>.from(map['likedBy']) : [],
    );
  }
}

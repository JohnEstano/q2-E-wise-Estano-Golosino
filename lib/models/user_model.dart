// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String? phoneNumber;
  final int scanCount; // Number of scans used (max 6)

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.scanCount = 0,
  });

  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'User',
      photoURL: firebaseUser.photoURL,
      phoneNumber: firebaseUser.phoneNumber,
      scanCount: 0, // Default to 0 for new users
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'scanCount': scanCount,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      phoneNumber: json['phoneNumber'],
      scanCount: json['scanCount'] ?? 0,
    );
  }
}

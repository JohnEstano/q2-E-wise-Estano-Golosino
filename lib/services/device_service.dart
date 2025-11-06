// lib/services/device_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/device.dart';

class DeviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Generate unique QR code identifier
  String generateQRCode() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Upload image to Firebase Storage
  Future<String?> uploadImage(String imagePath, String deviceId) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final userId = _userId;
      if (userId == null) throw Exception('User not authenticated');

      // Create reference with user-specific path
      final storageRef = _storage.ref().child(
        'devices/$userId/$deviceId/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Upload file
      final uploadTask = await storageRef.putFile(file);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Save device to Firestore
  Future<bool> saveDevice(Device device) async {
    try {
      final userId = _userId;
      if (userId == null) throw Exception('User not authenticated');

      // Upload image if available
      if (device.imagePath != null && device.imagePath!.isNotEmpty) {
        final imageUrl = await uploadImage(device.imagePath!, device.id);
        if (imageUrl != null) {
          device.imageUrl = imageUrl;
        }
      }

      // Save to Firestore under user's collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(device.id)
          .set(device.toMap());

      return true;
    } catch (e) {
      print('Error saving device: $e');
      return false;
    }
  }

  // Get all devices for current user
  Stream<List<Device>> getDevices() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .orderBy('scannedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Device.fromMap(doc.data());
          }).toList();
        });
  }

  // Get device by ID
  Future<Device?> getDeviceById(String deviceId) async {
    try {
      final userId = _userId;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .get();

      if (doc.exists) {
        return Device.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting device: $e');
      return null;
    }
  }

  // Get device by QR code
  Future<Device?> getDeviceByQRCode(String qrCode) async {
    try {
      final userId = _userId;
      if (userId == null) return null;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Device.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting device by QR code: $e');
      return null;
    }
  }

  // Update device
  Future<bool> updateDevice(Device device) async {
    try {
      final userId = _userId;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(device.id)
          .update(device.toMap());

      return true;
    } catch (e) {
      print('Error updating device: $e');
      return false;
    }
  }

  // Delete device
  Future<bool> deleteDevice(String deviceId) async {
    try {
      final userId = _userId;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting device: $e');
      return false;
    }
  }
}

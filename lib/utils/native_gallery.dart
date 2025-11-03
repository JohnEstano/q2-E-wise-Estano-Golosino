// lib/utils/native_gallery.dart
import 'dart:async';
import 'package:flutter/services.dart';

class NativeGallery {
  static const MethodChannel _ch = MethodChannel('ewise/gallery');

  /// Save the image at [filePath] to the platform gallery.
  /// Returns true on success.
  static Future<bool> saveImageToGallery(String filePath) async {
    try {
      final dynamic res = await _ch.invokeMethod('saveImage', {
        'path': filePath,
      });
      return res == true;
    } on PlatformException {
      // debug print for development
      // print('NativeGallery.saveImageToGallery error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }
}

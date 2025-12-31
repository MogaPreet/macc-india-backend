import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service for Firebase Storage operations
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload image file to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadImage({
    required dynamic file, // File for mobile, Uint8List for web
    required String path,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child('$path/$fileName');
      UploadTask uploadTask;

      if (kIsWeb) {
        // Web upload using bytes
        uploadTask = ref.putData(
          file as Uint8List,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // Mobile upload using file
        uploadTask = ref.putFile(file as File);
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete image from Firebase Storage using its URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;

      // Extract path from URL and delete
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Silently fail if image doesn't exist or can't be deleted
      print('Failed to delete image: $e');
    }
  }

  /// Delete multiple images
  Future<void> deleteImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await deleteImage(url);
    }
  }
}

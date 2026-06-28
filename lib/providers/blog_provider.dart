import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/blog_model.dart';
import '../core/constants/firebase_constants.dart';

/// Provider for managing SEO blog posts
class BlogProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  List<BlogModel> _blogs = [];
  bool _isLoading = false;
  String? _error;
  double _uploadProgress = 0.0;

  List<BlogModel> get blogs => _blogs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  List<BlogModel> get publishedBlogs =>
      _blogs.where((b) => b.isPublished).toList();

  Future<void> fetchBlogs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docs = await _firestoreService.getCollection(
        collection: FirebaseConstants.blogsCollection,
      );

      _blogs = docs.docs.map((doc) => BlogModel.fromFirestore(doc)).toList();

      _blogs.sort((a, b) {
        final aDate = a.publishedAt ?? a.createdAt;
        final bDate = b.publishedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
      _error = null;
    } catch (e) {
      _error = 'Failed to load blogs: $e';
      _blogs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBlog({
    required String title,
    required String slug,
    required String excerpt,
    String? content,
    String? metaTitle,
    String? metaDescription,
    List<String> keywords = const [],
    Uint8List? coverImageFile,
    bool isPublished = false,
    DateTime? publishedAt,
  }) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      String? coverImageUrl;

      if (coverImageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$slug.jpg';
        coverImageUrl = await _storageService.uploadImage(
          file: coverImageFile,
          path: FirebaseConstants.blogImagesPath,
          fileName: fileName,
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        );
      }

      final now = DateTime.now();
      final effectivePublishedAt = isPublished
          ? (publishedAt ?? now)
          : null;

      final blogData = BlogModel(
        id: '',
        title: title,
        slug: slug,
        excerpt: excerpt,
        content: content,
        metaTitle: metaTitle,
        metaDescription: metaDescription,
        keywords: keywords,
        coverImage: coverImageUrl,
        isPublished: isPublished,
        publishedAt: effectivePublishedAt,
        createdAt: now,
        updatedAt: now,
      );

      await _firestoreService.addDocument(
        collection: FirebaseConstants.blogsCollection,
        data: blogData.toFirestore(),
      );

      await fetchBlogs();
      return true;
    } catch (e) {
      _error = 'Failed to add blog: $e';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  Future<bool> updateBlog({
    required String blogId,
    required String title,
    required String slug,
    required String excerpt,
    String? content,
    String? metaTitle,
    String? metaDescription,
    List<String> keywords = const [],
    Uint8List? newCoverImageFile,
    String? existingCoverImageUrl,
    required bool isPublished,
    DateTime? publishedAt,
    DateTime? existingPublishedAt,
  }) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      String? coverImageUrl = existingCoverImageUrl;

      if (newCoverImageFile != null) {
        if (existingCoverImageUrl != null && existingCoverImageUrl.isNotEmpty) {
          await _storageService.deleteImage(existingCoverImageUrl);
        }

        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$slug.jpg';
        coverImageUrl = await _storageService.uploadImage(
          file: newCoverImageFile,
          path: FirebaseConstants.blogImagesPath,
          fileName: fileName,
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        );
      }

      DateTime? effectivePublishedAt = publishedAt ?? existingPublishedAt;
      if (isPublished && effectivePublishedAt == null) {
        effectivePublishedAt = DateTime.now();
      }
      if (!isPublished) {
        effectivePublishedAt = null;
      }

      final updateData = <String, dynamic>{
        'title': title,
        'slug': slug,
        'excerpt': excerpt,
        'content': content,
        'metaTitle': metaTitle,
        'metaDescription': metaDescription,
        'keywords': keywords,
        'coverImage': coverImageUrl,
        'isPublished': isPublished,
        'publishedAt': effectivePublishedAt != null
            ? Timestamp.fromDate(effectivePublishedAt)
            : null,
        'updatedAt': DateTime.now(),
      };

      await _firestoreService.updateDocument(
        collection: FirebaseConstants.blogsCollection,
        docId: blogId,
        data: updateData,
      );

      await fetchBlogs();
      return true;
    } catch (e) {
      _error = 'Failed to update blog: $e';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  Future<bool> deleteBlog(String blogId, String? coverImageUrl) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
        await _storageService.deleteImage(coverImageUrl);
      }

      await _firestoreService.deleteDocument(
        collection: FirebaseConstants.blogsCollection,
        docId: blogId,
      );

      await fetchBlogs();
      return true;
    } catch (e) {
      _error = 'Failed to delete blog: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> togglePublished(String blogId, bool isPublished) async {
    try {
      final updateData = <String, dynamic>{
        'isPublished': isPublished,
        'updatedAt': DateTime.now(),
      };
      if (isPublished) {
        updateData['publishedAt'] = DateTime.now();
      } else {
        updateData['publishedAt'] = null;
      }

      await _firestoreService.updateDocument(
        collection: FirebaseConstants.blogsCollection,
        docId: blogId,
        data: updateData,
      );
      await fetchBlogs();
      return true;
    } catch (e) {
      _error = 'Failed to update publish status: $e';
      return false;
    }
  }
}

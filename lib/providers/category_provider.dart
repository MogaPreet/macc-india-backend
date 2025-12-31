import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/category_model.dart';
import '../core/constants/firebase_constants.dart';

/// Provider for managing categories
class CategoryProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;
  double _uploadProgress = 0.0;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  /// Get active categories only
  List<CategoryModel> get activeCategories =>
      _categories.where((c) => c.isActive).toList();

  /// Fetch all categories
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docs = await _firestoreService.getCollection(
        collection: FirebaseConstants.categoriesCollection,
      );

      _categories = docs.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();

      // Sort by order first (nulls last), then by createdAt
      _categories.sort((a, b) {
        if (a.order != null && b.order != null) {
          return a.order!.compareTo(b.order!);
        } else if (a.order != null) {
          return -1;
        } else if (b.order != null) {
          return 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      _error = null;
    } catch (e) {
      _error = 'Failed to load categories: $e';
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new category
  Future<bool> addCategory({
    required String name,
    required String slug,
    String? icon,
    String? color,
    Uint8List? imageFile,
    int? order,
    bool isActive = true,
  }) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$slug.jpg';
        imageUrl = await _storageService.uploadImage(
          file: imageFile,
          path: FirebaseConstants.categoryImagesPath,
          fileName: fileName,
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        );
      }

      // Create category document
      final now = DateTime.now();
      final categoryData = CategoryModel(
        id: '',
        name: name,
        slug: slug,
        icon: icon,
        color: color,
        image: imageUrl,
        order: order,
        isActive: isActive,
        createdAt: now,
        updatedAt: now,
      );

      await _firestoreService.addDocument(
        collection: FirebaseConstants.categoriesCollection,
        data: categoryData.toFirestore(),
      );

      await fetchCategories();
      return true;
    } catch (e) {
      _error = 'Failed to add category: $e';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Update an existing category
  Future<bool> updateCategory({
    required String categoryId,
    required String name,
    required String slug,
    String? icon,
    String? color,
    Uint8List? newImageFile,
    String? existingImageUrl,
    int? order,
    bool? isActive,
  }) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      String? imageUrl = existingImageUrl;

      // Upload new image if provided
      if (newImageFile != null) {
        // Delete old image if exists
        if (existingImageUrl != null && existingImageUrl.isNotEmpty) {
          await _storageService.deleteImage(existingImageUrl);
        }

        // Upload new image
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$slug.jpg';
        imageUrl = await _storageService.uploadImage(
          file: newImageFile,
          path: FirebaseConstants.categoryImagesPath,
          fileName: fileName,
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        );
      }

      // Update category document
      final updateData = <String, dynamic>{
        'name': name,
        'slug': slug,
        'icon': icon,
        'color': color,
        'image': imageUrl,
        'order': order,
        'updatedAt': DateTime.now(),
      };

      if (isActive != null) {
        updateData['isActive'] = isActive;
      }

      await _firestoreService.updateDocument(
        collection: FirebaseConstants.categoriesCollection,
        docId: categoryId,
        data: updateData,
      );

      await fetchCategories();
      return true;
    } catch (e) {
      _error = 'Failed to update category: $e';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(String categoryId, String? imageUrl) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Delete image from storage if exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _storageService.deleteImage(imageUrl);
      }

      // Delete category document
      await _firestoreService.deleteDocument(
        collection: FirebaseConstants.categoriesCollection,
        docId: categoryId,
      );

      await fetchCategories();
      return true;
    } catch (e) {
      _error = 'Failed to delete category: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle category active status
  Future<bool> toggleCategoryActive(String categoryId, bool isActive) async {
    try {
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.categoriesCollection,
        docId: categoryId,
        data: {'isActive': isActive, 'updatedAt': DateTime.now()},
      );
      await fetchCategories();
      return true;
    } catch (e) {
      _error = 'Failed to update category status: $e';
      return false;
    }
  }

  /// Update category order
  Future<void> updateCategoryOrder(String categoryId, int newOrder) async {
    try {
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.categoriesCollection,
        docId: categoryId,
        data: {'order': newOrder, 'updatedAt': DateTime.now()},
      );
      await fetchCategories();
    } catch (e) {
      debugPrint('Failed to update category order: $e');
    }
  }
}

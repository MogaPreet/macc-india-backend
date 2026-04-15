import 'package:flutter/foundation.dart';
import '../models/accessory_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../core/constants/firebase_constants.dart';

/// Provider for managing accessory state and operations
class AccessoryProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  List<AccessoryModel> _accessories = [];
  bool _isLoading = false;
  String? _error;
  double _uploadProgress = 0.0;

  List<AccessoryModel> get accessories => _accessories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  /// Get active accessories only
  List<AccessoryModel> get activeAccessories =>
      _accessories.where((a) => a.isActive).toList();

  /// Get featured accessories
  List<AccessoryModel> get featuredAccessories =>
      _accessories.where((a) => a.isFeatured && a.isActive).toList();

  /// Get accessories by type
  List<AccessoryModel> getAccessoriesByType(String type) =>
      _accessories.where((a) => a.accessoryType == type && a.isActive).toList();

  /// Get accessories by brand
  List<AccessoryModel> getAccessoriesByBrand(String brandId) =>
      _accessories.where((a) => a.brandId == brandId && a.isActive).toList();

  /// Fetch all accessories
  Future<void> fetchAccessories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestoreService.getCollection(
        collection: FirebaseConstants.accessoriesCollection,
        queryBuilder: (query) => query.orderBy('createdAt', descending: true),
      );

      _accessories = snapshot.docs
          .map((doc) => AccessoryModel.fromFirestore(doc))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _accessories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new accessory
  Future<bool> addAccessory({
    required String name,
    required String slug,
    String? description,
    required String brandId,
    required String brandName,
    required List<String> categoryIds,
    required List<String> categoryNames,
    required String accessoryType,
    required double price,
    double? originalPrice,
    required String condition,
    int stock = 1,
    bool isFeatured = false,
    bool isActive = true,
    required List<Uint8List> imageFiles,
    required AccessorySpecs specs,
    AccessoryWarranty? warranty,
    String? youtubeUrl,
  }) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      List<String> imageUrls = [];

      // Upload all images
      if (imageFiles.isNotEmpty) {
        int index = 0;
        for (var file in imageFiles) {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${slug}_$index.jpg';
          final url = await _storageService.uploadImage(
            file: file,
            path: FirebaseConstants.accessoryImagesPath,
            fileName: fileName,
            onProgress: (progress) {
              _uploadProgress = progress;
              notifyListeners();
            },
          );
          imageUrls.add(url);
          index++;
        }
      }

      // Create accessory document
      final now = DateTime.now();
      final accessoryData = AccessoryModel(
        id: '',
        name: name,
        slug: slug,
        description: description,
        brandId: brandId,
        brandName: brandName,
        categoryIds: categoryIds,
        categoryNames: categoryNames,
        accessoryType: accessoryType,
        price: price,
        originalPrice: originalPrice,
        condition: condition,
        stock: stock,
        isFeatured: isFeatured,
        isActive: isActive,
        images: imageUrls,
        specs: specs,
        warranty: warranty,
        youtubeUrl: youtubeUrl,
        createdAt: now,
        updatedAt: now,
      );

      await _firestoreService.addDocument(
        collection: FirebaseConstants.accessoriesCollection,
        data: accessoryData.toFirestore(),
      );

      await fetchAccessories();
      return true;
    } catch (e) {
      _error = 'Failed to add accessory: $e';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Update an existing accessory
  Future<bool> updateAccessory({
    required String accessoryId,
    required String name,
    required String slug,
    String? description,
    required String brandId,
    required String brandName,
    required List<String> categoryIds,
    required List<String> categoryNames,
    required String accessoryType,
    required double price,
    double? originalPrice,
    required String condition,
    int stock = 1,
    required bool isFeatured,
    required bool isActive,
    List<Uint8List>? newImageFiles,
    required List<String> existingImageUrls,
    required AccessorySpecs specs,
    AccessoryWarranty? warranty,
    String? youtubeUrl,
  }) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      List<String> finalImageUrls = List.from(existingImageUrls);

      // Upload new images
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        int index = 0;
        for (var file in newImageFiles) {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${slug}_new_$index.jpg';
          final url = await _storageService.uploadImage(
            file: file,
            path: FirebaseConstants.accessoryImagesPath,
            fileName: fileName,
            onProgress: (progress) {
              _uploadProgress = progress;
              notifyListeners();
            },
          );
          finalImageUrls.add(url);
          index++;
        }
      }

      // Update accessory document
      final updateData = {
        'name': name,
        'slug': slug,
        'description': description,
        'brandId': brandId,
        'brandName': brandName,
        'categoryIds': categoryIds,
        'categoryNames': categoryNames,
        'accessoryType': accessoryType,
        'price': price,
        'originalPrice': originalPrice,
        'condition': condition,
        'stock': stock,
        'isFeatured': isFeatured,
        'isActive': isActive,
        'images': finalImageUrls,
        'specs': specs.toMap(),
        'warranty': warranty?.toMap(),
        'youtubeUrl': youtubeUrl,
        'updatedAt': DateTime.now(),
      };

      await _firestoreService.updateDocument(
        collection: FirebaseConstants.accessoriesCollection,
        docId: accessoryId,
        data: updateData,
      );

      await fetchAccessories();
      return true;
    } catch (e) {
      _error = 'Failed to update accessory: $e';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Delete accessory
  Future<bool> deleteAccessory(
      String accessoryId, List<String> imageUrls) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Delete all images from storage
      for (var imageUrl in imageUrls) {
        if (imageUrl.isNotEmpty) {
          try {
            await _storageService.deleteImage(imageUrl);
          } catch (e) {
            debugPrint('Failed to delete image: $e');
          }
        }
      }

      // Delete from Firestore
      await _firestoreService.deleteDocument(
        collection: FirebaseConstants.accessoriesCollection,
        docId: accessoryId,
      );

      await fetchAccessories();
      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to delete accessory: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle accessory active status
  Future<bool> toggleAccessoryActive(
      String accessoryId, bool isActive) async {
    try {
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.accessoriesCollection,
        docId: accessoryId,
        data: {'isActive': isActive, 'updatedAt': DateTime.now()},
      );
      await fetchAccessories();
      return true;
    } catch (e) {
      _error = 'Failed to update accessory status: $e';
      return false;
    }
  }

  /// Toggle accessory featured status
  Future<bool> toggleAccessoryFeatured(
      String accessoryId, bool isFeatured) async {
    try {
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.accessoriesCollection,
        docId: accessoryId,
        data: {'isFeatured': isFeatured, 'updatedAt': DateTime.now()},
      );
      await fetchAccessories();
      return true;
    } catch (e) {
      _error = 'Failed to update accessory featured status: $e';
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

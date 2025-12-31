import 'package:flutter/foundation.dart';
import '../models/brand_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../core/constants/firebase_constants.dart';

/// Provider for Brand management
class BrandProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  List<BrandModel> _brands = [];
  bool _isLoading = false;
  String? _error;
  double _uploadProgress = 0.0;

  List<BrandModel> get brands => _brands;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  /// Get active brands only
  List<BrandModel> get activeBrands =>
      _brands.where((b) => b.isActive).toList();

  /// Fetch all brands
  Future<void> fetchBrands() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docs = await _firestoreService.getCollection(
        collection: FirebaseConstants.brandsCollection,
      );

      _brands = docs.docs.map((doc) => BrandModel.fromFirestore(doc)).toList();
      _brands.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _error = null;
    } catch (e) {
      _error = 'Failed to load brands: $e';
      _brands = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new brand
  Future<bool> addBrand({
    required String name,
    Uint8List? logoFile,
    String? color,
    bool isActive = true,
  }) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      String? logoUrl;

      // Upload logo if provided
      if (logoFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$name.jpg';
        logoUrl = await _storageService.uploadImage(
          file: logoFile,
          path: FirebaseConstants.brandImagesPath,
          fileName: fileName,
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        );
      }

      // Create brand document
      final now = DateTime.now();
      final brandData = BrandModel(
        id: '',
        name: name,
        logo: logoUrl,
        color: color,
        isActive: isActive,
        createdAt: now,
      );

      await _firestoreService.addDocument(
        collection: FirebaseConstants.brandsCollection,
        data: brandData.toFirestore(),
      );

      await fetchBrands();
      return true;
    } catch (e) {
      _error = 'Failed to add brand: $e';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Update an existing brand
  Future<bool> updateBrand({
    required String brandId,
    required String name,
    Uint8List? newLogoFile,
    String? existingLogoUrl,
    String? color,
    bool? isActive,
  }) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      String? logoUrl = existingLogoUrl;

      // Upload new logo if provided
      if (newLogoFile != null) {
        // Delete old logo if exists
        if (existingLogoUrl != null && existingLogoUrl.isNotEmpty) {
          await _storageService.deleteImage(existingLogoUrl);
        }

        // Upload new logo
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$name.jpg';
        logoUrl = await _storageService.uploadImage(
          file: newLogoFile,
          path: FirebaseConstants.brandImagesPath,
          fileName: fileName,
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        );
      }

      // Update brand document
      final updateData = <String, dynamic>{
        'name': name,
        'logo': logoUrl,
        'color': color,
      };

      if (isActive != null) {
        updateData['isActive'] = isActive;
      }

      await _firestoreService.updateDocument(
        collection: FirebaseConstants.brandsCollection,
        docId: brandId,
        data: updateData,
      );

      await fetchBrands();
      return true;
    } catch (e) {
      _error = 'Failed to update brand: $e';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Delete a brand
  Future<bool> deleteBrand(String brandId, String? logoUrl) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Delete logo from storage if exists
      if (logoUrl != null && logoUrl.isNotEmpty) {
        await _storageService.deleteImage(logoUrl);
      }

      // Delete brand document
      await _firestoreService.deleteDocument(
        collection: FirebaseConstants.brandsCollection,
        docId: brandId,
      );

      await fetchBrands();
      return true;
    } catch (e) {
      _error = 'Failed to delete brand: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle brand active status
  Future<bool> toggleBrandActive(String brandId, bool isActive) async {
    try {
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.brandsCollection,
        docId: brandId,
        data: {'isActive': isActive},
      );
      await fetchBrands();
      return true;
    } catch (e) {
      _error = 'Failed to update brand status: $e';
      return false;
    }
  }
}

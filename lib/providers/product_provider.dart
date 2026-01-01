import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../core/constants/firebase_constants.dart';

/// Provider for managing product state and operations
class ProductProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;
  double _uploadProgress = 0.0;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  /// Get active products only
  List<ProductModel> get activeProducts =>
      _products.where((p) => p.isActive).toList();

  /// Get featured products
  List<ProductModel> get featuredProducts =>
      _products.where((p) => p.isFeatured && p.isActive).toList();

  /// Get products by category
  List<ProductModel> getProductsByCategory(String categoryId) =>
      _products.where((p) => p.categoryId == categoryId && p.isActive).toList();

  /// Get products by brand
  List<ProductModel> getProductsByBrand(String brandId) =>
      _products.where((p) => p.brandId == brandId && p.isActive).toList();

  /// Fetch all products
  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestoreService.getCollection(
        collection: FirebaseConstants.productsCollection,
        queryBuilder: (query) => query.orderBy('createdAt', descending: true),
      );

      _products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Stream products for real-time updates
  Stream<List<ProductModel>> streamProducts() {
    return _firestoreService
        .streamCollection(
          collection: FirebaseConstants.productsCollection,
          queryBuilder: (query) => query.orderBy('createdAt', descending: true),
        )
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Add a new product
  Future<bool> addProduct({
    required String name,
    required String slug,
    String? description,
    required String brandId,
    required String brandName,
    required String categoryId,
    required String categoryName,
    required double price,
    double? originalPrice,
    required String condition,
    int stock = 1,
    bool isFeatured = false,
    bool isActive = true,
    required List<Uint8List> imageFiles,
    required ProductSpecs specs,
    required List<IncludedItem> includedItems,
    ProductWarranty? warranty,
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
            path: FirebaseConstants.productImagesPath,
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

      // Create product document
      final now = DateTime.now();
      final productData = ProductModel(
        id: '',
        name: name,
        slug: slug,
        description: description,
        brandId: brandId,
        brandName: brandName,
        categoryId: categoryId,
        categoryName: categoryName,
        price: price,
        originalPrice: originalPrice,
        condition: condition,
        stock: stock,
        isFeatured: isFeatured,
        isActive: isActive,
        images: imageUrls,
        specs: specs,
        includedItems: includedItems,
        warranty: warranty,
        youtubeUrl: youtubeUrl,
        createdAt: now,
        updatedAt: now,
      );

      await _firestoreService.addDocument(
        collection: FirebaseConstants.productsCollection,
        data: productData.toFirestore(),
      );

      await fetchProducts();
      return true;
    } catch (e) {
      _error = 'Failed to add product: $e';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Update an existing product
  Future<bool> updateProduct({
    required String productId,
    required String name,
    required String slug,
    String? description,
    required String brandId,
    required String brandName,
    required String categoryId,
    required String categoryName,
    required double price,
    double? originalPrice,
    required String condition,
    int stock = 1,
    required bool isFeatured,
    required bool isActive,
    List<Uint8List>? newImageFiles,
    required List<String> existingImageUrls,
    required ProductSpecs specs,
    required List<IncludedItem> includedItems,
    ProductWarranty? warranty,
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
            path: FirebaseConstants.productImagesPath,
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

      // Update product document
      final updateData = {
        'name': name,
        'slug': slug,
        'description': description,
        'brandId': brandId,
        'brandName': brandName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'price': price,
        'originalPrice': originalPrice,
        'condition': condition,
        'stock': stock,
        'isFeatured': isFeatured,
        'isActive': isActive,
        'images': finalImageUrls,
        'specs': specs.toMap(),
        'includedItems': includedItems.map((item) => item.toMap()).toList(),
        'warranty': warranty?.toMap(),
        'youtubeUrl': youtubeUrl,
        'updatedAt': DateTime.now(),
      };

      await _firestoreService.updateDocument(
        collection: FirebaseConstants.productsCollection,
        docId: productId,
        data: updateData,
      );

      await fetchProducts();
      return true;
    } catch (e) {
      _error = 'Failed to update product: $e';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Delete product
  Future<bool> deleteProduct(String productId, List<String> imageUrls) async {
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
        collection: FirebaseConstants.productsCollection,
        docId: productId,
      );

      // Refresh products list
      await fetchProducts();

      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to delete product: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle product active status
  Future<bool> toggleProductActive(String productId, bool isActive) async {
    try {
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.productsCollection,
        docId: productId,
        data: {'isActive': isActive, 'updatedAt': DateTime.now()},
      );
      await fetchProducts();
      return true;
    } catch (e) {
      _error = 'Failed to update product status: $e';
      return false;
    }
  }

  /// Toggle product featured status
  Future<bool> toggleProductFeatured(String productId, bool isFeatured) async {
    try {
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.productsCollection,
        docId: productId,
        data: {'isFeatured': isFeatured, 'updatedAt': DateTime.now()},
      );
      await fetchProducts();
      return true;
    } catch (e) {
      _error = 'Failed to update product featured status: $e';
      return false;
    }
  }

  /// Update product stock
  Future<bool> updateProductStock(String productId, int stock) async {
    try {
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.productsCollection,
        docId: productId,
        data: {'stock': stock, 'updatedAt': DateTime.now()},
      );
      await fetchProducts();
      return true;
    } catch (e) {
      _error = 'Failed to update product stock: $e';
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

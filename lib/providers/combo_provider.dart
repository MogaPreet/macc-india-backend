import 'package:flutter/foundation.dart';
import '../models/combo_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../core/constants/firebase_constants.dart';

/// Provider for product combos (bundles of 2+ catalog products).
class ComboProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  List<ProductComboModel> _combos = [];
  bool _isLoading = false;
  String? _error;
  double _uploadProgress = 0.0;

  List<ProductComboModel> get combos => _combos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  List<ProductComboModel> get activeCombos =>
      _combos.where((c) => c.isActive).toList();

  Future<void> fetchCombos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestoreService.getCollection(
        collection: FirebaseConstants.combosCollection,
        queryBuilder: (query) => query.orderBy('createdAt', descending: true),
      );

      _combos = snapshot.docs
          .map((doc) => ProductComboModel.fromFirestore(doc))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _combos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCombo({
    required String name,
    required String slug,
    String? description,
    required List<ComboComponent> components,
    required double price,
    double? originalPrice,
    int stock = 1,
    bool isFeatured = false,
    bool isActive = true,
    required List<Uint8List> imageFiles,
    String? youtubeUrl,
  }) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      final imageUrls = <String>[];
      if (imageFiles.isNotEmpty) {
        var index = 0;
        for (final file in imageFiles) {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${slug}_$index.jpg';
          final url = await _storageService.uploadImage(
            file: file,
            path: FirebaseConstants.comboImagesPath,
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

      final now = DateTime.now();
      final data = ProductComboModel(
        id: '',
        name: name,
        slug: slug,
        description: description,
        components: components,
        price: price,
        originalPrice: originalPrice,
        stock: stock,
        isFeatured: isFeatured,
        isActive: isActive,
        images: imageUrls,
        youtubeUrl: youtubeUrl,
        createdAt: now,
        updatedAt: now,
      ).toFirestore();

      await _firestoreService.addDocument(
        collection: FirebaseConstants.combosCollection,
        data: data,
      );

      await fetchCombos();
      return true;
    } catch (e) {
      _error = 'Failed to add combo: $e';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  Future<bool> updateCombo({
    required String comboId,
    required String name,
    required String slug,
    String? description,
    required List<ComboComponent> components,
    required double price,
    double? originalPrice,
    required int stock,
    required bool isFeatured,
    required bool isActive,
    List<Uint8List>? newImageFiles,
    required List<String> existingImageUrls,
    String? youtubeUrl,
  }) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      var finalImageUrls = List<String>.from(existingImageUrls);

      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        var index = 0;
        for (final file in newImageFiles) {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${slug}_new_$index.jpg';
          final url = await _storageService.uploadImage(
            file: file,
            path: FirebaseConstants.comboImagesPath,
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

      final updateData = {
        'name': name,
        'slug': slug,
        'description': description,
        'components': components.map((c) => c.toMap()).toList(),
        'price': price,
        'originalPrice': originalPrice,
        'stock': stock,
        'isFeatured': isFeatured,
        'isActive': isActive,
        'images': finalImageUrls,
        'youtubeUrl': youtubeUrl,
        'updatedAt': DateTime.now(),
      };

      await _firestoreService.updateDocument(
        collection: FirebaseConstants.combosCollection,
        docId: comboId,
        data: updateData,
      );

      await fetchCombos();
      return true;
    } catch (e) {
      _error = 'Failed to update combo: $e';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  Future<bool> deleteCombo(String comboId, List<String> imageUrls) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      for (final url in imageUrls) {
        if (url.isNotEmpty) {
          try {
            await _storageService.deleteImage(url);
          } catch (e) {
            debugPrint('Failed to delete combo image: $e');
          }
        }
      }

      await _firestoreService.deleteDocument(
        collection: FirebaseConstants.combosCollection,
        docId: comboId,
      );

      await fetchCombos();
      return true;
    } catch (e) {
      _error = 'Failed to delete combo: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleComboActive(String comboId, bool isActive) async {
    try {
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.combosCollection,
        docId: comboId,
        data: {'isActive': isActive, 'updatedAt': DateTime.now()},
      );
      await fetchCombos();
      return true;
    } catch (e) {
      _error = 'Failed to update combo status: $e';
      return false;
    }
  }

  Future<bool> toggleComboFeatured(String comboId, bool isFeatured) async {
    try {
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.combosCollection,
        docId: comboId,
        data: {'isFeatured': isFeatured, 'updatedAt': DateTime.now()},
      );
      await fetchCombos();
      return true;
    } catch (e) {
      _error = 'Failed to update combo featured flag: $e';
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

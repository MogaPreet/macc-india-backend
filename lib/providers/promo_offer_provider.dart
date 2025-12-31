import 'package:flutter/foundation.dart';
import '../models/promo_offer_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../core/constants/firebase_constants.dart';

/// Provider for Promo Offer management
class PromoOfferProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  List<PromoOfferModel> _offers = [];
  bool _isLoading = false;
  String? _error;
  double _uploadProgress = 0.0;

  List<PromoOfferModel> get offers => _offers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  /// Get active offer (only one should be active)
  PromoOfferModel? get activeOffer {
    try {
      return _offers.firstWhere((o) => o.isActive && o.isCurrentlyValid);
    } catch (e) {
      return null;
    }
  }

  /// Fetch all promo offers
  Future<void> fetchOffers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestoreService.getCollection(
        collection: FirebaseConstants.promoOffersCollection,
        queryBuilder: (query) => query.orderBy('createdAt', descending: true),
      );

      _offers = snapshot.docs
          .map((doc) => PromoOfferModel.fromFirestore(doc))
          .toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load offers: $e';
      _offers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new promo offer
  Future<bool> addOffer({
    required String title,
    String? subtitle,
    required Uint8List imageFile,
    required List<String> productIds,
    DateTime? startDate,
    DateTime? endDate,
    bool isActive = false,
  }) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      // If setting as active, deactivate all other offers first
      if (isActive) {
        await _deactivateAllOffers();
      }

      // Upload background image
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_promo.jpg';
      final imageUrl = await _storageService.uploadImage(
        file: imageFile,
        path: FirebaseConstants.promoImagesPath,
        fileName: fileName,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      // Create offer document
      final offerData = PromoOfferModel(
        id: '',
        title: title,
        subtitle: subtitle,
        backgroundImage: imageUrl,
        productIds: productIds,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addDocument(
        collection: FirebaseConstants.promoOffersCollection,
        data: offerData.toFirestore(),
      );

      await fetchOffers();
      return true;
    } catch (e) {
      _error = 'Failed to add offer: $e';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Update an existing promo offer
  Future<bool> updateOffer({
    required String offerId,
    required String title,
    String? subtitle,
    Uint8List? newImageFile,
    required String existingImageUrl,
    required List<String> productIds,
    DateTime? startDate,
    DateTime? endDate,
    required bool isActive,
  }) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      // If setting as active, deactivate all other offers first
      if (isActive) {
        await _deactivateAllOffers(exceptId: offerId);
      }

      String imageUrl = existingImageUrl;

      // Upload new image if provided
      if (newImageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_promo.jpg';
        imageUrl = await _storageService.uploadImage(
          file: newImageFile,
          path: FirebaseConstants.promoImagesPath,
          fileName: fileName,
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        );
      }

      // Update offer document
      final updateData = {
        'title': title,
        'subtitle': subtitle,
        'backgroundImage': imageUrl,
        'productIds': productIds,
        'startDate': startDate,
        'endDate': endDate,
        'isActive': isActive,
      };

      await _firestoreService.updateDocument(
        collection: FirebaseConstants.promoOffersCollection,
        docId: offerId,
        data: updateData,
      );

      await fetchOffers();
      return true;
    } catch (e) {
      _error = 'Failed to update offer: $e';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Toggle offer active status
  Future<bool> toggleOfferActive(String offerId, bool isActive) async {
    try {
      // If activating, deactivate all other offers first
      if (isActive) {
        await _deactivateAllOffers(exceptId: offerId);
      }

      await _firestoreService.updateDocument(
        collection: FirebaseConstants.promoOffersCollection,
        docId: offerId,
        data: {'isActive': isActive},
      );
      await fetchOffers();
      return true;
    } catch (e) {
      _error = 'Failed to update status: $e';
      return false;
    }
  }

  /// Deactivate all offers (except optionally one)
  Future<void> _deactivateAllOffers({String? exceptId}) async {
    for (var offer in _offers.where((o) => o.isActive && o.id != exceptId)) {
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.promoOffersCollection,
        docId: offer.id,
        data: {'isActive': false},
      );
    }
  }

  /// Delete an offer
  Future<bool> deleteOffer(String offerId, String imageUrl) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Delete image from storage
      if (imageUrl.isNotEmpty) {
        try {
          await _storageService.deleteImage(imageUrl);
        } catch (e) {
          debugPrint('Failed to delete image: $e');
        }
      }

      // Delete from Firestore
      await _firestoreService.deleteDocument(
        collection: FirebaseConstants.promoOffersCollection,
        docId: offerId,
      );

      await fetchOffers();
      return true;
    } catch (e) {
      _error = 'Failed to delete offer: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

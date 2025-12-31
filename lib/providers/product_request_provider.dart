import 'package:flutter/foundation.dart';
import '../models/product_request_model.dart';
import '../services/firestore_service.dart';
import '../core/constants/firebase_constants.dart';

/// Provider for Product Request management
class ProductRequestProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ProductRequestModel> _requests = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = 'all';
  String _searchQuery = '';

  List<ProductRequestModel> get requests => _filteredRequests;
  List<ProductRequestModel> get allRequests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;

  /// Get filtered requests based on status and search query
  List<ProductRequestModel> get _filteredRequests {
    List<ProductRequestModel> filtered = _requests;

    // Apply status filter
    if (_statusFilter != 'all') {
      filtered = filtered.where((r) => r.status == _statusFilter).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return r.customerName.toLowerCase().contains(query) ||
            r.customerPhone.toLowerCase().contains(query) ||
            r.productName.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  /// Get count by status
  int getCountByStatus(String status) {
    if (status == 'all') return _requests.length;
    return _requests.where((r) => r.status == status).length;
  }

  /// Set status filter
  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Fetch all product requests
  Future<void> fetchRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestoreService.getCollection(
        collection: FirebaseConstants.productRequestsCollection,
        queryBuilder: (query) => query.orderBy('createdAt', descending: true),
      );

      _requests = snapshot.docs
          .map((doc) => ProductRequestModel.fromFirestore(doc))
          .toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load requests: $e';
      _requests = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update request status
  Future<bool> updateRequestStatus(String requestId, String newStatus) async {
    try {
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.productRequestsCollection,
        docId: requestId,
        data: {'status': newStatus},
      );
      await fetchRequests();
      return true;
    } catch (e) {
      _error = 'Failed to update status: $e';
      return false;
    }
  }

  /// Delete a request
  Future<bool> deleteRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.deleteDocument(
        collection: FirebaseConstants.productRequestsCollection,
        docId: requestId,
      );
      await fetchRequests();
      return true;
    } catch (e) {
      _error = 'Failed to delete request: $e';
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

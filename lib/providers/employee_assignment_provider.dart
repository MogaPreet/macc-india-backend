import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/employee_assignment_model.dart';
import '../services/firestore_service.dart';
import '../core/constants/firebase_constants.dart';

/// Provider for Employee Assignment / Progress management
class EmployeeAssignmentProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<EmployeeAssignmentModel> _assignments = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = 'all';
  String _employeeFilter = 'all';
  String _searchQuery = '';

  List<EmployeeAssignmentModel> get assignments => _filteredAssignments;
  List<EmployeeAssignmentModel> get allAssignments => _assignments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;
  String get employeeFilter => _employeeFilter;
  String get searchQuery => _searchQuery;

  List<EmployeeAssignmentModel> get _filteredAssignments {
    var filtered = _assignments;

    if (_statusFilter != 'all') {
      filtered = filtered.where((a) => a.status == _statusFilter).toList();
    }

    if (_employeeFilter != 'all') {
      filtered =
          filtered.where((a) => a.employeeId == _employeeFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        return a.customerName.toLowerCase().contains(query) ||
            a.customerPhone.toLowerCase().contains(query) ||
            (a.customerEmail?.toLowerCase().contains(query) ?? false) ||
            a.productName.toLowerCase().contains(query) ||
            a.employeeName.toLowerCase().contains(query) ||
            a.remarks.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  int getCountByStatus(String status) {
    if (status == 'all') return _assignments.length;
    return _assignments.where((a) => a.status == status).length;
  }

  List<EmployeeAssignmentModel> assignmentsForEmployee(String employeeId) {
    return _assignments.where((a) => a.employeeId == employeeId).toList();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setEmployeeFilter(String employeeId) {
    _employeeFilter = employeeId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchAssignments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestoreService.getCollection(
        collection: FirebaseConstants.employeeAssignmentsCollection,
      );

      _assignments = snapshot.docs
          .map((doc) => EmployeeAssignmentModel.fromFirestore(doc))
          .toList();
      _assignments.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _error = null;
    } catch (e) {
      _error = 'Failed to load assignments: $e';
      _assignments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAssignment({
    required String employeeId,
    required String employeeName,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required String productId,
    required String productName,
    String status = AssignmentStatus.pending,
    String remarks = '',
    String createdBy = 'admin',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final history = <RemarkHistoryEntry>[];
      final trimmedRemarks = remarks.trim();
      if (trimmedRemarks.isNotEmpty) {
        history.add(
          RemarkHistoryEntry(
            text: trimmedRemarks,
            updatedAt: now,
            updatedBy: createdBy,
          ),
        );
      }

      final assignment = EmployeeAssignmentModel(
        id: '',
        employeeId: employeeId,
        employeeName: employeeName,
        customerName: customerName.trim(),
        customerPhone: customerPhone.trim(),
        customerEmail: _nullableTrim(customerEmail),
        productId: productId,
        productName: productName,
        status: status,
        remarks: trimmedRemarks,
        remarkHistory: history,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      await _firestoreService.addDocument(
        collection: FirebaseConstants.employeeAssignmentsCollection,
        data: assignment.toFirestore(),
      );

      await fetchAssignments();
      return true;
    } catch (e) {
      _error = 'Failed to add assignment: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAssignment({
    required String id,
    required String employeeId,
    required String employeeName,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required String productId,
    required String productName,
    required String status,
    required String remarks,
    String updatedBy = 'admin',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      EmployeeAssignmentModel? existing;
      for (final a in _assignments) {
        if (a.id == id) {
          existing = a;
          break;
        }
      }

      final now = DateTime.now();
      final trimmedRemarks = remarks.trim();
      final history = List<RemarkHistoryEntry>.from(
        existing?.remarkHistory ?? [],
      );

      final previousRemarks = existing?.remarks.trim() ?? '';
      if (trimmedRemarks.isNotEmpty && trimmedRemarks != previousRemarks) {
        history.insert(
          0,
          RemarkHistoryEntry(
            text: trimmedRemarks,
            updatedAt: now,
            updatedBy: updatedBy,
          ),
        );
      }

      await _firestoreService.updateDocument(
        collection: FirebaseConstants.employeeAssignmentsCollection,
        docId: id,
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'customerName': customerName.trim(),
          'customerPhone': customerPhone.trim(),
          'customerEmail': _nullableTrim(customerEmail),
          'productId': productId,
          'productName': productName,
          'status': status,
          'remarks': trimmedRemarks,
          'remarkHistory': history.map((e) => e.toMap()).toList(),
          'updatedAt': Timestamp.fromDate(now),
        },
      );

      await fetchAssignments();
      return true;
    } catch (e) {
      _error = 'Failed to update assignment: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String id, String newStatus) async {
    try {
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.employeeAssignmentsCollection,
        docId: id,
        data: {
          'status': newStatus,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );
      await fetchAssignments();
      return true;
    } catch (e) {
      _error = 'Failed to update status: $e';
      return false;
    }
  }

  Future<bool> deleteAssignment(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.deleteDocument(
        collection: FirebaseConstants.employeeAssignmentsCollection,
        docId: id,
      );
      await fetchAssignments();
      return true;
    } catch (e) {
      _error = 'Failed to delete assignment: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Keep denormalized employee name in sync when employee profile is updated
  Future<void> syncEmployeeName(String employeeId, String newName) async {
    final matching =
        _assignments.where((a) => a.employeeId == employeeId).toList();
    for (final a in matching) {
      if (a.employeeName == newName) continue;
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.employeeAssignmentsCollection,
        docId: a.id,
        data: {'employeeName': newName},
      );
    }
    if (matching.isNotEmpty) {
      await fetchAssignments();
    }
  }

  String? _nullableTrim(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

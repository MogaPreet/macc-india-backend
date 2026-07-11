import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/employee_model.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
import '../core/constants/firebase_constants.dart';

/// Provider for Employee management
class EmployeeProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  List<EmployeeModel> _employees = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _activeFilter = 'all';

  List<EmployeeModel> get employees => _filteredEmployees;
  List<EmployeeModel> get allEmployees => _employees;
  List<EmployeeModel> get activeEmployees =>
      _employees.where((e) => e.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get activeFilter => _activeFilter;

  List<EmployeeModel> get _filteredEmployees {
    var filtered = _employees;

    if (_activeFilter == 'active') {
      filtered = filtered.where((e) => e.isActive).toList();
    } else if (_activeFilter == 'inactive') {
      filtered = filtered.where((e) => !e.isActive).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.name.toLowerCase().contains(query) ||
            e.email.toLowerCase().contains(query) ||
            e.employeeId.toLowerCase().contains(query) ||
            (e.phone?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setActiveFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  Future<void> fetchEmployees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docs = await _firestoreService.getCollection(
        collection: FirebaseConstants.employeesCollection,
      );

      _employees =
          docs.docs.map((doc) => EmployeeModel.fromFirestore(doc)).toList();
      _employees.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _error = null;
    } catch (e) {
      _error = 'Failed to load employees: $e';
      _employees = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  EmployeeModel? getById(String id) {
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> addEmployee({
    required String name,
    required String email,
    required String employeeId,
    required String password,
    String? phone,
    bool isActive = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (_employees.any((e) => e.email.toLowerCase() == normalizedEmail)) {
        _error = 'An employee with this email already exists';
        return false;
      }
      if (_employees.any(
        (e) => e.employeeId.toLowerCase() == employeeId.trim().toLowerCase(),
      )) {
        _error = 'An employee with this ID already exists';
        return false;
      }

      final authUid = await _authService.createEmployeeAuthUser(
        email: normalizedEmail,
        password: password,
      );

      final now = DateTime.now();
      final employee = EmployeeModel(
        id: '',
        name: name.trim(),
        email: normalizedEmail,
        employeeId: employeeId.trim(),
        phone: _nullableTrim(phone),
        authUid: authUid,
        isActive: isActive,
        createdAt: now,
        updatedAt: now,
      );

      await _firestoreService.addDocument(
        collection: FirebaseConstants.employeesCollection,
        data: employee.toFirestore(),
      );

      await fetchEmployees();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEmployee({
    required String id,
    required String name,
    required String email,
    required String employeeId,
    String? phone,
    bool? isActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (_employees.any(
        (e) => e.id != id && e.email.toLowerCase() == normalizedEmail,
      )) {
        _error = 'An employee with this email already exists';
        return false;
      }
      if (_employees.any(
        (e) =>
            e.id != id &&
            e.employeeId.toLowerCase() == employeeId.trim().toLowerCase(),
      )) {
        _error = 'An employee with this ID already exists';
        return false;
      }

      final data = <String, dynamic>{
        'name': name.trim(),
        'email': normalizedEmail,
        'employeeId': employeeId.trim(),
        'phone': _nullableTrim(phone),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      if (isActive != null) {
        data['isActive'] = isActive;
      }

      await _firestoreService.updateDocument(
        collection: FirebaseConstants.employeesCollection,
        docId: id,
        data: data,
      );

      await fetchEmployees();
      return true;
    } catch (e) {
      _error = 'Failed to update employee: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email.trim().toLowerCase());
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.deleteDocument(
        collection: FirebaseConstants.employeesCollection,
        docId: id,
      );
      await fetchEmployees();
      return true;
    } catch (e) {
      _error = 'Failed to delete employee: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleEmployeeActive(String id, bool isActive) async {
    try {
      await _firestoreService.updateDocument(
        collection: FirebaseConstants.employeesCollection,
        docId: id,
        data: {
          'isActive': isActive,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );
      await fetchEmployees();
      return true;
    } catch (e) {
      _error = 'Failed to update employee status: $e';
      return false;
    }
  }

  String? _nullableTrim(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

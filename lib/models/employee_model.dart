import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for Employee (profile + Firebase Auth uid for employee portal)
class EmployeeModel {
  final String id;
  final String name;
  final String email;
  final String employeeId;
  final String? phone;
  final String? authUid;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.email,
    required this.employeeId,
    this.phone,
    this.authUid,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmployeeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmployeeModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      employeeId: data['employeeId'] ?? '',
      phone: data['phone'],
      authUid: data['authUid'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'employeeId': employeeId,
      'phone': phone,
      'authUid': authUid,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? email,
    String? employeeId,
    String? phone,
    String? authUid,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      phone: phone ?? this.phone,
      authUid: authUid ?? this.authUid,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Lead model for customer inquiries
class LeadModel {
  final String id;
  final String customerName;
  final String phoneNumber;
  final String productName;
  final String productId;
  final bool isContacted;
  final DateTime createdAt;

  LeadModel({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.productName,
    required this.productId,
    this.isContacted = false,
    required this.createdAt,
  });

  /// Create LeadModel from Firestore document
  factory LeadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeadModel(
      id: doc.id,
      customerName: data['customerName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      productName: data['productName'] ?? '',
      productId: data['productId'] ?? '',
      isContacted: data['isContacted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert LeadModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'productName': productName,
      'productId': productId,
      'isContacted': isContacted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  LeadModel copyWith({
    String? id,
    String? customerName,
    String? phoneNumber,
    String? productName,
    String? productId,
    bool? isContacted,
    DateTime? createdAt,
  }) {
    return LeadModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      productName: productName ?? this.productName,
      productId: productId ?? this.productId,
      isContacted: isContacted ?? this.isContacted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

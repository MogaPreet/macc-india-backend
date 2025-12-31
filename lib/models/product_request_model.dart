import 'package:cloud_firestore/cloud_firestore.dart';

/// Product Request status values
class RequestStatus {
  static const String pending = 'pending';
  static const String contacted = 'contacted';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static List<String> get values => [pending, contacted, completed, cancelled];

  static String getDisplayName(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case contacted:
        return 'Contacted';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }
}

/// Model for Product Request (user inquiries from website)
class ProductRequestModel {
  final String id;
  final String productId;
  final String productName;
  final String productSlug;
  final String customerName;
  final String customerPhone;
  final String status;
  final DateTime createdAt;

  ProductRequestModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSlug,
    required this.customerName,
    required this.customerPhone,
    this.status = RequestStatus.pending,
    required this.createdAt,
  });

  /// Create from Firestore document
  factory ProductRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductRequestModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productSlug: data['productSlug'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      status: data['status'] ?? RequestStatus.pending,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'productSlug': productSlug,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  ProductRequestModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productSlug,
    String? customerName,
    String? customerPhone,
    String? status,
    DateTime? createdAt,
  }) {
    return ProductRequestModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSlug: productSlug ?? this.productSlug,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

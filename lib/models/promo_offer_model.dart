import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for Promo Offer
class PromoOfferModel {
  final String id;
  final String title;
  final String? subtitle;
  final String backgroundImage;
  final List<String> productIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  PromoOfferModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.backgroundImage,
    required this.productIds,
    this.startDate,
    this.endDate,
    this.isActive = false,
    required this.createdAt,
  });

  /// Check if offer is currently valid (within date range)
  bool get isCurrentlyValid {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// Check if offer has expired
  bool get hasExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Get status text
  String get statusText {
    if (!isActive) return 'Inactive';
    if (hasExpired) return 'Expired';
    if (startDate != null && DateTime.now().isBefore(startDate!)) {
      return 'Scheduled';
    }
    return 'Active';
  }

  /// Create from Firestore document
  factory PromoOfferModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<String> productIdsList = [];
    if (data['productIds'] != null) {
      productIdsList = List<String>.from(data['productIds']);
    }

    return PromoOfferModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      backgroundImage: data['backgroundImage'] ?? '',
      productIds: productIdsList,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'backgroundImage': backgroundImage,
      'productIds': productIds,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  PromoOfferModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? backgroundImage,
    List<String>? productIds,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return PromoOfferModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      productIds: productIds ?? this.productIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Banner model for hero images
class BannerModel {
  final String id;
  final String imageUrl;
  final int order; // For sorting/ordering banners
  final bool isActive;
  final DateTime createdAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.order,
    this.isActive = true,
    required this.createdAt,
  });

  /// Create BannerModel from Firestore document
  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert BannerModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'order': order,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  BannerModel copyWith({
    String? id,
    String? imageUrl,
    int? order,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for Brand
class BrandModel {
  final String id;
  final String name;
  final String? logo;
  final String? color;
  final bool isActive;
  final DateTime createdAt;

  BrandModel({
    required this.id,
    required this.name,
    this.logo,
    this.color,
    this.isActive = true,
    required this.createdAt,
  });

  /// Create from Firestore document
  factory BrandModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BrandModel(
      id: doc.id,
      name: data['name'] ?? '',
      logo: data['logo'],
      color: data['color'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'logo': logo,
      'color': color,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  BrandModel copyWith({
    String? id,
    String? name,
    String? logo,
    String? color,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

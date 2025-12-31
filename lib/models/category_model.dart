import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for Category
class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final String? color;
  final String? image;
  final int? order;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
    this.image,
    this.order,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create CategoryModel from Firestore document
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      slug: data['slug'] ?? '',
      icon: data['icon'],
      color: data['color'],
      image: data['image'],
      order: data['order'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert CategoryModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'slug': slug,
      'icon': icon,
      'color': color,
      'image': image,
      'order': order,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  CategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? icon,
    String? color,
    String? image,
    int? order,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      image: image ?? this.image,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Generate a URL-friendly slug from the name
  static String generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }
}

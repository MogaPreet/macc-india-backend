import 'package:cloud_firestore/cloud_firestore.dart';

/// One line item inside a product combo (references a catalog product).
class ComboComponent {
  final String productId;
  final int quantity;
  final int sortOrder;

  /// Denormalized label for admin / fallback when the product doc is missing.
  final String? productNameSnapshot;

  const ComboComponent({
    required this.productId,
    this.quantity = 1,
    this.sortOrder = 0,
    this.productNameSnapshot,
  });

  factory ComboComponent.fromMap(Map<String, dynamic> data) {
    return ComboComponent(
      productId: data['productId'] as String? ?? '',
      quantity: (data['quantity'] is int)
          ? data['quantity'] as int
          : int.tryParse('${data['quantity']}') ?? 1,
      sortOrder: (data['sortOrder'] is int)
          ? data['sortOrder'] as int
          : int.tryParse('${data['sortOrder']}') ?? 0,
      productNameSnapshot: data['productNameSnapshot'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantity': quantity,
      'sortOrder': sortOrder,
      'productNameSnapshot': productNameSnapshot,
    };
  }

  ComboComponent copyWith({
    String? productId,
    int? quantity,
    int? sortOrder,
    String? productNameSnapshot,
  }) {
    return ComboComponent(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      sortOrder: sortOrder ?? this.sortOrder,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
    );
  }
}

/// Sellable bundle of two or more products (Firestore: `combos` collection).
class ProductComboModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final List<ComboComponent> components;
  final double price;
  final double? originalPrice;
  final int stock;
  final bool isFeatured;
  final bool isActive;
  final List<String> images;
  final String? youtubeUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductComboModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.components,
    required this.price,
    this.originalPrice,
    this.stock = 1,
    this.isFeatured = false,
    this.isActive = true,
    required this.images,
    this.youtubeUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  String get mainImage => images.isNotEmpty ? images.first : '';

  int get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  static String generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  factory ProductComboModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<String> imagesList = [];
    if (data['images'] != null) {
      imagesList = List<String>.from(data['images'] as List);
    }

    List<ComboComponent> comp = [];
    if (data['components'] != null) {
      comp = (data['components'] as List)
          .map((e) => ComboComponent.fromMap(e as Map<String, dynamic>))
          .toList();
      comp.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    return ProductComboModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      slug: data['slug'] as String? ?? '',
      description: data['description'] as String?,
      components: comp,
      price: (data['price'] ?? 0).toDouble(),
      originalPrice: data['originalPrice']?.toDouble(),
      stock: data['stock'] is int
          ? data['stock'] as int
          : int.tryParse('${data['stock']}') ?? 1,
      isFeatured: data['isFeatured'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      images: imagesList,
      youtubeUrl: data['youtubeUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final sorted = List<ComboComponent>.from(components)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return {
      'name': name,
      'slug': slug,
      'description': description,
      'components': sorted.map((c) => c.toMap()).toList(),
      'price': price,
      'originalPrice': originalPrice,
      'stock': stock,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'images': images,
      'youtubeUrl': youtubeUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ProductComboModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    List<ComboComponent>? components,
    double? price,
    double? originalPrice,
    int? stock,
    bool? isFeatured,
    bool? isActive,
    List<String>? images,
    String? youtubeUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductComboModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      components: components ?? this.components,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      stock: stock ?? this.stock,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      images: images ?? this.images,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Product specifications model
class ProductSpecs {
  final String? processor;
  final String? ram;
  final String? storage;
  final String? screen;
  final String? graphics;
  final String? battery;
  final String? os;
  final String? ports;
  final String? weight;

  ProductSpecs({
    this.processor,
    this.ram,
    this.storage,
    this.screen,
    this.graphics,
    this.battery,
    this.os,
    this.ports,
    this.weight,
  });

  factory ProductSpecs.fromMap(Map<String, dynamic>? data) {
    if (data == null) return ProductSpecs();
    return ProductSpecs(
      processor: data['processor'],
      ram: data['ram'],
      storage: data['storage'],
      screen: data['screen'],
      graphics: data['graphics'],
      battery: data['battery'],
      os: data['os'],
      ports: data['ports'],
      weight: data['weight'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'processor': processor,
      'ram': ram,
      'storage': storage,
      'screen': screen,
      'graphics': graphics,
      'battery': battery,
      'os': os,
      'ports': ports,
      'weight': weight,
    };
  }

  ProductSpecs copyWith({
    String? processor,
    String? ram,
    String? storage,
    String? screen,
    String? graphics,
    String? battery,
    String? os,
    String? ports,
    String? weight,
  }) {
    return ProductSpecs(
      processor: processor ?? this.processor,
      ram: ram ?? this.ram,
      storage: storage ?? this.storage,
      screen: screen ?? this.screen,
      graphics: graphics ?? this.graphics,
      battery: battery ?? this.battery,
      os: os ?? this.os,
      ports: ports ?? this.ports,
      weight: weight ?? this.weight,
    );
  }

  /// Check if any spec is present
  bool get hasAnySpec =>
      processor != null ||
      ram != null ||
      storage != null ||
      screen != null ||
      graphics != null ||
      battery != null ||
      os != null ||
      ports != null ||
      weight != null;
}

/// Included item model (accessories, chargers, etc.)
class IncludedItem {
  final String name;
  final String icon;
  final bool included;

  IncludedItem({required this.name, required this.icon, this.included = true});

  factory IncludedItem.fromMap(Map<String, dynamic> data) {
    return IncludedItem(
      name: data['name'] ?? '',
      icon: data['icon'] ?? '',
      included: data['included'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'icon': icon, 'included': included};
  }

  IncludedItem copyWith({String? name, String? icon, bool? included}) {
    return IncludedItem(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      included: included ?? this.included,
    );
  }
}

/// Warranty information model
class ProductWarranty {
  final String? duration;
  final String? type;
  final String? description;

  ProductWarranty({this.duration, this.type, this.description});

  factory ProductWarranty.fromMap(Map<String, dynamic>? data) {
    if (data == null) return ProductWarranty();
    return ProductWarranty(
      duration: data['duration'],
      type: data['type'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'duration': duration, 'type': type, 'description': description};
  }

  ProductWarranty copyWith({
    String? duration,
    String? type,
    String? description,
  }) {
    return ProductWarranty(
      duration: duration ?? this.duration,
      type: type ?? this.type,
      description: description ?? this.description,
    );
  }

  bool get hasWarranty =>
      duration != null || type != null || description != null;
}

/// Product condition enum values
class ProductCondition {
  static const String likeNew = 'Like New';
  static const String excellent = 'Excellent';
  static const String good = 'Good';
  static const String fair = 'Fair';

  static List<String> get values => [likeNew, excellent, good, fair];
}

/// Model for Product
class ProductModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String brandId;
  final String brandName;

  /// List of category IDs this product belongs to
  final List<String> categoryIds;

  /// List of category names this product belongs to
  final List<String> categoryNames;

  /// Legacy single category ID (for backward compatibility)
  @Deprecated('Use categoryIds instead')
  String get categoryId => categoryIds.isNotEmpty ? categoryIds.first : '';

  /// Legacy single category name (for backward compatibility)
  @Deprecated('Use categoryNames instead')
  String get categoryName =>
      categoryNames.isNotEmpty ? categoryNames.first : '';
  final double price;
  final double? originalPrice;
  final String condition;
  final int stock;
  final bool isFeatured;
  final bool isActive;
  final List<String> images;
  final ProductSpecs specs;
  final List<IncludedItem> includedItems;
  final ProductWarranty? warranty;
  final String? youtubeUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.brandId,
    required this.brandName,
    required this.categoryIds,
    required this.categoryNames,
    required this.price,
    this.originalPrice,
    required this.condition,
    this.stock = 1,
    this.isFeatured = false,
    this.isActive = true,
    required this.images,
    required this.specs,
    required this.includedItems,
    this.warranty,
    this.youtubeUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Helper to get the main display image
  String get mainImage => images.isNotEmpty ? images.first : '';

  /// Calculate discount percentage
  int get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  /// Check if product has discount
  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  /// Check if product is in stock
  bool get inStock => stock > 0;

  /// Generate slug from name
  static String generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  /// Create ProductModel from Firestore document
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse images array
    List<String> imagesList = [];
    if (data['images'] != null) {
      imagesList = List<String>.from(data['images']);
    }

    // Parse included items
    List<IncludedItem> includedItemsList = [];
    if (data['includedItems'] != null) {
      includedItemsList = (data['includedItems'] as List)
          .map((item) => IncludedItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      slug: data['slug'] ?? '',
      description: data['description'],
      brandId: data['brandId'] ?? '',
      brandName: data['brandName'] ?? '',
      // Handle both new (list) and legacy (single) category formats
      categoryIds: data['categoryIds'] != null
          ? List<String>.from(data['categoryIds'])
          : (data['categoryId'] != null &&
                    data['categoryId'].toString().isNotEmpty
                ? [data['categoryId'] as String]
                : <String>[]),
      categoryNames: data['categoryNames'] != null
          ? List<String>.from(data['categoryNames'])
          : (data['categoryName'] != null &&
                    data['categoryName'].toString().isNotEmpty
                ? [data['categoryName'] as String]
                : <String>[]),
      price: (data['price'] ?? 0).toDouble(),
      originalPrice: data['originalPrice']?.toDouble(),
      condition: data['condition'] ?? ProductCondition.good,
      stock: data['stock'] ?? 1,
      isFeatured: data['isFeatured'] ?? false,
      isActive: data['isActive'] ?? true,
      images: imagesList,
      specs: ProductSpecs.fromMap(data['specs']),
      includedItems: includedItemsList,
      warranty: data['warranty'] != null
          ? ProductWarranty.fromMap(data['warranty'])
          : null,
      youtubeUrl: data['youtubeUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert ProductModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'slug': slug,
      'description': description,
      'brandId': brandId,
      'brandName': brandName,
      'categoryIds': categoryIds,
      'categoryNames': categoryNames,
      'price': price,
      'originalPrice': originalPrice,
      'condition': condition,
      'stock': stock,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'images': images,
      'specs': specs.toMap(),
      'includedItems': includedItems.map((item) => item.toMap()).toList(),
      'warranty': warranty?.toMap(),
      'youtubeUrl': youtubeUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  ProductModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? brandId,
    String? brandName,
    List<String>? categoryIds,
    List<String>? categoryNames,
    double? price,
    double? originalPrice,
    String? condition,
    int? stock,
    bool? isFeatured,
    bool? isActive,
    List<String>? images,
    ProductSpecs? specs,
    List<IncludedItem>? includedItems,
    ProductWarranty? warranty,
    String? youtubeUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      categoryIds: categoryIds ?? this.categoryIds,
      categoryNames: categoryNames ?? this.categoryNames,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      condition: condition ?? this.condition,
      stock: stock ?? this.stock,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      images: images ?? this.images,
      specs: specs ?? this.specs,
      includedItems: includedItems ?? this.includedItems,
      warranty: warranty ?? this.warranty,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

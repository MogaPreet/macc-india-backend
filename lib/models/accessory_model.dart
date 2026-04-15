import 'package:cloud_firestore/cloud_firestore.dart';

/// Accessory type constants
class AccessoryTypeValues {
  static const String keyboard = 'keyboard';
  static const String mouse = 'mouse';
  static const String graphicCard = 'graphic_card';
  static const String charger = 'charger';
  static const String cable = 'cable';
  static const String casecover = 'case_cover';
  static const String stand = 'stand';
  static const String hub = 'hub';
  static const String audio = 'audio';
  static const String other = 'other';

  static List<String> get values => [
        keyboard,
        mouse,
        graphicCard,
        charger,
        cable,
        casecover,
        stand,
        hub,
        audio,
        other,
      ];

  /// Get display label for accessory type
  static String label(String type) {
    switch (type) {
      case keyboard:
        return 'Keyboard';
      case mouse:
        return 'Mouse';
      case graphicCard:
        return 'Graphic Card';
      case charger:
        return 'Charger / Adapter';
      case cable:
        return 'Cable';
      case casecover:
        return 'Case / Cover';
      case stand:
        return 'Stand / Mount';
      case hub:
        return 'Hub / Dock';
      case audio:
        return 'Audio Accessory';
      case other:
        return 'Other';
      default:
        return 'Other';
    }
  }

  /// Get icon string for accessory type
  static String icon(String type) {
    switch (type) {
      case keyboard:
        return '⌨️';
      case mouse:
        return '🖱️';
      case graphicCard:
        return '🖥️';
      case charger:
        return '🔌';
      case cable:
        return '🔗';
      case casecover:
        return '💼';
      case stand:
        return '🖥️';
      case hub:
        return '🔌';
      case audio:
        return '🎧';
      case other:
        return '📦';
      default:
        return '📦';
    }
  }
}

/// Accessory condition enum values (reuse same as products)
class AccessoryCondition {
  static const String brandNew = 'Brand New';
  static const String likeNew = 'Like New';
  static const String excellent = 'Excellent';
  static const String good = 'Good';
  static const String fair = 'Fair';

  static List<String> get values => [brandNew, likeNew, excellent, good, fair];
}

/// Accessory specifications model
/// Contains ALL possible spec fields across all accessory types.
/// Which fields are used depends on the accessoryType.
class AccessorySpecs {
  // --- Keyboard fields ---
  final String? layout;
  final String? switchType;
  final String? backlight;
  final String? keyCount;

  // --- Mouse fields ---
  final String? dpi;
  final String? sensorType;
  final String? buttons;

  // --- Graphic Card fields ---
  final String? gpuChipset;
  final String? vram;
  final String? clockSpeed;
  final String? memoryBus;
  final String? powerRequirement;
  final String? cooling;
  final String? cardLength;

  // --- Charger fields ---
  final String? wattage;
  final String? outputPorts;
  final String? fastCharging;
  final String? cableIncluded;

  // --- Cable fields ---
  final String? cableType;
  final String? cableLength;
  final String? dataTransfer;
  final String? powerDelivery;

  // --- Case/Cover fields ---
  final String? deviceCompatibility;
  final String? features;

  // --- Stand/Mount fields ---
  final String? standType;
  final String? adjustable;
  final String? weightCapacity;

  // --- Hub/Dock fields ---
  final String? inputPort;
  final String? hubOutputPorts;
  final String? powerPassthrough;

  // --- Audio fields ---
  final String? audioType;
  final String? driverSize;
  final String? noiseCancellation;
  final String? batteryLife;

  // --- Shared fields across types ---
  final String? connectivity;
  final String? compatibility;
  final String? material;
  final String? color;
  final String? dimensions;
  final String? weight;
  final String? ports;

  // --- Other/Generic fields ---
  final String? category;
  final String? keyFeature;

  AccessorySpecs({
    this.layout,
    this.switchType,
    this.backlight,
    this.keyCount,
    this.dpi,
    this.sensorType,
    this.buttons,
    this.gpuChipset,
    this.vram,
    this.clockSpeed,
    this.memoryBus,
    this.powerRequirement,
    this.cooling,
    this.cardLength,
    this.wattage,
    this.outputPorts,
    this.fastCharging,
    this.cableIncluded,
    this.cableType,
    this.cableLength,
    this.dataTransfer,
    this.powerDelivery,
    this.deviceCompatibility,
    this.features,
    this.standType,
    this.adjustable,
    this.weightCapacity,
    this.inputPort,
    this.hubOutputPorts,
    this.powerPassthrough,
    this.audioType,
    this.driverSize,
    this.noiseCancellation,
    this.batteryLife,
    this.connectivity,
    this.compatibility,
    this.material,
    this.color,
    this.dimensions,
    this.weight,
    this.ports,
    this.category,
    this.keyFeature,
  });

  factory AccessorySpecs.fromMap(Map<String, dynamic>? data) {
    if (data == null) return AccessorySpecs();
    return AccessorySpecs(
      layout: data['layout'],
      switchType: data['switchType'],
      backlight: data['backlight'],
      keyCount: data['keyCount'],
      dpi: data['dpi'],
      sensorType: data['sensorType'],
      buttons: data['buttons'],
      gpuChipset: data['gpuChipset'],
      vram: data['vram'],
      clockSpeed: data['clockSpeed'],
      memoryBus: data['memoryBus'],
      powerRequirement: data['powerRequirement'],
      cooling: data['cooling'],
      cardLength: data['cardLength'],
      wattage: data['wattage'],
      outputPorts: data['outputPorts'],
      fastCharging: data['fastCharging'],
      cableIncluded: data['cableIncluded'],
      cableType: data['cableType'],
      cableLength: data['cableLength'],
      dataTransfer: data['dataTransfer'],
      powerDelivery: data['powerDelivery'],
      deviceCompatibility: data['deviceCompatibility'],
      features: data['features'],
      standType: data['standType'],
      adjustable: data['adjustable'],
      weightCapacity: data['weightCapacity'],
      inputPort: data['inputPort'],
      hubOutputPorts: data['hubOutputPorts'],
      powerPassthrough: data['powerPassthrough'],
      audioType: data['audioType'],
      driverSize: data['driverSize'],
      noiseCancellation: data['noiseCancellation'],
      batteryLife: data['batteryLife'],
      connectivity: data['connectivity'],
      compatibility: data['compatibility'],
      material: data['material'],
      color: data['color'],
      dimensions: data['dimensions'],
      weight: data['weight'],
      ports: data['ports'],
      category: data['category'],
      keyFeature: data['keyFeature'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'layout': layout,
      'switchType': switchType,
      'backlight': backlight,
      'keyCount': keyCount,
      'dpi': dpi,
      'sensorType': sensorType,
      'buttons': buttons,
      'gpuChipset': gpuChipset,
      'vram': vram,
      'clockSpeed': clockSpeed,
      'memoryBus': memoryBus,
      'powerRequirement': powerRequirement,
      'cooling': cooling,
      'cardLength': cardLength,
      'wattage': wattage,
      'outputPorts': outputPorts,
      'fastCharging': fastCharging,
      'cableIncluded': cableIncluded,
      'cableType': cableType,
      'cableLength': cableLength,
      'dataTransfer': dataTransfer,
      'powerDelivery': powerDelivery,
      'deviceCompatibility': deviceCompatibility,
      'features': features,
      'standType': standType,
      'adjustable': adjustable,
      'weightCapacity': weightCapacity,
      'inputPort': inputPort,
      'hubOutputPorts': hubOutputPorts,
      'powerPassthrough': powerPassthrough,
      'audioType': audioType,
      'driverSize': driverSize,
      'noiseCancellation': noiseCancellation,
      'batteryLife': batteryLife,
      'connectivity': connectivity,
      'compatibility': compatibility,
      'material': material,
      'color': color,
      'dimensions': dimensions,
      'weight': weight,
      'ports': ports,
      'category': category,
      'keyFeature': keyFeature,
    };
  }
}

/// Warranty information model for accessories
class AccessoryWarranty {
  final String? duration;
  final String? type;
  final String? description;

  AccessoryWarranty({this.duration, this.type, this.description});

  factory AccessoryWarranty.fromMap(Map<String, dynamic>? data) {
    if (data == null) return AccessoryWarranty();
    return AccessoryWarranty(
      duration: data['duration'],
      type: data['type'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'duration': duration, 'type': type, 'description': description};
  }

  bool get hasWarranty =>
      duration != null || type != null || description != null;
}

/// Model for Accessory
class AccessoryModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String brandId;
  final String brandName;
  final List<String> categoryIds;
  final List<String> categoryNames;
  final String accessoryType;
  final double price;
  final double? originalPrice;
  final String condition;
  final int stock;
  final bool isFeatured;
  final bool isActive;
  final List<String> images;
  final AccessorySpecs specs;
  final AccessoryWarranty? warranty;
  final String? youtubeUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccessoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.brandId,
    required this.brandName,
    required this.categoryIds,
    required this.categoryNames,
    required this.accessoryType,
    required this.price,
    this.originalPrice,
    required this.condition,
    this.stock = 1,
    this.isFeatured = false,
    this.isActive = true,
    required this.images,
    required this.specs,
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

  /// Check if accessory has discount
  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  /// Check if accessory is in stock
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

  /// Create AccessoryModel from Firestore document
  factory AccessoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<String> imagesList = [];
    if (data['images'] != null) {
      imagesList = List<String>.from(data['images']);
    }

    return AccessoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      slug: data['slug'] ?? '',
      description: data['description'],
      brandId: data['brandId'] ?? '',
      brandName: data['brandName'] ?? '',
      categoryIds: data['categoryIds'] != null
          ? List<String>.from(data['categoryIds'])
          : <String>[],
      categoryNames: data['categoryNames'] != null
          ? List<String>.from(data['categoryNames'])
          : <String>[],
      accessoryType: data['accessoryType'] ?? AccessoryTypeValues.other,
      price: (data['price'] ?? 0).toDouble(),
      originalPrice: data['originalPrice']?.toDouble(),
      condition: data['condition'] ?? AccessoryCondition.good,
      stock: data['stock'] ?? 1,
      isFeatured: data['isFeatured'] ?? false,
      isActive: data['isActive'] ?? true,
      images: imagesList,
      specs: AccessorySpecs.fromMap(data['specs']),
      warranty: data['warranty'] != null
          ? AccessoryWarranty.fromMap(data['warranty'])
          : null,
      youtubeUrl: data['youtubeUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert AccessoryModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'slug': slug,
      'description': description,
      'brandId': brandId,
      'brandName': brandName,
      'categoryIds': categoryIds,
      'categoryNames': categoryNames,
      'accessoryType': accessoryType,
      'price': price,
      'originalPrice': originalPrice,
      'condition': condition,
      'stock': stock,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'images': images,
      'specs': specs.toMap(),
      'warranty': warranty?.toMap(),
      'youtubeUrl': youtubeUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  AccessoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? brandId,
    String? brandName,
    List<String>? categoryIds,
    List<String>? categoryNames,
    String? accessoryType,
    double? price,
    double? originalPrice,
    String? condition,
    int? stock,
    bool? isFeatured,
    bool? isActive,
    List<String>? images,
    AccessorySpecs? specs,
    AccessoryWarranty? warranty,
    String? youtubeUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccessoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      categoryIds: categoryIds ?? this.categoryIds,
      categoryNames: categoryNames ?? this.categoryNames,
      accessoryType: accessoryType ?? this.accessoryType,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      condition: condition ?? this.condition,
      stock: stock ?? this.stock,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      images: images ?? this.images,
      specs: specs ?? this.specs,
      warranty: warranty ?? this.warranty,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

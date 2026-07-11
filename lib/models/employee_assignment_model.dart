import 'package:cloud_firestore/cloud_firestore.dart';

/// Assignment status values for employee progress tracking
class AssignmentStatus {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String contacted = 'contacted';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static List<String> get values => [
        pending,
        inProgress,
        contacted,
        completed,
        cancelled,
      ];

  static String getDisplayName(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case inProgress:
        return 'In Progress';
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

/// Where the customer heard about MACC
class ReferralSource {
  static const String instagram = 'instagram';
  static const String facebook = 'facebook';
  static const String whatsapp = 'whatsapp';
  static const String walkIn = 'walk_in';
  static const String google = 'google';
  static const String referral = 'referral';
  static const String other = 'other';

  static List<String> get values => [
        instagram,
        facebook,
        whatsapp,
        walkIn,
        google,
        referral,
        other,
      ];

  static String getDisplayName(String source) {
    switch (source) {
      case instagram:
        return 'Instagram';
      case facebook:
        return 'Facebook';
      case whatsapp:
        return 'WhatsApp';
      case walkIn:
        return 'Walk-in';
      case google:
        return 'Google';
      case referral:
        return 'Referral';
      case other:
        return 'Other';
      default:
        return source;
    }
  }
}

/// Single remark history entry
class RemarkHistoryEntry {
  final String text;
  final DateTime updatedAt;
  final String updatedBy;

  RemarkHistoryEntry({
    required this.text,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory RemarkHistoryEntry.fromMap(Map<String, dynamic> data) {
    return RemarkHistoryEntry(
      text: data['text'] ?? '',
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: data['updatedBy'] ?? 'admin',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }
}

/// Product interest line item on an assignment
class AssignmentProductInterest {
  final String productId;
  final String productName;
  final String? productType;
  final String? brandName;

  AssignmentProductInterest({
    required this.productId,
    required this.productName,
    this.productType,
    this.brandName,
  });

  factory AssignmentProductInterest.fromMap(Map<String, dynamic> data) {
    return AssignmentProductInterest(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productType: data['productType'],
      brandName: data['brandName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productType': productType,
      'brandName': brandName,
    };
  }
}

/// Guided discovery notes from employee visit
class AssignmentDiscovery {
  final String useCase;
  final String budgetRange;
  final String currentDevice;
  final String understandingNotes;
  final String needsNotes;

  const AssignmentDiscovery({
    this.useCase = '',
    this.budgetRange = '',
    this.currentDevice = '',
    this.understandingNotes = '',
    this.needsNotes = '',
  });

  factory AssignmentDiscovery.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const AssignmentDiscovery();
    return AssignmentDiscovery(
      useCase: data['useCase'] ?? '',
      budgetRange: data['budgetRange'] ?? '',
      currentDevice: data['currentDevice'] ?? '',
      understandingNotes: data['understandingNotes'] ?? '',
      needsNotes: data['needsNotes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'useCase': useCase,
      'budgetRange': budgetRange,
      'currentDevice': currentDevice,
      'understandingNotes': understandingNotes,
      'needsNotes': needsNotes,
    };
  }

  bool get isEmpty =>
      useCase.isEmpty &&
      budgetRange.isEmpty &&
      currentDevice.isEmpty &&
      understandingNotes.isEmpty &&
      needsNotes.isEmpty;
}

/// Model for employee assignment (customer + product work item)
class EmployeeAssignmentModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String productId;
  final String productName;
  final List<AssignmentProductInterest> products;
  final String? referralSource;
  final String? referralOther;
  final AssignmentDiscovery discovery;
  final String status;
  final String remarks;
  final List<RemarkHistoryEntry> remarkHistory;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmployeeAssignmentModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.productId,
    required this.productName,
    this.products = const [],
    this.referralSource,
    this.referralOther,
    this.discovery = const AssignmentDiscovery(),
    this.status = AssignmentStatus.pending,
    this.remarks = '',
    this.remarkHistory = const [],
    this.createdBy = 'admin',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display names for all interested products
  List<String> get productDisplayNames {
    if (products.isNotEmpty) {
      return products.map((p) => p.productName).toList();
    }
    if (productName.isNotEmpty) return [productName];
    return [];
  }

  factory EmployeeAssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final historyRaw = data['remarkHistory'] as List<dynamic>? ?? [];
    final productsRaw = data['products'] as List<dynamic>? ?? [];
    final products = productsRaw
        .map((e) => AssignmentProductInterest.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();

    final productId = data['productId'] ?? '';
    final productName = data['productName'] ?? '';

    return EmployeeAssignmentModel(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerEmail: data['customerEmail'],
      productId: productId.isNotEmpty
          ? productId
          : (products.isNotEmpty ? products.first.productId : ''),
      productName: productName.isNotEmpty
          ? productName
          : (products.isNotEmpty ? products.first.productName : ''),
      products: products,
      referralSource: data['referralSource'],
      referralOther: data['referralOther'],
      discovery: AssignmentDiscovery.fromMap(
        data['discovery'] != null
            ? Map<String, dynamic>.from(data['discovery'] as Map)
            : null,
      ),
      status: data['status'] ?? AssignmentStatus.pending,
      remarks: data['remarks'] ?? '',
      remarkHistory: historyRaw
          .map((e) => RemarkHistoryEntry.fromMap(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      createdBy: data['createdBy'] ?? 'admin',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'productId': productId,
      'productName': productName,
      'products': products.map((e) => e.toMap()).toList(),
      'referralSource': referralSource,
      'referralOther': referralOther,
      'discovery': discovery.toMap(),
      'status': status,
      'remarks': remarks,
      'remarkHistory': remarkHistory.map((e) => e.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  EmployeeAssignmentModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? productId,
    String? productName,
    List<AssignmentProductInterest>? products,
    String? referralSource,
    String? referralOther,
    AssignmentDiscovery? discovery,
    String? status,
    String? remarks,
    List<RemarkHistoryEntry>? remarkHistory,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeAssignmentModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      products: products ?? this.products,
      referralSource: referralSource ?? this.referralSource,
      referralOther: referralOther ?? this.referralOther,
      discovery: discovery ?? this.discovery,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      remarkHistory: remarkHistory ?? this.remarkHistory,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

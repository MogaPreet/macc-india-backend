import 'package:cloud_firestore/cloud_firestore.dart';

/// Contact request status values
class ContactRequestStatus {
  static const String pending = 'pending';
  static const String read = 'read';
  static const String replied = 'replied';
  static const String resolved = 'resolved';

  static List<String> get values => [pending, read, replied, resolved];

  static String getDisplayName(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case read:
        return 'Read';
      case replied:
        return 'Replied';
      case resolved:
        return 'Resolved';
      default:
        return status;
    }
  }
}

/// Contact request subject types
class ContactSubject {
  static const String general = 'general';
  static const String product = 'product';
  static const String support = 'support';
  static const String warranty = 'warranty';
  static const String bulk = 'bulk';
  static const String other = 'other';

  static List<String> get values => [
    general,
    product,
    support,
    warranty,
    bulk,
    other,
  ];

  static String getDisplayName(String subject) {
    switch (subject) {
      case general:
        return 'General Inquiry';
      case product:
        return 'Product Question';
      case support:
        return 'Support';
      case warranty:
        return 'Warranty';
      case bulk:
        return 'Bulk Order';
      case other:
        return 'Other';
      default:
        return subject;
    }
  }
}

/// Model for Contact Request (website contact form submissions)
class ContactRequestModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;

  ContactRequestModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.subject,
    required this.message,
    this.status = ContactRequestStatus.pending,
    required this.createdAt,
  });

  /// Create from Firestore document
  factory ContactRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContactRequestModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      subject: data['subject'] ?? ContactSubject.general,
      message: data['message'] ?? '',
      status: data['status'] ?? ContactRequestStatus.pending,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'subject': subject,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  ContactRequestModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? subject,
    String? message,
    String? status,
    DateTime? createdAt,
  }) {
    return ContactRequestModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

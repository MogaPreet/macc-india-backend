import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for SEO blog posts
class BlogModel {
  final String id;
  final String title;
  final String slug;
  final String excerpt;
  final String? content;
  final String? metaTitle;
  final String? metaDescription;
  final List<String> keywords;
  final String? coverImage;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  BlogModel({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt = '',
    this.content,
    this.metaTitle,
    this.metaDescription,
    this.keywords = const [],
    this.coverImage,
    this.isPublished = false,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BlogModel(
      id: doc.id,
      title: data['title'] ?? '',
      slug: data['slug'] ?? '',
      excerpt: data['excerpt'] ?? '',
      content: data['content'],
      metaTitle: data['metaTitle'],
      metaDescription: data['metaDescription'],
      keywords: data['keywords'] != null
          ? List<String>.from(data['keywords'])
          : [],
      coverImage: data['coverImage'],
      isPublished: data['isPublished'] ?? false,
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'slug': slug,
      'excerpt': excerpt,
      'content': content,
      'metaTitle': metaTitle,
      'metaDescription': metaDescription,
      'keywords': keywords,
      'coverImage': coverImage,
      'isPublished': isPublished,
      'publishedAt': publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BlogModel copyWith({
    String? id,
    String? title,
    String? slug,
    String? excerpt,
    String? content,
    String? metaTitle,
    String? metaDescription,
    List<String>? keywords,
    String? coverImage,
    bool? isPublished,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BlogModel(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      excerpt: excerpt ?? this.excerpt,
      content: content ?? this.content,
      metaTitle: metaTitle ?? this.metaTitle,
      metaDescription: metaDescription ?? this.metaDescription,
      keywords: keywords ?? this.keywords,
      coverImage: coverImage ?? this.coverImage,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }
}

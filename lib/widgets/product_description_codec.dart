import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

/// Encodes/decodes product descriptions as Quill Delta JSON for WYSIWYG storage.
///
/// Legacy plain-text descriptions (no JSON) load as a single paragraph.
class ProductDescriptionCodec {
  ProductDescriptionCodec._();

  static Document documentFromStored(String? raw) {
    if (raw == null || raw.isEmpty) return Document();
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return Document();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        return Document.fromJson(decoded);
      }
    } catch (_) {
      // Treat as legacy plain text
    }
    return Document.fromJson([
      {'insert': '$trimmed\n'},
    ]);
  }

  static String serialize(QuillController controller) {
    final deltaJson = controller.document.toDelta().toJson();
    return jsonEncode(deltaJson);
  }

  /// Returns `null` when there is no visible content (matches previous optional field).
  static String? serializeNullable(QuillController controller) {
    final plain = controller.document.toPlainText().trim();
    if (plain.isEmpty) return null;
    return serialize(controller);
  }
}

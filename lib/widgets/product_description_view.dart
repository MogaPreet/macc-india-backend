import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'product_description_codec.dart';

/// Read-only rich text for a stored product description (Quill Delta JSON or legacy plain text).
class ProductDescriptionView extends StatefulWidget {
  const ProductDescriptionView({
    super.key,
    required this.description,
    this.padding = EdgeInsets.zero,
    this.minHeight = 0,
  });

  final String? description;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  @override
  State<ProductDescriptionView> createState() => _ProductDescriptionViewState();
}

class _ProductDescriptionViewState extends State<ProductDescriptionView> {
  late final QuillController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: ProductDescriptionCodec.documentFromStored(widget.description),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
    _focusNode = FocusNode(canRequestFocus: false);
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant ProductDescriptionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.description != widget.description) {
      _controller.document = ProductDescriptionCodec.documentFromStored(
        widget.description,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.description;
    if (raw == null || raw.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding,
      child: QuillEditor.basic(
        focusNode: _focusNode,
        scrollController: _scrollController,
        controller: _controller,
        config: QuillEditorConfig(
          scrollable: false,
          expands: false,
          minHeight: widget.minHeight,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../core/constants/colors.dart';

/// Rich-text description field (Quill) with a compact toolbar: bold, italic,
/// underline, strike, colors, line height.
class ProductDescriptionEditor extends StatelessWidget {
  const ProductDescriptionEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    this.label = 'Description',
    this.hintText = 'Enter product description',
    this.minHeight = 200,
  });

  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final String label;
  final String hintText;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
        contentPadding: EdgeInsets.zero,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            QuillSimpleToolbar(
              controller: controller,
              config: QuillSimpleToolbarConfig(
                showFontFamily: false,
                showFontSize: false,
                showInlineCode: false,
                showListNumbers: false,
                showListBullets: false,
                showListCheck: false,
                showCodeBlock: false,
                showQuote: false,
                showIndent: false,
                showLink: false,
                showUndo: false,
                showRedo: false,
                showSearchButton: false,
                showSubscript: false,
                showSuperscript: false,
                showHeaderStyle: false,
                showAlignmentButtons: false,
                showClearFormat: false,
                showLineHeightButton: true,
                showColorButton: true,
                showBackgroundColorButton: true,
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: true,
                multiRowsDisplay: true,
                decoration: const BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderColor),
                  ),
                ),
                iconTheme: const QuillIconTheme(
                  iconButtonUnselectedData: IconButtonData(
                    color: AppColors.textSecondary,
                  ),
                  iconButtonSelectedData: IconButtonData(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
            Theme(
              data: theme.copyWith(
                textTheme: theme.textTheme.copyWith(
                  bodyLarge: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              child: QuillEditor.basic(
                focusNode: focusNode,
                scrollController: scrollController,
                controller: controller,
                config: QuillEditorConfig(
                  scrollable: false,
                  expands: false,
                  minHeight: minHeight,
                  padding: const EdgeInsets.all(12),
                  placeholder: hintText,
                  customStyles: DefaultStyles(
                    placeHolder: DefaultTextBlockStyle(
                      TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 16,
                        height: 1.4,
                      ),
                      HorizontalSpacing.zero,
                      VerticalSpacing.zero,
                      VerticalSpacing.zero,
                      null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

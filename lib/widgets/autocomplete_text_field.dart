import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

/// A reusable autocomplete text field widget that provides suggestions
/// while allowing free-form input
class AutocompleteTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final List<String> suggestions;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;

  const AutocompleteTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    required this.suggestions,
    this.validator,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return suggestions.where((option) {
              return option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
            });
          },
          onSelected: (String selection) {
            controller.text = selection;
          },
          fieldViewBuilder:
              (
                BuildContext context,
                TextEditingController textEditingController,
                FocusNode fieldFocusNode,
                VoidCallback onFieldSubmitted,
              ) {
                // Sync the initial value
                if (textEditingController.text != controller.text) {
                  textEditingController.text = controller.text;
                }

                // Sync changes back to the original controller
                textEditingController.addListener(() {
                  if (controller.text != textEditingController.text) {
                    controller.text = textEditingController.text;
                  }
                });

                return TextFormField(
                  controller: textEditingController,
                  focusNode: fieldFocusNode,
                  decoration: InputDecoration(
                    labelText: labelText,
                    hintText: hintText,
                    suffixIcon: suggestions.isNotEmpty
                        ? const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textMuted,
                          )
                        : null,
                  ),
                  validator: validator,
                  onFieldSubmitted: (String value) {
                    onFieldSubmitted();
                  },
                );
              },
          optionsViewBuilder:
              (
                BuildContext context,
                AutocompleteOnSelected<String> onSelected,
                Iterable<String> options,
              ) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                        maxWidth: constraints.maxWidth,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () {
                              onSelected(option);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Text(
                                option,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
        );
      },
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import '../../widgets/image_uploader.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/utils/validators.dart';

/// Screen for editing an existing category
class EditCategoryScreen extends StatefulWidget {
  final CategoryModel category;

  const EditCategoryScreen({super.key, required this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _iconController;
  late TextEditingController _colorController;
  late TextEditingController _orderController;
  late bool _isActive;

  Uint8List? _newImageBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _slugController = TextEditingController(text: widget.category.slug);
    _iconController = TextEditingController(text: widget.category.icon ?? '');
    _colorController = TextEditingController(text: widget.category.color ?? '');
    _orderController = TextEditingController(
      text: widget.category.order?.toString() ?? '',
    );
    _isActive = widget.category.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _iconController.dispose();
    _colorController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _updateCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<CategoryProvider>();

    final success = await provider.updateCategory(
      categoryId: widget.category.id,
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      icon: _iconController.text.trim().isNotEmpty
          ? _iconController.text.trim()
          : null,
      color: _colorController.text.trim().isNotEmpty
          ? _colorController.text.trim()
          : null,
      newImageFile: _newImageBytes,
      existingImageUrl: widget.category.image,
      order: _orderController.text.isNotEmpty
          ? int.tryParse(_orderController.text)
          : null,
      isActive: _isActive,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: 'Category updated successfully!',
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      Fluttertoast.showToast(
        msg: provider.error ?? 'Failed to update category',
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Category'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
          const SizedBox(width: AppDimensions.paddingM),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: AppDimensions.maxContentWidth,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Category Image (Optional)'),
                          const SizedBox(height: AppDimensions.paddingM),
                          ImageUploader(
                            onImageSelected: (bytes, fileName) {
                              setState(() {
                                _newImageBytes = bytes;
                              });
                            },
                            initialImageUrl: widget.category.image,
                            height: 250,
                          ),
                          const SizedBox(height: AppDimensions.paddingXL),

                          _buildSectionTitle('Category Information'),
                          const SizedBox(height: AppDimensions.paddingM),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Category Name *',
                              hintText: 'e.g., Laptops',
                            ),
                            validator: (value) => Validators.required(
                              value,
                              fieldName: 'Category name',
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          TextFormField(
                            controller: _slugController,
                            decoration: const InputDecoration(
                              labelText: 'Slug *',
                              hintText: 'e.g., laptops',
                              helperText: 'URL-friendly version of the name',
                            ),
                            validator: (value) =>
                                Validators.required(value, fieldName: 'Slug'),
                          ),
                          const SizedBox(height: AppDimensions.paddingM),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _iconController,
                                  decoration: const InputDecoration(
                                    labelText: 'Icon (Optional)',
                                    hintText: 'e.g., 💻 or laptop',
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.paddingM),
                              Expanded(
                                child: TextFormField(
                                  controller: _colorController,
                                  decoration: const InputDecoration(
                                    labelText: 'Color (Optional)',
                                    hintText: 'e.g., #FF5733',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.paddingM),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _orderController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Display Order (Optional)',
                                    hintText: 'e.g., 1',
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.paddingM),
                              Expanded(
                                child: SwitchListTile(
                                  title: const Text('Active'),
                                  subtitle: Text(
                                    _isActive ? 'Visible to users' : 'Hidden',
                                    style: TextStyle(
                                      color: _isActive
                                          ? AppColors.successColor
                                          : AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  value: _isActive,
                                  onChanged: (value) {
                                    setState(() {
                                      _isActive = value;
                                    });
                                  },
                                  activeTrackColor: AppColors.successColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.paddingXL),

                          // Update Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : _updateCategory,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppDimensions.paddingM,
                                ),
                                child: provider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Update Category',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingXL),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Upload Progress Indicator
              if (provider.isLoading && provider.uploadProgress > 0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: AppColors.surfaceColor,
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Uploading image... ${(provider.uploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingS),
                        LinearProgressIndicator(
                          value: provider.uploadProgress,
                          backgroundColor: AppColors.borderColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

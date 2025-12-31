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

/// Screen for adding a new category
class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _iconController = TextEditingController();
  final _colorController = TextEditingController();
  final _orderController = TextEditingController();
  bool _isActive = true;

  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    // Auto-generate slug when name changes
    _nameController.addListener(_autoGenerateSlug);
  }

  void _autoGenerateSlug() {
    if (_slugController.text.isEmpty ||
        _slugController.text ==
            CategoryModel.generateSlug(
              _nameController.text.substring(
                0,
                _nameController.text.length - 1,
              ),
            )) {
      _slugController.text = CategoryModel.generateSlug(_nameController.text);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_autoGenerateSlug);
    _nameController.dispose();
    _slugController.dispose();
    _iconController.dispose();
    _colorController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<CategoryProvider>();

    final success = await provider.addCategory(
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      icon: _iconController.text.trim().isNotEmpty
          ? _iconController.text.trim()
          : null,
      color: _colorController.text.trim().isNotEmpty
          ? _colorController.text.trim()
          : null,
      imageFile: _imageBytes,
      order: _orderController.text.isNotEmpty
          ? int.tryParse(_orderController.text)
          : null,
      isActive: _isActive,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: 'Category added successfully!',
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      Fluttertoast.showToast(
        msg: provider.error ?? 'Failed to add category',
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Category'),
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
                                _imageBytes = bytes;
                              });
                            },
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

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : _saveCategory,
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
                                        'Save Category',
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

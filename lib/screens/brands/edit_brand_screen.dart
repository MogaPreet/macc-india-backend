import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/brand_provider.dart';
import '../../models/brand_model.dart';
import '../../widgets/image_uploader.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/utils/validators.dart';

/// Screen for editing an existing brand
class EditBrandScreen extends StatefulWidget {
  final BrandModel brand;

  const EditBrandScreen({super.key, required this.brand});

  @override
  State<EditBrandScreen> createState() => _EditBrandScreenState();
}

class _EditBrandScreenState extends State<EditBrandScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _colorController;
  late bool _isActive;

  Uint8List? _newLogoBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.brand.name);
    _colorController = TextEditingController(text: widget.brand.color ?? '');
    _isActive = widget.brand.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _updateBrand() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<BrandProvider>();

    final success = await provider.updateBrand(
      brandId: widget.brand.id,
      name: _nameController.text.trim(),
      newLogoFile: _newLogoBytes,
      existingLogoUrl: widget.brand.logo,
      color: _colorController.text.trim().isNotEmpty
          ? _colorController.text.trim()
          : null,
      isActive: _isActive,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: 'Brand updated successfully!',
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      Fluttertoast.showToast(
        msg: provider.error ?? 'Failed to update brand',
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Brand'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
          const SizedBox(width: AppDimensions.paddingM),
        ],
      ),
      body: Consumer<BrandProvider>(
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
                          _buildSectionTitle('Brand Logo (Optional)'),
                          const SizedBox(height: AppDimensions.paddingM),
                          ImageUploader(
                            onImageSelected: (bytes, fileName) {
                              setState(() {
                                _newLogoBytes = bytes;
                              });
                            },
                            initialImageUrl: widget.brand.logo,
                            height: 250,
                          ),
                          const SizedBox(height: AppDimensions.paddingXL),

                          _buildSectionTitle('Brand Information'),
                          const SizedBox(height: AppDimensions.paddingM),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Brand Name *',
                              hintText: 'e.g., Apple, Dell, HP',
                            ),
                            validator: (value) => Validators.required(
                              value,
                              fieldName: 'Brand name',
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          TextFormField(
                            controller: _colorController,
                            decoration: const InputDecoration(
                              labelText: 'Brand Color (Optional)',
                              hintText: 'e.g., #0071C5',
                              helperText: 'Hex color code for brand identity',
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingM),

                          SwitchListTile(
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
                          const SizedBox(height: AppDimensions.paddingXL),

                          // Update Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : _updateBrand,
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
                                        'Update Brand',
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
                          'Uploading logo... ${(provider.uploadProgress * 100).toInt()}%',
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

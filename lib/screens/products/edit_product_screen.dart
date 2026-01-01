import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/product_provider.dart';
import '../../providers/brand_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/product_model.dart';
import '../../widgets/multi_image_uploader.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/utils/validators.dart';

/// Screen for editing an existing product
class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _priceController;
  late TextEditingController _originalPriceController;
  late TextEditingController _descriptionController;
  late TextEditingController _stockController;

  List<Uint8List> _newImageBytes = [];
  List<String> _existingImageUrls = [];

  late bool _isFeatured;
  late bool _isActive;
  String? _selectedBrandId;
  String? _selectedBrandName;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  late String _selectedCondition;

  // Specs controllers
  late TextEditingController _processorController;
  late TextEditingController _ramController;
  late TextEditingController _storageController;
  late TextEditingController _screenController;
  late TextEditingController _graphicsController;
  late TextEditingController _batteryController;
  late TextEditingController _osController;
  late TextEditingController _portsController;
  late TextEditingController _weightController;

  // Included items
  late List<IncludedItem> _includedItems;

  // Warranty
  late TextEditingController _warrantyDurationController;
  late TextEditingController _warrantyTypeController;
  late TextEditingController _warrantyDescController;

  // YouTube URL
  late TextEditingController _youtubeUrlController;

  @override
  void initState() {
    super.initState();
    final product = widget.product;

    // Basic info
    _nameController = TextEditingController(text: product.name);
    _slugController = TextEditingController(text: product.slug);
    _priceController = TextEditingController(
      text: product.price.toStringAsFixed(0),
    );
    _originalPriceController = TextEditingController(
      text: product.originalPrice?.toStringAsFixed(0) ?? '',
    );
    _descriptionController = TextEditingController(
      text: product.description ?? '',
    );
    _stockController = TextEditingController(text: product.stock.toString());

    _existingImageUrls = List.from(product.images);
    _isFeatured = product.isFeatured;
    _isActive = product.isActive;
    _selectedBrandId = product.brandId;
    _selectedBrandName = product.brandName;
    _selectedCategoryId = product.categoryId;
    _selectedCategoryName = product.categoryName;
    _selectedCondition = product.condition;

    // Specs
    _processorController = TextEditingController(
      text: product.specs.processor ?? '',
    );
    _ramController = TextEditingController(text: product.specs.ram ?? '');
    _storageController = TextEditingController(
      text: product.specs.storage ?? '',
    );
    _screenController = TextEditingController(text: product.specs.screen ?? '');
    _graphicsController = TextEditingController(
      text: product.specs.graphics ?? '',
    );
    _batteryController = TextEditingController(
      text: product.specs.battery ?? '',
    );
    _osController = TextEditingController(text: product.specs.os ?? '');
    _portsController = TextEditingController(text: product.specs.ports ?? '');
    _weightController = TextEditingController(text: product.specs.weight ?? '');

    // Included items
    _includedItems = product.includedItems.isNotEmpty
        ? List.from(product.includedItems)
        : [
            IncludedItem(name: 'Charger', icon: '🔌', included: true),
            IncludedItem(name: 'Original Box', icon: '📦', included: true),
            IncludedItem(name: 'Manual', icon: '📖', included: false),
          ];

    // Warranty
    _warrantyDurationController = TextEditingController(
      text: product.warranty?.duration ?? '',
    );
    _warrantyTypeController = TextEditingController(
      text: product.warranty?.type ?? '',
    );
    _warrantyDescController = TextEditingController(
      text: product.warranty?.description ?? '',
    );

    // YouTube URL
    _youtubeUrlController = TextEditingController(
      text: product.youtubeUrl ?? '',
    );

    // Fetch brands and categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandProvider>().fetchBrands();
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _processorController.dispose();
    _ramController.dispose();
    _storageController.dispose();
    _screenController.dispose();
    _graphicsController.dispose();
    _batteryController.dispose();
    _osController.dispose();
    _portsController.dispose();
    _weightController.dispose();
    _warrantyDurationController.dispose();
    _warrantyTypeController.dispose();
    _warrantyDescController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }

  ProductSpecs _buildSpecs() {
    return ProductSpecs(
      processor: _processorController.text.trim().isNotEmpty
          ? _processorController.text.trim()
          : null,
      ram: _ramController.text.trim().isNotEmpty
          ? _ramController.text.trim()
          : null,
      storage: _storageController.text.trim().isNotEmpty
          ? _storageController.text.trim()
          : null,
      screen: _screenController.text.trim().isNotEmpty
          ? _screenController.text.trim()
          : null,
      graphics: _graphicsController.text.trim().isNotEmpty
          ? _graphicsController.text.trim()
          : null,
      battery: _batteryController.text.trim().isNotEmpty
          ? _batteryController.text.trim()
          : null,
      os: _osController.text.trim().isNotEmpty
          ? _osController.text.trim()
          : null,
      ports: _portsController.text.trim().isNotEmpty
          ? _portsController.text.trim()
          : null,
      weight: _weightController.text.trim().isNotEmpty
          ? _weightController.text.trim()
          : null,
    );
  }

  ProductWarranty? _buildWarranty() {
    if (_warrantyDurationController.text.trim().isEmpty &&
        _warrantyTypeController.text.trim().isEmpty) {
      return null;
    }
    return ProductWarranty(
      duration: _warrantyDurationController.text.trim().isNotEmpty
          ? _warrantyDurationController.text.trim()
          : null,
      type: _warrantyTypeController.text.trim().isNotEmpty
          ? _warrantyTypeController.text.trim()
          : null,
      description: _warrantyDescController.text.trim().isNotEmpty
          ? _warrantyDescController.text.trim()
          : null,
    );
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newImageBytes.isEmpty && _existingImageUrls.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Product must have at least one image',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }

    if (_selectedBrandId == null || _selectedCategoryId == null) {
      Fluttertoast.showToast(
        msg: 'Please select brand and category',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }

    final provider = context.read<ProductProvider>();

    final success = await provider.updateProduct(
      productId: widget.product.id,
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      brandId: _selectedBrandId!,
      brandName: _selectedBrandName!,
      categoryId: _selectedCategoryId!,
      categoryName: _selectedCategoryName!,
      price: double.parse(_priceController.text.trim()),
      originalPrice: _originalPriceController.text.trim().isNotEmpty
          ? double.parse(_originalPriceController.text.trim())
          : null,
      condition: _selectedCondition,
      stock: int.tryParse(_stockController.text.trim()) ?? 1,
      isFeatured: _isFeatured,
      isActive: _isActive,
      newImageFiles: _newImageBytes.isNotEmpty ? _newImageBytes : null,
      existingImageUrls: _existingImageUrls,
      specs: _buildSpecs(),
      includedItems: _includedItems,
      warranty: _buildWarranty(),
      youtubeUrl: _youtubeUrlController.text.trim().isNotEmpty
          ? _youtubeUrlController.text.trim()
          : null,
    );

    if (success) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Product updated successfully',
          backgroundColor: AppColors.successColor,
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        Fluttertoast.showToast(
          msg: provider.error ?? 'Failed to update product',
          backgroundColor: AppColors.errorColor,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Product Images *'),
                      const SizedBox(height: AppDimensions.paddingM),
                      MultiImageUploader(
                        height: 200,
                        initialImageUrls: _existingImageUrls,
                        onImagesChanged: (newImages, currentUrls) {
                          setState(() {
                            _newImageBytes = newImages;
                            _existingImageUrls = currentUrls;
                          });
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingL),

                      _buildSectionTitle('Basic Information'),
                      const SizedBox(height: AppDimensions.paddingM),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          hintText: 'e.g., MacBook Pro 14-inch',
                        ),
                        validator: (value) => Validators.required(
                          value,
                          fieldName: 'Product name',
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      TextFormField(
                        controller: _slugController,
                        decoration: const InputDecoration(
                          labelText: 'Slug *',
                          hintText: 'e.g., macbook-pro-14-inch',
                          helperText: 'URL-friendly version of the name',
                        ),
                        validator: (value) =>
                            Validators.required(value, fieldName: 'Slug'),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),

                      // Brand and Category Selectors
                      Row(
                        children: [
                          Expanded(
                            child: Consumer<BrandProvider>(
                              builder: (context, brandProvider, child) {
                                return DropdownButtonFormField<String>(
                                  initialValue: _selectedBrandId,
                                  decoration: const InputDecoration(
                                    labelText: 'Brand *',
                                    hintText: 'Select Brand',
                                  ),
                                  items: brandProvider.brands.map((brand) {
                                    return DropdownMenuItem(
                                      value: brand.id,
                                      child: Text(brand.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    final brand = brandProvider.brands
                                        .firstWhere((b) => b.id == value);
                                    setState(() {
                                      _selectedBrandId = value;
                                      _selectedBrandName = brand.name;
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? 'Please select a brand'
                                      : null,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: Consumer<CategoryProvider>(
                              builder: (context, categoryProvider, child) {
                                return DropdownButtonFormField<String>(
                                  initialValue: _selectedCategoryId,
                                  decoration: const InputDecoration(
                                    labelText: 'Category *',
                                    hintText: 'Select Category',
                                  ),
                                  items: categoryProvider.categories.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat.id,
                                      child: Text(cat.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    final category = categoryProvider.categories
                                        .firstWhere((c) => c.id == value);
                                    setState(() {
                                      _selectedCategoryId = value;
                                      _selectedCategoryName = category.name;
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? 'Please select a category'
                                      : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingM),

                      // Price and Condition
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Selling Price (₹) *',
                                hintText: 'e.g., 89990',
                                prefixText: '₹ ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: Validators.price,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: TextFormField(
                              controller: _originalPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Original Price (₹)',
                                hintText: 'MRP for discount',
                                prefixText: '₹ ',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingM),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedCondition,
                              decoration: const InputDecoration(
                                labelText: 'Condition *',
                              ),
                              items: ProductCondition.values.map((condition) {
                                return DropdownMenuItem(
                                  value: condition,
                                  child: Text(condition),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCondition = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              decoration: const InputDecoration(
                                labelText: 'Stock Quantity',
                                hintText: 'Available units',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingM),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter product description',
                        ),
                        maxLines: 4,
                      ),

                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildSectionTitle('Specifications'),
                      const SizedBox(height: AppDimensions.paddingM),
                      _buildSpecsForm(),

                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildSectionTitle('Included Items'),
                      const SizedBox(height: AppDimensions.paddingM),
                      _buildIncludedItemsForm(),

                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildSectionTitle('Warranty (Optional)'),
                      const SizedBox(height: AppDimensions.paddingM),
                      _buildWarrantyForm(),

                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildSectionTitle('YouTube Video (Optional)'),
                      const SizedBox(height: AppDimensions.paddingM),
                      TextFormField(
                        controller: _youtubeUrlController,
                        decoration: const InputDecoration(
                          labelText: 'YouTube URL',
                          hintText: 'e.g., https://www.youtube.com/watch?v=...',
                          prefixIcon: Icon(Icons.video_library),
                        ),
                      ),

                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildSectionTitle('Product Settings'),
                      const SizedBox(height: AppDimensions.paddingM),
                      _buildSwitchTile(
                        title: 'Featured',
                        subtitle: 'Show on homepage',
                        value: _isFeatured,
                        onChanged: (value) =>
                            setState(() => _isFeatured = value),
                        activeColor: AppColors.primaryColor,
                      ),
                      _buildSwitchTile(
                        title: 'Active',
                        subtitle: 'Product visibility',
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                        activeColor: AppColors.successColor,
                      ),

                      const SizedBox(height: AppDimensions.paddingXL),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: provider.isLoading ? null : _updateProduct,
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
                                    'Update Product',
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
                          'Uploading images... ${(provider.uploadProgress * 100).toInt()}%',
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

  Widget _buildSpecsForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _processorController,
                decoration: const InputDecoration(
                  labelText: 'Processor',
                  hintText: 'e.g., Apple M3 Pro',
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: TextFormField(
                controller: _ramController,
                decoration: const InputDecoration(
                  labelText: 'RAM',
                  hintText: 'e.g., 16GB',
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
                controller: _storageController,
                decoration: const InputDecoration(
                  labelText: 'Storage',
                  hintText: 'e.g., 512GB SSD',
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: TextFormField(
                controller: _screenController,
                decoration: const InputDecoration(
                  labelText: 'Screen',
                  hintText: 'e.g., 14" Retina',
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
                controller: _graphicsController,
                decoration: const InputDecoration(
                  labelText: 'Graphics',
                  hintText: 'e.g., 18-core GPU',
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: TextFormField(
                controller: _batteryController,
                decoration: const InputDecoration(
                  labelText: 'Battery',
                  hintText: 'e.g., Up to 18 hours',
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
                controller: _osController,
                decoration: const InputDecoration(
                  labelText: 'Operating System',
                  hintText: 'e.g., macOS Sonoma',
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: TextFormField(
                controller: _portsController,
                decoration: const InputDecoration(
                  labelText: 'Ports',
                  hintText: 'e.g., 3x Thunderbolt 4',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        TextFormField(
          controller: _weightController,
          decoration: const InputDecoration(
            labelText: 'Weight',
            hintText: 'e.g., 1.6 kg',
          ),
        ),
      ],
    );
  }

  Widget _buildIncludedItemsForm() {
    return Column(
      children: _includedItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return CheckboxListTile(
          title: Text('${item.icon} ${item.name}'),
          value: item.included,
          onChanged: (value) {
            setState(() {
              _includedItems[index] = item.copyWith(included: value ?? false);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildWarrantyForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _warrantyDurationController,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  hintText: 'e.g., 6 months',
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: TextFormField(
                controller: _warrantyTypeController,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  hintText: 'e.g., Seller Warranty',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        TextFormField(
          controller: _warrantyDescController,
          decoration: const InputDecoration(
            labelText: 'Warranty Description',
            hintText: 'Additional warranty details...',
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        value: value,
        onChanged: onChanged,
        activeTrackColor: activeColor,
      ),
    );
  }
}

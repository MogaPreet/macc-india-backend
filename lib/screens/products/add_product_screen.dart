import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/product_provider.dart';
import '../../providers/brand_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/product_model.dart';
import '../../widgets/multi_image_uploader.dart';
import '../../widgets/autocomplete_text_field.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/utils/validators.dart';

/// Screen for adding a new product
class AddProductScreen extends StatefulWidget {
  /// Optional product to duplicate from
  final ProductModel? duplicateFrom;

  const AddProductScreen({super.key, this.duplicateFrom});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController(text: '1');

  // Multi-image state
  List<Uint8List> _newImageBytes = [];

  bool _isFeatured = false;
  bool _isActive = true;
  String? _selectedBrandId;
  String? _selectedBrandName;
  List<String> _selectedCategoryIds = [];
  List<String> _selectedCategoryNames = [];
  String _selectedCondition = ProductCondition.likeNew;

  // Specs controllers
  final _processorController = TextEditingController();
  final _ramController = TextEditingController();
  final _storageController = TextEditingController();
  final _screenController = TextEditingController();
  final _graphicsController = TextEditingController();
  final _batteryController = TextEditingController();
  final _osController = TextEditingController();
  final _portsController = TextEditingController();
  final _weightController = TextEditingController();

  // Included items
  late final List<IncludedItem> _includedItems = [
    IncludedItem(name: 'Charger', icon: '🔌', included: true),
    IncludedItem(name: 'Original Box', icon: '📦', included: true),
    IncludedItem(name: 'Manual', icon: '📖', included: false),
  ];

  // Warranty
  final _warrantyDurationController = TextEditingController();
  final _warrantyTypeController = TextEditingController();
  final _warrantyDescController = TextEditingController();

  // YouTube URL
  final _youtubeUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-generate slug when name changes
    _nameController.addListener(_autoGenerateSlug);

    // Pre-fill from duplicate source if provided
    final source = widget.duplicateFrom;
    if (source != null) {
      _nameController.text = '${source.name} (Copy)';
      _slugController.text = '${source.slug}-copy';
      _priceController.text = source.price.toStringAsFixed(0);
      _originalPriceController.text =
          source.originalPrice?.toStringAsFixed(0) ?? '';
      _descriptionController.text = source.description ?? '';
      _stockController.text = source.stock.toString();
      _isFeatured = source.isFeatured;
      _isActive = source.isActive;
      _selectedBrandId = source.brandId;
      _selectedBrandName = source.brandName;
      _selectedCategoryIds = List.from(source.categoryIds);
      _selectedCategoryNames = List.from(source.categoryNames);
      _selectedCondition = source.condition;

      // Specs
      _processorController.text = source.specs.processor ?? '';
      _ramController.text = source.specs.ram ?? '';
      _storageController.text = source.specs.storage ?? '';
      _screenController.text = source.specs.screen ?? '';
      _graphicsController.text = source.specs.graphics ?? '';
      _batteryController.text = source.specs.battery ?? '';
      _osController.text = source.specs.os ?? '';
      _portsController.text = source.specs.ports ?? '';
      _weightController.text = source.specs.weight ?? '';

      // Included items
      if (source.includedItems.isNotEmpty) {
        _includedItems.clear();
        _includedItems.addAll(
          source.includedItems.map(
            (item) => IncludedItem(
              name: item.name,
              icon: item.icon,
              included: item.included,
            ),
          ),
        );
      }

      // Warranty
      _warrantyDurationController.text = source.warranty?.duration ?? '';
      _warrantyTypeController.text = source.warranty?.type ?? '';
      _warrantyDescController.text = source.warranty?.description ?? '';

      // YouTube URL
      _youtubeUrlController.text = source.youtubeUrl ?? '';
    }

    // Fetch brands and categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandProvider>().fetchBrands();
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  void _autoGenerateSlug() {
    if (_slugController.text.isEmpty ||
        _slugController.text ==
            ProductModel.generateSlug(
              _nameController.text.isNotEmpty
                  ? _nameController.text.substring(
                      0,
                      _nameController.text.length - 1,
                    )
                  : '',
            )) {
      _slugController.text = ProductModel.generateSlug(_nameController.text);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_autoGenerateSlug);
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newImageBytes.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please select at least one product image',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }

    if (_selectedBrandId == null || _selectedCategoryIds.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please select brand and at least one category',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }

    final provider = context.read<ProductProvider>();

    final success = await provider.addProduct(
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      brandId: _selectedBrandId!,
      brandName: _selectedBrandName!,
      categoryIds: _selectedCategoryIds,
      categoryNames: _selectedCategoryNames,
      price: double.parse(_priceController.text.trim()),
      originalPrice: _originalPriceController.text.trim().isNotEmpty
          ? double.parse(_originalPriceController.text.trim())
          : null,
      condition: _selectedCondition,
      stock: int.tryParse(_stockController.text.trim()) ?? 1,
      isFeatured: _isFeatured,
      isActive: _isActive,
      imageFiles: _newImageBytes,
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
          msg: 'Product added successfully',
          backgroundColor: AppColors.successColor,
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        Fluttertoast.showToast(
          msg: provider.error ?? 'Failed to add product',
          backgroundColor: AppColors.errorColor,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.duplicateFrom != null ? 'Duplicate Product' : 'Add Product',
        ),
      ),
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
                        onImagesChanged: (newImages, _) {
                          setState(() {
                            _newImageBytes = newImages;
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
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingM),

                      // Multi-select Category Chips
                      _buildSectionTitle('Categories *'),
                      const SizedBox(height: AppDimensions.paddingS),
                      Consumer<CategoryProvider>(
                        builder: (context, categoryProvider, child) {
                          if (categoryProvider.categories.isEmpty) {
                            return const Text(
                              'No categories available',
                              style: TextStyle(color: AppColors.textSecondary),
                            );
                          }
                          return Wrap(
                            spacing: AppDimensions.paddingS,
                            runSpacing: AppDimensions.paddingS,
                            children: categoryProvider.categories.map((
                              category,
                            ) {
                              final isSelected = _selectedCategoryIds.contains(
                                category.id,
                              );
                              return FilterChip(
                                label: Text(category.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCategoryIds.add(category.id);
                                      _selectedCategoryNames.add(category.name);
                                    } else {
                                      _selectedCategoryIds.remove(category.id);
                                      _selectedCategoryNames.remove(
                                        category.name,
                                      );
                                    }
                                  });
                                },
                                selectedColor: AppColors.primaryColor
                                    .withOpacity(0.2),
                                checkmarkColor: AppColors.primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          );
                        },
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
                          onPressed: provider.isLoading ? null : _saveProduct,
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
                                    'Save Product',
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
    final productProvider = context.read<ProductProvider>();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _processorController,
                labelText: 'Processor',
                hintText: 'e.g., Apple M3 Pro',
                suggestions: productProvider.getUniqueProcessors(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _ramController,
                labelText: 'RAM',
                hintText: 'e.g., 16GB',
                suggestions: productProvider.getUniqueRamValues(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _storageController,
                labelText: 'Storage',
                hintText: 'e.g., 512GB SSD',
                suggestions: productProvider.getUniqueStorageValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _screenController,
                labelText: 'Screen',
                hintText: 'e.g., 14" Retina',
                suggestions: productProvider.getUniqueScreenValues(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _graphicsController,
                labelText: 'Graphics',
                hintText: 'e.g., 18-core GPU',
                suggestions: productProvider.getUniqueGraphicsValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _batteryController,
                labelText: 'Battery',
                hintText: 'e.g., Up to 18 hours',
                suggestions: productProvider.getUniqueBatteryValues(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _osController,
                labelText: 'Operating System',
                hintText: 'e.g., macOS Sonoma',
                suggestions: productProvider.getUniqueOsValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _portsController,
                labelText: 'Ports',
                hintText: 'e.g., 3x Thunderbolt 4',
                suggestions: productProvider.getUniquePortsValues(),
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

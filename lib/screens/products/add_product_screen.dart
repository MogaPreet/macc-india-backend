import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
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
import '../../widgets/product_description_codec.dart';
import '../../widgets/product_description_editor.dart';

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
  late final QuillController _descriptionQuillController;
  late final FocusNode _descriptionFocusNode;
  late final ScrollController _descriptionScrollController;
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
  String _selectedProductType = ProductType.laptop;

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

  // Monitor-specific specs controllers
  final _panelTypeController = TextEditingController();
  final _resolutionController = TextEditingController();
  final _refreshRateController = TextEditingController();
  final _responseTimeController = TextEditingController();
  final _displaySizeController = TextEditingController();

  // Phone/iPad-specific specs controllers
  final _screenSizeController = TextEditingController();
  final _cameraController = TextEditingController();
  final _chipsetController = TextEditingController();
  final _simTypeController = TextEditingController();
  final _connectivityController = TextEditingController();
  final _waterResistanceController = TextEditingController();
  final _biometricsController = TextEditingController();
  final _colorOptionsController = TextEditingController();
  final _pencilSupportController = TextEditingController();
  final _keyboardSupportController = TextEditingController();

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
      _stockController.text = source.stock.toString();
      _isFeatured = source.isFeatured;
      _isActive = source.isActive;
      _selectedBrandId = source.brandId;
      _selectedBrandName = source.brandName;
      _selectedCategoryIds = List.from(source.categoryIds);
      _selectedCategoryNames = List.from(source.categoryNames);
      _selectedCondition = source.condition;
      _selectedProductType = source.productType;

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

      // Monitor specs
      _panelTypeController.text = source.specs.panelType ?? '';
      _resolutionController.text = source.specs.resolution ?? '';
      _refreshRateController.text = source.specs.refreshRate ?? '';
      _responseTimeController.text = source.specs.responseTime ?? '';
      _displaySizeController.text = source.specs.displaySize ?? '';

      // Phone/iPad specs
      _screenSizeController.text = source.specs.screenSize ?? '';
      _cameraController.text = source.specs.camera ?? '';
      _chipsetController.text = source.specs.chipset ?? '';
      _simTypeController.text = source.specs.simType ?? '';
      _connectivityController.text = source.specs.connectivity ?? '';
      _waterResistanceController.text = source.specs.waterResistance ?? '';
      _biometricsController.text = source.specs.biometrics ?? '';
      _colorOptionsController.text = source.specs.colorOptions ?? '';
      _pencilSupportController.text = source.specs.pencilSupport ?? '';
      _keyboardSupportController.text = source.specs.keyboardSupport ?? '';

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

    _descriptionQuillController = QuillController(
      document: ProductDescriptionCodec.documentFromStored(
        widget.duplicateFrom?.description,
      ),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _descriptionFocusNode = FocusNode();
    _descriptionScrollController = ScrollController();

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
    _descriptionScrollController.dispose();
    _descriptionFocusNode.dispose();
    _descriptionQuillController.dispose();
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
    _panelTypeController.dispose();
    _resolutionController.dispose();
    _refreshRateController.dispose();
    _responseTimeController.dispose();
    _displaySizeController.dispose();
    _screenSizeController.dispose();
    _cameraController.dispose();
    _chipsetController.dispose();
    _simTypeController.dispose();
    _connectivityController.dispose();
    _waterResistanceController.dispose();
    _biometricsController.dispose();
    _colorOptionsController.dispose();
    _pencilSupportController.dispose();
    _keyboardSupportController.dispose();
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
      panelType: _panelTypeController.text.trim().isNotEmpty
          ? _panelTypeController.text.trim()
          : null,
      resolution: _resolutionController.text.trim().isNotEmpty
          ? _resolutionController.text.trim()
          : null,
      refreshRate: _refreshRateController.text.trim().isNotEmpty
          ? _refreshRateController.text.trim()
          : null,
      responseTime: _responseTimeController.text.trim().isNotEmpty
          ? _responseTimeController.text.trim()
          : null,
      displaySize: _displaySizeController.text.trim().isNotEmpty
          ? _displaySizeController.text.trim()
          : null,
      screenSize: _screenSizeController.text.trim().isNotEmpty
          ? _screenSizeController.text.trim()
          : null,
      camera: _cameraController.text.trim().isNotEmpty
          ? _cameraController.text.trim()
          : null,
      chipset: _chipsetController.text.trim().isNotEmpty
          ? _chipsetController.text.trim()
          : null,
      simType: _simTypeController.text.trim().isNotEmpty
          ? _simTypeController.text.trim()
          : null,
      connectivity: _connectivityController.text.trim().isNotEmpty
          ? _connectivityController.text.trim()
          : null,
      waterResistance: _waterResistanceController.text.trim().isNotEmpty
          ? _waterResistanceController.text.trim()
          : null,
      biometrics: _biometricsController.text.trim().isNotEmpty
          ? _biometricsController.text.trim()
          : null,
      colorOptions: _colorOptionsController.text.trim().isNotEmpty
          ? _colorOptionsController.text.trim()
          : null,
      pencilSupport: _pencilSupportController.text.trim().isNotEmpty
          ? _pencilSupportController.text.trim()
          : null,
      keyboardSupport: _keyboardSupportController.text.trim().isNotEmpty
          ? _keyboardSupportController.text.trim()
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
      description: ProductDescriptionCodec.serializeNullable(
        _descriptionQuillController,
      ),
      brandId: _selectedBrandId!,
      brandName: _selectedBrandName!,
      categoryIds: _selectedCategoryIds,
      categoryNames: _selectedCategoryNames,
      price: double.parse(_priceController.text.trim()),
      originalPrice: _originalPriceController.text.trim().isNotEmpty
          ? double.parse(_originalPriceController.text.trim())
          : null,
      condition: _selectedCondition,
      productType: _selectedProductType,
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
                      _buildSectionTitle('Product Type'),
                      const SizedBox(height: AppDimensions.paddingM),
                      _buildProductTypeSelector(),
                      const SizedBox(height: AppDimensions.paddingL),

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

                      ProductDescriptionEditor(
                        controller: _descriptionQuillController,
                        focusNode: _descriptionFocusNode,
                        scrollController: _descriptionScrollController,
                      ),

                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildSectionTitle('Specifications'),
                      const SizedBox(height: AppDimensions.paddingM),
                      _buildSpecsForm(),

                      if (_selectedProductType == ProductType.laptop) ...[
                        const SizedBox(height: AppDimensions.paddingXL),
                        _buildSectionTitle('Included Items'),
                        const SizedBox(height: AppDimensions.paddingM),
                        _buildIncludedItemsForm(),
                      ],

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

  Widget _buildProductTypeSelector() {
    return Row(
      children: ProductType.values.map((type) {
        final isSelected = _selectedProductType == type;
        final IconData icon;
        switch (type) {
          case ProductType.laptop:
            icon = Icons.laptop_mac;
            break;
          case ProductType.system:
            icon = Icons.desktop_windows;
            break;
          case ProductType.monitor:
            icon = Icons.monitor;
            break;
          case ProductType.phone:
            icon = Icons.phone_android;
            break;
          case ProductType.ipad:
            icon = Icons.tablet_mac;
            break;
          default:
            icon = Icons.laptop_mac;
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedProductType = type;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ProductType.label(type),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpecsForm() {
    if (_selectedProductType == ProductType.monitor) {
      return _buildMonitorSpecsForm();
    }
    if (_selectedProductType == ProductType.phone) {
      return _buildPhoneSpecsForm();
    }
    if (_selectedProductType == ProductType.ipad) {
      return _buildIpadSpecsForm();
    }

    final productProvider = context.read<ProductProvider>();
    final isSystem = _selectedProductType == ProductType.system;

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
            if (!isSystem) ...[
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
            if (!isSystem) ...[
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

  Widget _buildMonitorSpecsForm() {
    final productProvider = context.read<ProductProvider>();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _displaySizeController,
                labelText: 'Display Size',
                hintText: 'e.g., 27 inch',
                suggestions: productProvider.getUniqueDisplaySizeValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _resolutionController,
                labelText: 'Resolution',
                hintText: 'e.g., 3840 x 2160 (4K)',
                suggestions: productProvider.getUniqueResolutionValues(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _panelTypeController,
                labelText: 'Panel Type',
                hintText: 'e.g., IPS / VA / OLED',
                suggestions: productProvider.getUniquePanelTypeValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _refreshRateController,
                labelText: 'Refresh Rate',
                hintText: 'e.g., 144Hz',
                suggestions: productProvider.getUniqueRefreshRateValues(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _responseTimeController,
                labelText: 'Response Time',
                hintText: 'e.g., 1ms GTG',
                suggestions: productProvider.getUniqueResponseTimeValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _portsController,
                labelText: 'Ports',
                hintText: 'e.g., HDMI, DP, USB-C',
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
            hintText: 'e.g., 5.2 kg',
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneSpecsForm() {
    final productProvider = context.read<ProductProvider>();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _screenSizeController,
                labelText: 'Screen Size',
                hintText: 'e.g., 6.7" Super Retina XDR',
                suggestions: productProvider.getUniqueScreenSizeValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _chipsetController,
                labelText: 'Chipset',
                hintText: 'e.g., Apple A17 Pro',
                suggestions: productProvider.getUniqueChipsetValues(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _ramController,
                labelText: 'RAM',
                hintText: 'e.g., 8GB',
                suggestions: productProvider.getUniqueRamValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _storageController,
                labelText: 'Storage',
                hintText: 'e.g., 256GB',
                suggestions: productProvider.getUniqueStorageValues(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _cameraController,
                labelText: 'Camera',
                hintText: 'e.g., 48MP + 12MP + 12MP',
                suggestions: productProvider.getUniqueCameraValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _batteryController,
                labelText: 'Battery',
                hintText: 'e.g., 4422 mAh',
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
                labelText: 'OS',
                hintText: 'e.g., iOS 17 / Android 14',
                suggestions: productProvider.getUniqueOsValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _simTypeController,
                labelText: 'SIM Type',
                hintText: 'e.g., Nano-SIM + eSIM',
                suggestions: productProvider.getUniqueSimTypeValues(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _connectivityController,
                labelText: 'Connectivity',
                hintText: 'e.g., 5G, WiFi 6E, BT 5.3',
                suggestions: productProvider.getUniqueConnectivityValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: TextFormField(
                controller: _waterResistanceController,
                decoration: const InputDecoration(
                  labelText: 'Water Resistance',
                  hintText: 'e.g., IP68',
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
                controller: _biometricsController,
                decoration: const InputDecoration(
                  labelText: 'Biometrics',
                  hintText: 'e.g., Face ID / Fingerprint',
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  hintText: 'e.g., 187g',
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
                controller: _colorOptionsController,
                decoration: const InputDecoration(
                  labelText: 'Color Options',
                  hintText: 'e.g., Black, Silver, Gold',
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: TextFormField(
                controller: _portsController,
                decoration: const InputDecoration(
                  labelText: 'Ports',
                  hintText: 'e.g., USB-C / Lightning',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIpadSpecsForm() {
    final productProvider = context.read<ProductProvider>();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _screenSizeController,
                labelText: 'Screen Size',
                hintText: 'e.g., 12.9" Liquid Retina XDR',
                suggestions: productProvider.getUniqueScreenSizeValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _chipsetController,
                labelText: 'Chipset',
                hintText: 'e.g., Apple M2 / Snapdragon',
                suggestions: productProvider.getUniqueChipsetValues(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _ramController,
                labelText: 'RAM',
                hintText: 'e.g., 8GB',
                suggestions: productProvider.getUniqueRamValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _storageController,
                labelText: 'Storage',
                hintText: 'e.g., 256GB',
                suggestions: productProvider.getUniqueStorageValues(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: AutocompleteTextField(
                controller: _cameraController,
                labelText: 'Camera',
                hintText: 'e.g., 12MP Wide + 10MP Ultra Wide',
                suggestions: productProvider.getUniqueCameraValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _batteryController,
                labelText: 'Battery',
                hintText: 'e.g., Up to 10 hours',
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
                labelText: 'OS',
                hintText: 'e.g., iPadOS 17 / Android 14',
                suggestions: productProvider.getUniqueOsValues(),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AutocompleteTextField(
                controller: _connectivityController,
                labelText: 'Connectivity',
                hintText: 'e.g., WiFi 6E, BT 5.3, 5G',
                suggestions: productProvider.getUniqueConnectivityValues(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pencilSupportController,
                decoration: const InputDecoration(
                  labelText: 'Pencil / Stylus Support',
                  hintText: 'e.g., Apple Pencil 2nd Gen',
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: TextFormField(
                controller: _keyboardSupportController,
                decoration: const InputDecoration(
                  labelText: 'Keyboard Support',
                  hintText: 'e.g., Magic Keyboard, Smart Folio',
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
                controller: _biometricsController,
                decoration: const InputDecoration(
                  labelText: 'Biometrics',
                  hintText: 'e.g., Face ID / Touch ID',
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  hintText: 'e.g., 682g',
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
                controller: _colorOptionsController,
                decoration: const InputDecoration(
                  labelText: 'Color Options',
                  hintText: 'e.g., Space Gray, Silver',
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: TextFormField(
                controller: _portsController,
                decoration: const InputDecoration(
                  labelText: 'Ports',
                  hintText: 'e.g., USB-C / Thunderbolt',
                ),
              ),
            ),
          ],
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

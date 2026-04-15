import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/accessory_provider.dart';
import '../../providers/brand_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/accessory_model.dart';
import '../../widgets/multi_image_uploader.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/utils/validators.dart';

/// Screen for editing an existing accessory
class EditAccessoryScreen extends StatefulWidget {
  final AccessoryModel accessory;

  const EditAccessoryScreen({super.key, required this.accessory});

  @override
  State<EditAccessoryScreen> createState() => _EditAccessoryScreenState();
}

class _EditAccessoryScreenState extends State<EditAccessoryScreen> {
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
  List<String> _selectedCategoryIds = [];
  List<String> _selectedCategoryNames = [];
  late String _selectedCondition;
  late String _selectedAccessoryType;

  // --- Shared spec controllers ---
  late TextEditingController _connectivityController;
  late TextEditingController _compatibilityController;
  late TextEditingController _materialController;
  late TextEditingController _colorController;
  late TextEditingController _dimensionsController;
  late TextEditingController _weightController;
  late TextEditingController _portsController;

  // --- Keyboard spec controllers ---
  late TextEditingController _layoutController;
  late TextEditingController _switchTypeController;
  late TextEditingController _backlightController;
  late TextEditingController _keyCountController;

  // --- Mouse spec controllers ---
  late TextEditingController _dpiController;
  late TextEditingController _sensorTypeController;
  late TextEditingController _buttonsController;

  // --- Graphic Card spec controllers ---
  late TextEditingController _gpuChipsetController;
  late TextEditingController _vramController;
  late TextEditingController _clockSpeedController;
  late TextEditingController _memoryBusController;
  late TextEditingController _powerRequirementController;
  late TextEditingController _coolingController;
  late TextEditingController _cardLengthController;

  // --- Charger spec controllers ---
  late TextEditingController _wattageController;
  late TextEditingController _outputPortsController;
  late TextEditingController _fastChargingController;
  late TextEditingController _cableIncludedController;

  // --- Cable spec controllers ---
  late TextEditingController _cableTypeController;
  late TextEditingController _cableLengthController;
  late TextEditingController _dataTransferController;
  late TextEditingController _powerDeliveryController;

  // --- Case/Cover spec controllers ---
  late TextEditingController _deviceCompatibilityController;
  late TextEditingController _featuresController;

  // --- Stand/Mount spec controllers ---
  late TextEditingController _standTypeController;
  late TextEditingController _adjustableController;
  late TextEditingController _weightCapacityController;

  // --- Hub/Dock spec controllers ---
  late TextEditingController _inputPortController;
  late TextEditingController _hubOutputPortsController;
  late TextEditingController _powerPassthroughController;

  // --- Audio spec controllers ---
  late TextEditingController _audioTypeController;
  late TextEditingController _driverSizeController;
  late TextEditingController _noiseCancellationController;
  late TextEditingController _batteryLifeController;

  // --- Other spec controllers ---
  late TextEditingController _categoryController;
  late TextEditingController _keyFeatureController;

  // Warranty
  late TextEditingController _warrantyDurationController;
  late TextEditingController _warrantyTypeController;
  late TextEditingController _warrantyDescController;

  // YouTube URL
  late TextEditingController _youtubeUrlController;

  @override
  void initState() {
    super.initState();
    final a = widget.accessory;
    final s = a.specs;

    _nameController = TextEditingController(text: a.name);
    _slugController = TextEditingController(text: a.slug);
    _priceController = TextEditingController(text: a.price.toStringAsFixed(0));
    _originalPriceController = TextEditingController(
        text: a.originalPrice?.toStringAsFixed(0) ?? '');
    _descriptionController = TextEditingController(text: a.description ?? '');
    _stockController = TextEditingController(text: a.stock.toString());

    _existingImageUrls = List.from(a.images);
    _isFeatured = a.isFeatured;
    _isActive = a.isActive;
    _selectedBrandId = a.brandId;
    _selectedBrandName = a.brandName;
    _selectedCategoryIds = List.from(a.categoryIds);
    _selectedCategoryNames = List.from(a.categoryNames);
    _selectedCondition = a.condition;
    _selectedAccessoryType = a.accessoryType;

    // Shared
    _connectivityController = TextEditingController(text: s.connectivity ?? '');
    _compatibilityController = TextEditingController(text: s.compatibility ?? '');
    _materialController = TextEditingController(text: s.material ?? '');
    _colorController = TextEditingController(text: s.color ?? '');
    _dimensionsController = TextEditingController(text: s.dimensions ?? '');
    _weightController = TextEditingController(text: s.weight ?? '');
    _portsController = TextEditingController(text: s.ports ?? '');

    // Keyboard
    _layoutController = TextEditingController(text: s.layout ?? '');
    _switchTypeController = TextEditingController(text: s.switchType ?? '');
    _backlightController = TextEditingController(text: s.backlight ?? '');
    _keyCountController = TextEditingController(text: s.keyCount ?? '');

    // Mouse
    _dpiController = TextEditingController(text: s.dpi ?? '');
    _sensorTypeController = TextEditingController(text: s.sensorType ?? '');
    _buttonsController = TextEditingController(text: s.buttons ?? '');

    // Graphic Card
    _gpuChipsetController = TextEditingController(text: s.gpuChipset ?? '');
    _vramController = TextEditingController(text: s.vram ?? '');
    _clockSpeedController = TextEditingController(text: s.clockSpeed ?? '');
    _memoryBusController = TextEditingController(text: s.memoryBus ?? '');
    _powerRequirementController = TextEditingController(text: s.powerRequirement ?? '');
    _coolingController = TextEditingController(text: s.cooling ?? '');
    _cardLengthController = TextEditingController(text: s.cardLength ?? '');

    // Charger
    _wattageController = TextEditingController(text: s.wattage ?? '');
    _outputPortsController = TextEditingController(text: s.outputPorts ?? '');
    _fastChargingController = TextEditingController(text: s.fastCharging ?? '');
    _cableIncludedController = TextEditingController(text: s.cableIncluded ?? '');

    // Cable
    _cableTypeController = TextEditingController(text: s.cableType ?? '');
    _cableLengthController = TextEditingController(text: s.cableLength ?? '');
    _dataTransferController = TextEditingController(text: s.dataTransfer ?? '');
    _powerDeliveryController = TextEditingController(text: s.powerDelivery ?? '');

    // Case/Cover
    _deviceCompatibilityController = TextEditingController(text: s.deviceCompatibility ?? '');
    _featuresController = TextEditingController(text: s.features ?? '');

    // Stand
    _standTypeController = TextEditingController(text: s.standType ?? '');
    _adjustableController = TextEditingController(text: s.adjustable ?? '');
    _weightCapacityController = TextEditingController(text: s.weightCapacity ?? '');

    // Hub
    _inputPortController = TextEditingController(text: s.inputPort ?? '');
    _hubOutputPortsController = TextEditingController(text: s.hubOutputPorts ?? '');
    _powerPassthroughController = TextEditingController(text: s.powerPassthrough ?? '');

    // Audio
    _audioTypeController = TextEditingController(text: s.audioType ?? '');
    _driverSizeController = TextEditingController(text: s.driverSize ?? '');
    _noiseCancellationController = TextEditingController(text: s.noiseCancellation ?? '');
    _batteryLifeController = TextEditingController(text: s.batteryLife ?? '');

    // Other
    _categoryController = TextEditingController(text: s.category ?? '');
    _keyFeatureController = TextEditingController(text: s.keyFeature ?? '');

    // Warranty
    _warrantyDurationController = TextEditingController(text: a.warranty?.duration ?? '');
    _warrantyTypeController = TextEditingController(text: a.warranty?.type ?? '');
    _warrantyDescController = TextEditingController(text: a.warranty?.description ?? '');

    // YouTube
    _youtubeUrlController = TextEditingController(text: a.youtubeUrl ?? '');

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
    _connectivityController.dispose();
    _compatibilityController.dispose();
    _materialController.dispose();
    _colorController.dispose();
    _dimensionsController.dispose();
    _weightController.dispose();
    _portsController.dispose();
    _layoutController.dispose();
    _switchTypeController.dispose();
    _backlightController.dispose();
    _keyCountController.dispose();
    _dpiController.dispose();
    _sensorTypeController.dispose();
    _buttonsController.dispose();
    _gpuChipsetController.dispose();
    _vramController.dispose();
    _clockSpeedController.dispose();
    _memoryBusController.dispose();
    _powerRequirementController.dispose();
    _coolingController.dispose();
    _cardLengthController.dispose();
    _wattageController.dispose();
    _outputPortsController.dispose();
    _fastChargingController.dispose();
    _cableIncludedController.dispose();
    _cableTypeController.dispose();
    _cableLengthController.dispose();
    _dataTransferController.dispose();
    _powerDeliveryController.dispose();
    _deviceCompatibilityController.dispose();
    _featuresController.dispose();
    _standTypeController.dispose();
    _adjustableController.dispose();
    _weightCapacityController.dispose();
    _inputPortController.dispose();
    _hubOutputPortsController.dispose();
    _powerPassthroughController.dispose();
    _audioTypeController.dispose();
    _driverSizeController.dispose();
    _noiseCancellationController.dispose();
    _batteryLifeController.dispose();
    _categoryController.dispose();
    _keyFeatureController.dispose();
    _warrantyDurationController.dispose();
    _warrantyTypeController.dispose();
    _warrantyDescController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }

  AccessorySpecs _buildSpecs() {
    String? _val(TextEditingController c) =>
        c.text.trim().isNotEmpty ? c.text.trim() : null;

    return AccessorySpecs(
      connectivity: _val(_connectivityController),
      compatibility: _val(_compatibilityController),
      material: _val(_materialController),
      color: _val(_colorController),
      dimensions: _val(_dimensionsController),
      weight: _val(_weightController),
      ports: _val(_portsController),
      layout: _val(_layoutController),
      switchType: _val(_switchTypeController),
      backlight: _val(_backlightController),
      keyCount: _val(_keyCountController),
      dpi: _val(_dpiController),
      sensorType: _val(_sensorTypeController),
      buttons: _val(_buttonsController),
      gpuChipset: _val(_gpuChipsetController),
      vram: _val(_vramController),
      clockSpeed: _val(_clockSpeedController),
      memoryBus: _val(_memoryBusController),
      powerRequirement: _val(_powerRequirementController),
      cooling: _val(_coolingController),
      cardLength: _val(_cardLengthController),
      wattage: _val(_wattageController),
      outputPorts: _val(_outputPortsController),
      fastCharging: _val(_fastChargingController),
      cableIncluded: _val(_cableIncludedController),
      cableType: _val(_cableTypeController),
      cableLength: _val(_cableLengthController),
      dataTransfer: _val(_dataTransferController),
      powerDelivery: _val(_powerDeliveryController),
      deviceCompatibility: _val(_deviceCompatibilityController),
      features: _val(_featuresController),
      standType: _val(_standTypeController),
      adjustable: _val(_adjustableController),
      weightCapacity: _val(_weightCapacityController),
      inputPort: _val(_inputPortController),
      hubOutputPorts: _val(_hubOutputPortsController),
      powerPassthrough: _val(_powerPassthroughController),
      audioType: _val(_audioTypeController),
      driverSize: _val(_driverSizeController),
      noiseCancellation: _val(_noiseCancellationController),
      batteryLife: _val(_batteryLifeController),
      category: _val(_categoryController),
      keyFeature: _val(_keyFeatureController),
    );
  }

  AccessoryWarranty? _buildWarranty() {
    if (_warrantyDurationController.text.trim().isEmpty &&
        _warrantyTypeController.text.trim().isEmpty) {
      return null;
    }
    return AccessoryWarranty(
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

  Future<void> _updateAccessory() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newImageBytes.isEmpty && _existingImageUrls.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Accessory must have at least one image',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }

    if (_selectedBrandId == null) {
      Fluttertoast.showToast(
        msg: 'Please select a brand',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }

    final provider = context.read<AccessoryProvider>();

    final success = await provider.updateAccessory(
      accessoryId: widget.accessory.id,
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      brandId: _selectedBrandId!,
      brandName: _selectedBrandName!,
      categoryIds: _selectedCategoryIds,
      categoryNames: _selectedCategoryNames,
      accessoryType: _selectedAccessoryType,
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
      warranty: _buildWarranty(),
      youtubeUrl: _youtubeUrlController.text.trim().isNotEmpty
          ? _youtubeUrlController.text.trim()
          : null,
    );

    if (success) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Accessory updated successfully',
          backgroundColor: AppColors.successColor,
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        Fluttertoast.showToast(
          msg: provider.error ?? 'Failed to update accessory',
          backgroundColor: AppColors.errorColor,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Accessory')),
      body: Consumer<AccessoryProvider>(
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
                      _buildSectionTitle('Accessory Type'),
                      const SizedBox(height: AppDimensions.paddingM),
                      _buildAccessoryTypeSelector(),
                      const SizedBox(height: AppDimensions.paddingL),

                      _buildSectionTitle('Accessory Images *'),
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
                          labelText: 'Accessory Name *',
                          hintText: 'e.g., Logitech MX Master 3S',
                        ),
                        validator: (value) => Validators.required(
                          value,
                          fieldName: 'Accessory name',
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      TextFormField(
                        controller: _slugController,
                        decoration: const InputDecoration(
                          labelText: 'Slug *',
                          hintText: 'e.g., logitech-mx-master-3s',
                          helperText: 'URL-friendly version of the name',
                        ),
                        validator: (value) =>
                            Validators.required(value, fieldName: 'Slug'),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),

                      // Brand Selector
                      Consumer<BrandProvider>(
                        builder: (context, brandProvider, child) {
                          return DropdownButtonFormField<String>(
                            value: _selectedBrandId,
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
                            validator: (value) =>
                                value == null ? 'Please select a brand' : null,
                          );
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingM),

                      // Category Chips
                      _buildSectionTitle('Categories'),
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
                            children:
                                categoryProvider.categories.map((category) {
                              final isSelected =
                                  _selectedCategoryIds.contains(category.id);
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
                                      _selectedCategoryNames
                                          .remove(category.name);
                                    }
                                  });
                                },
                                selectedColor:
                                    AppColors.primaryColor.withOpacity(0.2),
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
                                hintText: 'e.g., 8995',
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
                              value: _selectedCondition,
                              decoration: const InputDecoration(
                                labelText: 'Condition *',
                              ),
                              items:
                                  AccessoryCondition.values.map((condition) {
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
                          hintText: 'Enter accessory description',
                        ),
                        maxLines: 4,
                      ),

                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildSectionTitle('Specifications'),
                      const SizedBox(height: AppDimensions.paddingS),
                      Text(
                        'Fields shown are specific to ${AccessoryTypeValues.label(_selectedAccessoryType)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      _buildTypeSpecificSpecs(),

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
                          hintText:
                              'e.g., https://www.youtube.com/watch?v=...',
                          prefixIcon: Icon(Icons.video_library),
                        ),
                      ),

                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildSectionTitle('Settings'),
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
                        subtitle: 'Accessory visibility',
                        value: _isActive,
                        onChanged: (value) =>
                            setState(() => _isActive = value),
                        activeColor: AppColors.successColor,
                      ),

                      const SizedBox(height: AppDimensions.paddingXL),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              provider.isLoading ? null : _updateAccessory,
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
                                    'Update Accessory',
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

              // Upload Progress
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
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppDimensions.paddingS),
                        LinearProgressIndicator(
                          value: provider.uploadProgress,
                          backgroundColor: AppColors.borderColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor),
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

  Widget _buildAccessoryTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AccessoryTypeValues.values.map((type) {
        final isSelected = _selectedAccessoryType == type;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedAccessoryType = type;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AccessoryTypeValues.icon(type),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  AccessoryTypeValues.label(type),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeSpecificSpecs() {
    switch (_selectedAccessoryType) {
      case AccessoryTypeValues.keyboard:
        return _buildKeyboardSpecs();
      case AccessoryTypeValues.mouse:
        return _buildMouseSpecs();
      case AccessoryTypeValues.graphicCard:
        return _buildGraphicCardSpecs();
      case AccessoryTypeValues.charger:
        return _buildChargerSpecs();
      case AccessoryTypeValues.cable:
        return _buildCableSpecs();
      case AccessoryTypeValues.casecover:
        return _buildCaseCoverSpecs();
      case AccessoryTypeValues.stand:
        return _buildStandSpecs();
      case AccessoryTypeValues.hub:
        return _buildHubSpecs();
      case AccessoryTypeValues.audio:
        return _buildAudioSpecs();
      case AccessoryTypeValues.other:
        return _buildOtherSpecs();
      default:
        return _buildOtherSpecs();
    }
  }

  Widget _buildKeyboardSpecs() {
    return Column(children: [
      _specRow(_layoutController, 'Layout', 'e.g., Full-size / TKL / 60%',
          _switchTypeController, 'Switch Type', 'e.g., Mechanical Cherry MX Red'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_connectivityController, 'Connectivity', 'e.g., Wired USB / Bluetooth',
          _backlightController, 'Backlight', 'e.g., RGB / White / None'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_keyCountController, 'Key Count', 'e.g., 104 keys',
          _compatibilityController, 'Compatibility', 'e.g., Windows, Mac, iPad'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_colorController, 'Color', 'e.g., Black / White',
          _weightController, 'Weight', 'e.g., 810g'),
    ]);
  }

  Widget _buildMouseSpecs() {
    return Column(children: [
      _specRow(_dpiController, 'DPI', 'e.g., 25,600 DPI',
          _sensorTypeController, 'Sensor Type', 'e.g., Optical / Laser'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_connectivityController, 'Connectivity', 'e.g., Bluetooth + 2.4GHz',
          _buttonsController, 'Buttons', 'e.g., 7 programmable buttons'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_compatibilityController, 'Compatibility', 'e.g., Windows, Mac',
          _colorController, 'Color', 'e.g., Black / White'),
      const SizedBox(height: AppDimensions.paddingM),
      TextFormField(controller: _weightController,
          decoration: const InputDecoration(labelText: 'Weight', hintText: 'e.g., 95g')),
    ]);
  }

  Widget _buildGraphicCardSpecs() {
    return Column(children: [
      _specRow(_gpuChipsetController, 'GPU Chipset', 'e.g., NVIDIA RTX 4070 Ti',
          _vramController, 'VRAM', 'e.g., 12GB GDDR6X'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_clockSpeedController, 'Clock Speed', 'e.g., Boost: 2610 MHz',
          _memoryBusController, 'Memory Bus', 'e.g., 192-bit'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_powerRequirementController, 'Power Requirement', 'e.g., 285W (8-pin x2)',
          _portsController, 'Ports', 'e.g., 3x DP 1.4a, 1x HDMI 2.1'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_coolingController, 'Cooling', 'e.g., Triple Fan',
          _cardLengthController, 'Card Length', 'e.g., 336mm'),
    ]);
  }

  Widget _buildChargerSpecs() {
    return Column(children: [
      _specRow(_wattageController, 'Wattage', 'e.g., 67W USB-C',
          _outputPortsController, 'Output Ports', 'e.g., 1x USB-C, 1x USB-A'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_fastChargingController, 'Fast Charging', 'e.g., PD 3.0, QC 4.0',
          _compatibilityController, 'Compatibility', 'e.g., MacBook, iPhone'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_cableIncludedController, 'Cable Included', 'e.g., Yes / No',
          _colorController, 'Color', 'e.g., White / Black'),
    ]);
  }

  Widget _buildCableSpecs() {
    return Column(children: [
      _specRow(_cableTypeController, 'Cable Type', 'e.g., USB-C to USB-C',
          _cableLengthController, 'Length', 'e.g., 2 meters'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_dataTransferController, 'Data Transfer', 'e.g., USB 3.2 Gen 2 (10Gbps)',
          _powerDeliveryController, 'Power Delivery', 'e.g., 100W PD'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_materialController, 'Material', 'e.g., Braided Nylon',
          _colorController, 'Color', 'e.g., Space Gray'),
    ]);
  }

  Widget _buildCaseCoverSpecs() {
    return Column(children: [
      _specRow(_deviceCompatibilityController, 'Device Compatibility', 'e.g., iPhone 15 Pro Max',
          _materialController, 'Material', 'e.g., Leather / Silicone'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_featuresController, 'Features', 'e.g., MagSafe, Card Slot',
          _colorController, 'Color', 'e.g., Midnight, Forest Green'),
    ]);
  }

  Widget _buildStandSpecs() {
    return Column(children: [
      _specRow(_standTypeController, 'Stand Type', 'e.g., Laptop Stand / Monitor Arm',
          _materialController, 'Material', 'e.g., Aluminum / Steel'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_adjustableController, 'Adjustable', 'e.g., Height + Tilt',
          _weightCapacityController, 'Weight Capacity', 'e.g., Up to 8 kg'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_compatibilityController, 'Compatibility', 'e.g., Laptops 10"-17"',
          _colorController, 'Color', 'e.g., Silver / Black'),
    ]);
  }

  Widget _buildHubSpecs() {
    return Column(children: [
      _specRow(_inputPortController, 'Input Port', 'e.g., USB-C / Thunderbolt 4',
          _hubOutputPortsController, 'Output Ports', 'e.g., 2x USB-A, HDMI, SD Card'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_powerPassthroughController, 'Power Passthrough', 'e.g., 100W PD',
          _compatibilityController, 'Compatibility', 'e.g., MacBook, Windows'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_materialController, 'Material', 'e.g., Aluminum',
          _colorController, 'Color', 'e.g., Silver / Space Gray'),
    ]);
  }

  Widget _buildAudioSpecs() {
    return Column(children: [
      _specRow(_audioTypeController, 'Audio Type', 'e.g., Over-Ear / In-Ear / Speaker',
          _connectivityController, 'Connectivity', 'e.g., Bluetooth 5.3 / 3.5mm'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_driverSizeController, 'Driver Size', 'e.g., 40mm',
          _noiseCancellationController, 'Noise Cancellation', 'e.g., Active ANC'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_batteryLifeController, 'Battery Life', 'e.g., 30 hours',
          _compatibilityController, 'Compatibility', 'e.g., Universal'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_colorController, 'Color', 'e.g., Black / White',
          _weightController, 'Weight', 'e.g., 250g'),
    ]);
  }

  Widget _buildOtherSpecs() {
    return Column(children: [
      _specRow(_categoryController, 'Category', 'e.g., Adapter / Tool / etc.',
          _compatibilityController, 'Compatibility', 'e.g., Universal'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_keyFeatureController, 'Key Feature', 'Main feature of the product',
          _connectivityController, 'Connectivity', 'e.g., Wired / Wireless'),
      const SizedBox(height: AppDimensions.paddingM),
      _specRow(_materialController, 'Material', 'e.g., Plastic / Metal',
          _colorController, 'Color', 'e.g., Black'),
    ]);
  }

  Widget _specRow(
    TextEditingController c1, String l1, String h1,
    TextEditingController c2, String l2, String h2,
  ) {
    return Row(children: [
      Expanded(child: TextFormField(controller: c1,
          decoration: InputDecoration(labelText: l1, hintText: h1))),
      const SizedBox(width: AppDimensions.paddingM),
      Expanded(child: TextFormField(controller: c2,
          decoration: InputDecoration(labelText: l2, hintText: h2))),
    ]);
  }

  Widget _buildWarrantyForm() {
    return Column(children: [
      Row(children: [
        Expanded(child: TextFormField(controller: _warrantyDurationController,
            decoration: const InputDecoration(labelText: 'Duration', hintText: 'e.g., 6 months'))),
        const SizedBox(width: AppDimensions.paddingM),
        Expanded(child: TextFormField(controller: _warrantyTypeController,
            decoration: const InputDecoration(labelText: 'Type', hintText: 'e.g., Seller Warranty'))),
      ]),
      const SizedBox(height: AppDimensions.paddingM),
      TextFormField(controller: _warrantyDescController,
          decoration: const InputDecoration(
              labelText: 'Warranty Description', hintText: 'Additional warranty details...'),
          maxLines: 2),
    ]);
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
        title: Text(title ,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppColors.textSecondary)),
        value: value,
        onChanged: onChanged,
        activeTrackColor: activeColor,
      ),
    );
  }
}

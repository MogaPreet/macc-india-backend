import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/promo_offer_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/image_uploader.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/utils/validators.dart';

/// Screen for adding a new promo offer
class AddPromoOfferScreen extends StatefulWidget {
  const AddPromoOfferScreen({super.key});

  @override
  State<AddPromoOfferScreen> createState() => _AddPromoOfferScreenState();
}

class _AddPromoOfferScreenState extends State<AddPromoOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();

  Uint8List? _imageBytes;
  late final List<String> _selectedProductIds = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showProductSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Row(
                    children: [
                      const Text(
                        'Select Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: productProvider.products.length,
                    itemBuilder: (context, index) {
                      final product = productProvider.products[index];
                      final isSelected = _selectedProductIds.contains(
                        product.id,
                      );
                      return CheckboxListTile(
                        title: Text(product.name),
                        subtitle: Text(
                          '₹${product.price.toStringAsFixed(0)} • ${product.brandName}',
                        ),
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedProductIds.add(product.id);
                            } else {
                              _selectedProductIds.remove(product.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageBytes == null) {
      Fluttertoast.showToast(
        msg: 'Please select a background image',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }

    if (_selectedProductIds.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please select at least one product',
        backgroundColor: AppColors.errorColor,
      );
      return;
    }

    final provider = context.read<PromoOfferProvider>();

    final success = await provider.addOffer(
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim().isNotEmpty
          ? _subtitleController.text.trim()
          : null,
      imageFile: _imageBytes!,
      productIds: _selectedProductIds,
      startDate: _startDate,
      endDate: _endDate,
      isActive: _isActive,
    );

    if (success) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Promo offer created successfully',
          backgroundColor: AppColors.successColor,
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        Fluttertoast.showToast(
          msg: provider.error ?? 'Failed to create offer',
          backgroundColor: AppColors.errorColor,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Promo Offer')),
      body: Consumer<PromoOfferProvider>(
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
                      // Background Image
                      _buildSectionTitle('Background Image *'),
                      const SizedBox(height: AppDimensions.paddingM),
                      ImageUploader(
                        height: 200,
                        onImageSelected: (bytes, fileName) {
                          setState(() {
                            _imageBytes = bytes;
                          });
                        },
                      ),

                      const SizedBox(height: AppDimensions.paddingXL),

                      // Title
                      _buildSectionTitle('Offer Details'),
                      const SizedBox(height: AppDimensions.paddingM),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'e.g., New Year Sale',
                        ),
                        validator: (value) =>
                            Validators.required(value, fieldName: 'Title'),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      TextFormField(
                        controller: _subtitleController,
                        decoration: const InputDecoration(
                          labelText: 'Subtitle (Optional)',
                          hintText: 'e.g., Up to 30% off on selected items',
                        ),
                      ),

                      const SizedBox(height: AppDimensions.paddingXL),

                      // Products Selection
                      _buildSectionTitle('Products *'),
                      const SizedBox(height: AppDimensions.paddingM),
                      OutlinedButton.icon(
                        onPressed: _showProductSelector,
                        icon: const Icon(Icons.add),
                        label: Text(
                          _selectedProductIds.isEmpty
                              ? 'Select Products'
                              : '${_selectedProductIds.length} products selected',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                        ),
                      ),
                      if (_selectedProductIds.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.paddingM),
                        _buildSelectedProductsPreview(),
                      ],

                      const SizedBox(height: AppDimensions.paddingXL),

                      // Date Range
                      _buildSectionTitle('Date Range (Optional)'),
                      const SizedBox(height: AppDimensions.paddingM),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: 'Start Date',
                              date: _startDate,
                              onTap: () => _selectDate(true),
                              onClear: () => setState(() => _startDate = null),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: _buildDateField(
                              label: 'End Date',
                              date: _endDate,
                              onTap: () => _selectDate(false),
                              onClear: () => setState(() => _endDate = null),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDimensions.paddingXL),

                      // Active Toggle
                      Card(
                        child: SwitchListTile(
                          title: const Text(
                            'Make Active',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Only one offer can be active at a time',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                          activeTrackColor: AppColors.successColor,
                        ),
                      ),

                      const SizedBox(height: AppDimensions.paddingXL),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: provider.isLoading ? null : _saveOffer,
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
                                    'Create Promo Offer',
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
                          'Uploading... ${(provider.uploadProgress * 100).toInt()}%',
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
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          date != null
              ? '${date.day}/${date.month}/${date.year}'
              : 'Select date',
          style: TextStyle(
            color: date != null ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedProductsPreview() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final selectedProducts = productProvider.products
            .where((p) => _selectedProductIds.contains(p.id))
            .toList();

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedProducts.map((product) {
            return Chip(
              label: Text(product.name, style: const TextStyle(fontSize: 12)),
              onDeleted: () {
                setState(() {
                  _selectedProductIds.remove(product.id);
                });
              },
              deleteIconColor: AppColors.textMuted,
            );
          }).toList(),
        );
      },
    );
  }
}

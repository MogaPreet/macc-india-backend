import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../providers/promo_offer_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/promo_offer_model.dart';
import '../../models/product_model.dart';
import '../../widgets/image_uploader.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/utils/validators.dart';
import 'promo_product_picker_screen.dart';

/// Screen for editing an existing promo offer
class EditPromoOfferScreen extends StatefulWidget {
  final PromoOfferModel offer;

  const EditPromoOfferScreen({super.key, required this.offer});

  @override
  State<EditPromoOfferScreen> createState() => _EditPromoOfferScreenState();
}

class _EditPromoOfferScreenState extends State<EditPromoOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;

  Uint8List? _newImageBytes;
  late List<String> _selectedProductIds;
  DateTime? _startDate;
  DateTime? _endDate;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final offer = widget.offer;

    _titleController = TextEditingController(text: offer.title);
    _subtitleController = TextEditingController(text: offer.subtitle ?? '');
    _selectedProductIds = List.from(offer.productIds);
    _startDate = offer.startDate;
    _endDate = offer.endDate;
    _isActive = offer.isActive;

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

  Future<void> _openPromoProductPicker() async {
    await context.read<ProductProvider>().fetchProducts();
    if (!mounted) return;
    final result = await Navigator.of(context).push<List<String>?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PromoProductPickerScreen(
          initialProductIds: List<String>.from(_selectedProductIds),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedProductIds = result);
    }
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

  bool _validateDateRange() {
    if (_startDate != null && _endDate != null) {
      final s = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final e = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
      if (e.isBefore(s)) {
        Fluttertoast.showToast(
          msg: 'End date must be on or after start date',
          backgroundColor: AppColors.errorColor,
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _updateOffer() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateDateRange()) return;

    if (_newImageBytes == null && widget.offer.backgroundImage.isEmpty) {
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

    final success = await provider.updateOffer(
      offerId: widget.offer.id,
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim().isNotEmpty
          ? _subtitleController.text.trim()
          : null,
      newImageFile: _newImageBytes,
      existingImageUrl: widget.offer.backgroundImage,
      productIds: _selectedProductIds,
      startDate: _startDate,
      endDate: _endDate,
      isActive: _isActive,
    );

    if (success) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Promo offer updated successfully',
          backgroundColor: AppColors.successColor,
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        Fluttertoast.showToast(
          msg: provider.error ?? 'Failed to update offer',
          backgroundColor: AppColors.errorColor,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Promo Offer')),
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
                      _buildSectionTitle('Hero image *'),
                      const SizedBox(height: AppDimensions.paddingS),
                      Text(
                        'Replace the storefront banner or keep the current image.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      ImageUploader(
                        height: 220,
                        initialImageUrl: widget.offer.backgroundImage,
                        onImageSelected: (bytes, fileName) {
                          setState(() {
                            _newImageBytes = bytes;
                          });
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildSectionTitle('Offer details'),
                      const SizedBox(height: AppDimensions.paddingM),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'e.g., New Year Sale',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            Validators.required(value, fieldName: 'Title'),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      TextFormField(
                        controller: _subtitleController,
                        decoration: const InputDecoration(
                          labelText: 'Subtitle (optional)',
                          hintText: 'e.g., Up to 30% off on selected items',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildProductsPanel(),
                      const SizedBox(height: AppDimensions.paddingXL),
                      _buildSectionTitle('Schedule (optional)'),
                      const SizedBox(height: AppDimensions.paddingS),
                      Text(
                        'Dates are inclusive.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: 'Start date',
                              date: _startDate,
                              onTap: () => _selectDate(true),
                              onClear: () => setState(() => _startDate = null),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: _buildDateField(
                              label: 'End date',
                              date: _endDate,
                              onTap: () => _selectDate(false),
                              onClear: () => setState(() => _endDate = null),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingXL),
                      Card(
                        child: SwitchListTile(
                          title: const Text(
                            'Active',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Activating turns other offers off.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                          activeTrackColor: AppColors.successColor,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingXL),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: provider.isLoading ? null : _updateOffer,
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
                                    'Update promo offer',
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

  Widget _buildProductsPanel() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.hotDealColor.withValues(alpha: 0.12),
            AppColors.surfaceColor.withValues(alpha: 0.6),
          ],
        ),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.hotDealColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: AppColors.hotDealColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured products *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse the catalog or drag rows to reorder.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingL),
          FilledButton.icon(
            onPressed: _openPromoProductPicker,
            icon: const Icon(Icons.edit_rounded),
            label: Text(
              _selectedProductIds.isEmpty
                  ? 'Browse catalog & add products'
                  : 'Edit selection (${_selectedProductIds.length})',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          if (_selectedProductIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No products — add at least one.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            Consumer<ProductProvider>(
              builder: (context, productProvider, _) {
                return ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: _selectedProductIds.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final id = _selectedProductIds.removeAt(oldIndex);
                      _selectedProductIds.insert(newIndex, id);
                    });
                  },
                  itemBuilder: (context, index) {
                    final id = _selectedProductIds[index];
                    final p = productProvider.getProductById(id);
                    return _PromoSelectedRow(
                      key: ValueKey('promo_edit_$id'),
                      index: index,
                      product: p,
                      productId: id,
                      onRemove: () {
                        setState(() => _selectedProductIds.removeAt(index));
                      },
                    );
                  },
                );
              },
            ),
        ],
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
          border: const OutlineInputBorder(),
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
}

class _PromoSelectedRow extends StatelessWidget {
  const _PromoSelectedRow({
    super.key,
    required this.index,
    required this.product,
    required this.productId,
    required this.onRemove,
  });

  final int index;
  final ProductModel? product;
  final String productId;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final title = product?.name ?? 'Removed product';
    final subtitle = product != null
        ? '${ProductType.label(product!.productType)} · ${product!.brandName}'
        : 'ID: $productId — re-pick or remove';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ReorderableDragStartListener(
          index: index,
          child: SizedBox(
            width: 56,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: product != null && product!.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product!.mainImage,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: AppColors.surfaceColor,
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    )
                  : const ColoredBox(
                      color: AppColors.surfaceColor,
                      child: Icon(Icons.inventory_2_outlined,
                          color: AppColors.textMuted),
                    ),
            ),
          ),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: AppColors.errorColor),
          onPressed: onRemove,
          tooltip: 'Remove',
        ),
      ),
    );
  }
}

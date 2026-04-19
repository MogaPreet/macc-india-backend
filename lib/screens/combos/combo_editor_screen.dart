import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/utils/validators.dart';
import '../../models/combo_model.dart';
import '../../models/product_model.dart';
import '../../providers/combo_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/multi_image_uploader.dart';
import 'combo_product_picker_screen.dart';

/// Create or edit a product combo (2+ catalog products).
class ComboEditorScreen extends StatefulWidget {
  const ComboEditorScreen({super.key, this.existing});

  final ProductComboModel? existing;

  bool get isEditing => existing != null;

  @override
  State<ComboEditorScreen> createState() => _ComboEditorScreenState();
}

class _ComboEditorScreenState extends State<ComboEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _youtubeController = TextEditingController();

  List<Uint8List> _newImageBytes = [];
  List<String> _existingImageUrls = [];

  bool _isFeatured = false;
  bool _isActive = true;

  /// Ordered bundle lines (sortOrder is recomputed on save).
  List<ComboComponent> _components = [];

  String? _slugAutoFromName;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _slugController.text = e.slug;
      _slugAutoFromName = ProductComboModel.generateSlug(e.name);
      _descriptionController.text = e.description ?? '';
      _priceController.text = e.price.toStringAsFixed(0);
      _originalPriceController.text = e.originalPrice?.toStringAsFixed(0) ?? '';
      _stockController.text = e.stock.toString();
      _youtubeController.text = e.youtubeUrl ?? '';
      _isFeatured = e.isFeatured;
      _isActive = e.isActive;
      _existingImageUrls = List.from(e.images);
      _components = List.from(e.components);
    }

    _nameController.addListener(_onNameChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  void _onNameChanged() {
    final auto = ProductComboModel.generateSlug(_nameController.text);
    if (_slugController.text.isEmpty ||
        _slugController.text == _slugAutoFromName) {
      _slugController.text = auto;
    }
    _slugAutoFromName = auto;
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  void _fillOriginalFromProducts() {
    final productProvider = context.read<ProductProvider>();
    double sum = 0;
    for (final c in _components) {
      final p = productProvider.getProductById(c.productId);
      if (p != null) {
        sum += p.price * c.quantity;
      }
    }
    if (sum <= 0) {
      Fluttertoast.showToast(
        msg: 'Could not resolve products for sum. Add items or refresh list.',
      );
      return;
    }
    setState(() {
      _originalPriceController.text = sum.toStringAsFixed(0);
    });
  }

  Future<void> _pickProducts() async {
    await context.read<ProductProvider>().fetchProducts();
    if (!mounted) return;

    final selected = await Navigator.of(context).push<List<ProductModel>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ComboProductPickerScreen(
          existingProductIds: _components.map((c) => c.productId).toSet(),
        ),
      ),
    );

    if (selected == null || selected.isEmpty) return;

    setState(() {
      for (final p in selected) {
        if (_components.any((c) => c.productId == p.id)) continue;
        _components.add(
          ComboComponent(
            productId: p.id,
            quantity: 1,
            sortOrder: _components.length,
            productNameSnapshot: p.name,
          ),
        );
      }
    });
  }

  List<ComboComponent> _normalizedComponents(ProductProvider products) {
    final out = <ComboComponent>[];
    for (var i = 0; i < _components.length; i++) {
      final c = _components[i];
      final p = products.getProductById(c.productId);
      out.add(
        c.copyWith(
          sortOrder: i,
          productNameSnapshot: p?.name ?? c.productNameSnapshot,
        ),
      );
    }
    return out;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_components.length < 2) {
      Fluttertoast.showToast(
        msg: 'Add at least two products to this combo.',
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price < 0) {
      Fluttertoast.showToast(msg: 'Enter a valid combo price.');
      return;
    }

    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    if (stock < 0) {
      Fluttertoast.showToast(msg: 'Stock must be zero or greater.');
      return;
    }

    final originalRaw = _originalPriceController.text.trim();
    double? originalPrice;
    if (originalRaw.isNotEmpty) {
      originalPrice = double.tryParse(originalRaw);
      if (originalPrice == null || originalPrice < 0) {
        Fluttertoast.showToast(msg: 'Original price is invalid.');
        return;
      }
    }

    final productProvider = context.read<ProductProvider>();
    final normalized = _normalizedComponents(productProvider);

    final description = _descriptionController.text.trim();
    final youtube = _youtubeController.text.trim();

    final comboProvider = context.read<ComboProvider>();
    final ok = widget.isEditing
        ? await comboProvider.updateCombo(
            comboId: widget.existing!.id,
            name: _nameController.text.trim(),
            slug: _slugController.text.trim(),
            description: description.isEmpty ? null : description,
            components: normalized,
            price: price,
            originalPrice: originalPrice,
            stock: stock,
            isFeatured: _isFeatured,
            isActive: _isActive,
            newImageFiles:
                _newImageBytes.isNotEmpty ? _newImageBytes : null,
            existingImageUrls: _existingImageUrls,
            youtubeUrl: youtube.isEmpty ? null : youtube,
          )
        : await comboProvider.addCombo(
            name: _nameController.text.trim(),
            slug: _slugController.text.trim(),
            description: description.isEmpty ? null : description,
            components: normalized,
            price: price,
            originalPrice: originalPrice,
            stock: stock,
            isFeatured: _isFeatured,
            isActive: _isActive,
            imageFiles: _newImageBytes,
            youtubeUrl: youtube.isEmpty ? null : youtube,
          );

    if (!mounted) return;

    if (ok) {
      Fluttertoast.showToast(
        msg: widget.isEditing ? 'Combo updated' : 'Combo created',
      );
      Navigator.pop(context);
    } else if (comboProvider.error != null) {
      Fluttertoast.showToast(msg: comboProvider.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit combo' : 'New combo'),
        actions: [
          TextButton.icon(
            onPressed: context.watch<ComboProvider>().isLoading ? null : _submit,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          children: [
            MultiImageUploader(
              height: 200,
              initialImageUrls: _existingImageUrls,
              onImagesChanged: (newImages, keptUrls) {
                setState(() {
                  _newImageBytes = newImages;
                  _existingImageUrls = keptUrls;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Hero images for this bundle (optional — detail view still shows each product).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Combo name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.required(v, fieldName: 'Name'),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'Slug *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.required(v, fieldName: 'Slug'),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Short description / marketing copy',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 8,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Combo price (₹) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (v) =>
                        Validators.required(v, fieldName: 'Price'),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: TextFormField(
                    controller: _originalPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Original / list total (₹)',
                      border: OutlineInputBorder(),
                      hintText: 'Optional — shows savings',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed:
                    _components.length < 2 ? null : _fillOriginalFromProducts,
                icon: const Icon(Icons.calculate_outlined, size: 18),
                label: const Text('Set original from sum of product prices'),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Combo stock *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => Validators.required(v, fieldName: 'Stock'),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            TextFormField(
              controller: _youtubeController,
              decoration: const InputDecoration(
                labelText: 'YouTube URL (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            SwitchListTile(
              title: const Text('Featured'),
              value: _isFeatured,
              onChanged: (v) => setState(() => _isFeatured = v),
            ),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const Divider(height: AppDimensions.paddingXL),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDark.withValues(alpha: 0.2),
                    AppColors.surfaceColor.withValues(alpha: 0.5),
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
                          color: AppColors.primaryColor.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        child: const Icon(
                          Icons.layers_rounded,
                          color: AppColors.primaryLight,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bundle items',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Open the full-screen catalog to search, filter by type, and pick products in grid or list view. Drag rows to set storefront order.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
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
                    onPressed: _pickProducts,
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('Browse catalog & add products'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  if (_components.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingXL,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 40,
                            color: AppColors.textMuted.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No products yet',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add at least two items to publish this combo.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _components.length,
                      buildDefaultDragHandles: false,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _components.removeAt(oldIndex);
                          _components.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final c = _components[index];
                        final p = productProvider.getProductById(c.productId);
                        final title =
                            p?.name ?? c.productNameSnapshot ?? 'Unknown';
                        final subtitle = p != null
                            ? '${ProductType.label(p.productType)} · ${p.brandName}'
                            : 'Product may have been removed';
                        final thumb = p?.mainImage ?? '';

                        return Card(
                          key: ValueKey('${c.productId}_$index'),
                          margin: const EdgeInsets.only(
                            bottom: AppDimensions.paddingM,
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusL,
                            ),
                            side: const BorderSide(
                              color: AppColors.borderColor,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                leading: ReorderableDragStartListener(
                                  index: index,
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusM,
                                      ),
                                      color: AppColors.surfaceColor,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: thumb.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: thumb,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) =>
                                                const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                            errorWidget: (_, __, ___) =>
                                                const Icon(
                                              Icons.inventory_2_outlined,
                                              color: AppColors.textMuted,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.inventory_2_outlined,
                                            color: AppColors.textMuted,
                                          ),
                                  ),
                                ),
                                title: Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(subtitle),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Decrease quantity',
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: c.quantity <= 1
                                          ? null
                                          : () {
                                              setState(() {
                                                _components[index] = c.copyWith(
                                                  quantity: c.quantity - 1,
                                                );
                                              });
                                            },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        '${c.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Increase quantity',
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _components[index] = c.copyWith(
                                            quantity: c.quantity + 1,
                                          );
                                        });
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Remove from bundle',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.errorColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _components.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              if (p != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    12,
                                    10,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        Chip(
                                          label: Text(
                                            '₹${p.price.toStringAsFixed(0)}',
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: AppColors
                                              .primaryColor
                                              .withValues(alpha: 0.12),
                                          labelStyle: const TextStyle(
                                            color: AppColors.primaryLight,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Chip(
                                          label: Text('Stock ${p.stock}'),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        Chip(
                                          label: Text(p.condition),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Tip: drag the left edge of a row (on the image) to reorder. Use − / + for quantity.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingXL),
          ],
        ),
      ),
    );
  }
}

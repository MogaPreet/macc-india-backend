import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';

/// Full-screen immersive picker to add catalog products to a combo.
class ComboProductPickerScreen extends StatefulWidget {
  const ComboProductPickerScreen({
    super.key,
    required this.existingProductIds,
  });

  final Set<String> existingProductIds;

  @override
  State<ComboProductPickerScreen> createState() =>
      _ComboProductPickerScreenState();
}

class _ComboProductPickerScreenState extends State<ComboProductPickerScreen> {
  final _searchFocus = FocusNode();
  final _searchController = TextEditingController();
  String _query = '';
  String? _typeFilter;
  bool _gridMode = true;
  final Set<String> _picked = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _filtered(List<ProductModel> all) {
    return all.where((p) {
      if (_typeFilter != null && p.productType != _typeFilter) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.brandName.toLowerCase().contains(q) ||
          ProductType.label(p.productType).toLowerCase().contains(q) ||
          (p.specs.processor?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _togglePick(String id, {required bool inBundle}) {
    if (inBundle) return;
    setState(() {
      if (_picked.contains(id)) {
        _picked.remove(id);
      } else {
        _picked.add(id);
      }
    });
  }

  void _clearPicked() => setState(_picked.clear);

  void _confirm(BuildContext context) {
    final products = context.read<ProductProvider>().products;
    final out = products.where((p) => _picked.contains(p.id)).toList();
    Navigator.of(context).pop(out);
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final all = productProvider.products;
    final filtered = _filtered(all);
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width > 1100
        ? 4
        : width > 720
            ? 3
            : 2;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              onClose: () => Navigator.of(context).pop(),
              selectedCount: _picked.length,
              alreadyInBundle: widget.existingProductIds.length,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingL,
                0,
                AppDimensions.paddingL,
                AppDimensions.paddingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by name, brand, type, or processor…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusL),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusL),
                        borderSide:
                            const BorderSide(color: AppColors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusL),
                        borderSide: const BorderSide(
                          color: AppColors.primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('All types'),
                            selected: _typeFilter == null,
                            onSelected: (_) =>
                                setState(() => _typeFilter = null),
                            selectedColor:
                                AppColors.primaryColor.withValues(alpha: 0.25),
                            checkmarkColor: AppColors.primaryLight,
                          ),
                        ),
                        ...ProductType.values.map((type) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(ProductType.label(type)),
                              selected: _typeFilter == type,
                              onSelected: (sel) => setState(
                                () => _typeFilter = sel ? type : null,
                              ),
                              selectedColor: AppColors.primaryColor
                                  .withValues(alpha: 0.25),
                              checkmarkColor: AppColors.primaryLight,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Row(
                    children: [
                      Text(
                        '${filtered.length} product${filtered.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                      const Spacer(),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('List'),
                            icon: Icon(Icons.view_list_rounded, size: 18),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Grid'),
                            icon: Icon(Icons.grid_view_rounded, size: 18),
                          ),
                        ],
                        selected: {_gridMode},
                        onSelectionChanged: (s) =>
                            setState(() => _gridMode = s.first),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: productProvider.isLoading && all.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : all.isEmpty
                      ? _EmptyCatalog(onRetry: productProvider.fetchProducts)
                      : filtered.isEmpty
                          ? _NoMatches(onClear: () {
                              setState(() {
                                _query = '';
                                _searchController.clear();
                                _typeFilter = null;
                              });
                            })
                          : RefreshIndicator(
                              color: AppColors.primaryColor,
                              onRefresh: () => productProvider.fetchProducts(),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                child: _gridMode
                                    ? GridView.builder(
                                        key: const ValueKey('grid'),
                                        padding: const EdgeInsets.fromLTRB(
                                          AppDimensions.paddingL,
                                          0,
                                          AppDimensions.paddingL,
                                          100,
                                        ),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          mainAxisSpacing: 12,
                                          crossAxisSpacing: 12,
                                          childAspectRatio: 0.72,
                                        ),
                                        itemCount: filtered.length,
                                        itemBuilder: (context, i) =>
                                            _ProductGridTile(
                                          product: filtered[i],
                                          inBundle: widget
                                              .existingProductIds
                                              .contains(filtered[i].id),
                                          selected:
                                              _picked.contains(filtered[i].id),
                                          onTap: () => _togglePick(
                                            filtered[i].id,
                                            inBundle: widget
                                                .existingProductIds
                                                .contains(filtered[i].id),
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        key: const ValueKey('list'),
                                        padding: const EdgeInsets.fromLTRB(
                                          AppDimensions.paddingL,
                                          0,
                                          AppDimensions.paddingL,
                                          100,
                                        ),
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, i) =>
                                            _ProductListTile(
                                          product: filtered[i],
                                          inBundle: widget
                                              .existingProductIds
                                              .contains(filtered[i].id),
                                          selected:
                                              _picked.contains(filtered[i].id),
                                          onTap: () => _togglePick(
                                            filtered[i].id,
                                            inBundle: widget
                                                .existingProductIds
                                                .contains(filtered[i].id),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
            ),
            _BottomBar(
              pickedCount: _picked.length,
              onClear: _picked.isEmpty ? null : _clearPicked,
              onAdd: _picked.isEmpty
                  ? null
                  : () => _confirm(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onClose,
    required this.selectedCount,
    required this.alreadyInBundle,
  });

  final VoidCallback onClose;
  final int selectedCount;
  final int alreadyInBundle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark.withValues(alpha: 0.35),
            AppColors.backgroundColor,
            AppColors.surfaceColor.withValues(alpha: 0.4),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.dividerColor),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingS,
        AppDimensions.paddingM,
        AppDimensions.paddingM,
        AppDimensions.paddingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build your bundle',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick two or more products. Items already in this combo are marked and locked.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _StatChip(
                icon: Icons.inventory_2_outlined,
                label: '$selectedCount new',
                emphasized: selectedCount > 0,
              ),
              _StatChip(
                icon: Icons.layers_outlined,
                label: '$alreadyInBundle in combo',
                emphasized: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.emphasized,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.primaryColor.withValues(alpha: 0.2)
            : AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: emphasized ? AppColors.primaryColor : AppColors.borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: emphasized ? AppColors.primaryLight : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: emphasized ? AppColors.primaryLight : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductGridTile extends StatelessWidget {
  const _ProductGridTile({
    required this.product,
    required this.inBundle,
    required this.selected,
    required this.onTap,
  });

  final ProductModel product;
  final bool inBundle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canTap = !inBundle;
    final borderColor = inBundle
        ? AppColors.warningColor
        : selected
            ? AppColors.primaryColor
            : AppColors.borderColor;
    final glow = !inBundle && selected;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(
              color: borderColor,
              width: (selected || inBundle) ? 2 : 1,
            ),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: AppColors.surfaceColor,
                      child: product.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.mainImage,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 40,
                                color: AppColors.textMuted,
                              ),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: Text(
                          ProductType.label(product.productType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (inBundle)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          color: AppColors.warningColor.withValues(alpha: 0.92),
                          child: const Text(
                            'Already in bundle',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (selected && !inBundle)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.brandName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  const _ProductListTile({
    required this.product,
    required this.inBundle,
    required this.selected,
    required this.onTap,
  });

  final ProductModel product;
  final bool inBundle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canTap = !inBundle;

    return Material(
      color: AppColors.surfaceColor,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(
              color: inBundle
                  ? AppColors.warningColor
                  : selected
                      ? AppColors.primaryColor
                      : AppColors.borderColor,
              width: (selected || inBundle) ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: product.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.mainImage,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.cardColor,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const ColoredBox(
                            color: AppColors.cardColor,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        )
                      : const ColoredBox(
                          color: AppColors.cardColor,
                          child: Icon(Icons.inventory_2_outlined),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.brandName} · ${ProductType.label(product.productType)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (inBundle)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warningColor.withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: const Text(
                    'In bundle',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warningColor,
                    ),
                  ),
                )
              else
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected
                      ? AppColors.primaryColor
                      : AppColors.textMuted,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.pickedCount,
    required this.onClear,
    required this.onAdd,
  });

  final int pickedCount;
  final VoidCallback? onClear;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: AppColors.surfaceColor,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingL,
            AppDimensions.paddingM,
            AppDimensions.paddingL,
            AppDimensions.paddingM,
          ),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.dividerColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pickedCount selected',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      pickedCount == 0
                          ? 'Tap products to add them to this combo'
                          : 'Tap “Add to combo” to confirm',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Add to combo'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'No products in catalog',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create products first, then return here to bundle them.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
        Icon(Icons.search_off_rounded, size: 56, color: AppColors.textMuted),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'No matches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Try another search or clear filters.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Clear search & type'),
          ),
        ),
      ],
    );
  }
}

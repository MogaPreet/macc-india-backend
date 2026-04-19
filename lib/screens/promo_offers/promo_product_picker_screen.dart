import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';

/// Full-screen picker for promo-linked products. Preserves order; fixes bottom-sheet setState bugs.
class PromoProductPickerScreen extends StatefulWidget {
  const PromoProductPickerScreen({
    super.key,
    required this.initialProductIds,
  });

  /// Order is preserved for `productIds` on the promo.
  final List<String> initialProductIds;

  @override
  State<PromoProductPickerScreen> createState() =>
      _PromoProductPickerScreenState();
}

class _PromoProductPickerScreenState extends State<PromoProductPickerScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  String? _typeFilter;
  bool _gridMode = true;

  /// Selection order = storefront order.
  late List<String> _orderedIds;

  @override
  void initState() {
    super.initState();
    _orderedIds = List.from(widget.initialProductIds);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductProvider>().fetchProducts();
      _pruneMissingIds();
    });
  }

  void _pruneMissingIds() {
    final ids = context.read<ProductProvider>().products.map((p) => p.id).toSet();
    setState(() {
      _orderedIds = _orderedIds.where((id) => ids.contains(id)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
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

  bool _isSelected(String id) => _orderedIds.contains(id);

  void _toggle(String id) {
    setState(() {
      if (_orderedIds.contains(id)) {
        _orderedIds.remove(id);
      } else {
        _orderedIds.add(id);
      }
    });
  }

  void _clear() => setState(_orderedIds.clear);

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final all = productProvider.products;
    final filtered = _filtered(all);
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount =
        width > 1100 ? 4 : (width > 720 ? 3 : 2);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PromoPickerHeader(
              onClose: () => Navigator.of(context).pop<List<String>?>(),
              count: _orderedIds.length,
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
                      hintText: 'Search name, brand, type, processor…',
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
                        '${filtered.length} shown',
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
                      ? _EmptyPromoCatalog(
                          onRetry: productProvider.fetchProducts,
                        )
                      : filtered.isEmpty
                          ? _NoPromoMatches(
                              onClear: () {
                                setState(() {
                                  _query = '';
                                  _searchController.clear();
                                  _typeFilter = null;
                                });
                              },
                            )
                          : RefreshIndicator(
                              color: AppColors.primaryColor,
                              onRefresh: productProvider.fetchProducts,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
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
                                        itemBuilder: (context, i) {
                                          final p = filtered[i];
                                          return _PromoPickGridTile(
                                            product: p,
                                            selected: _isSelected(p.id),
                                            onTap: () => _toggle(p.id),
                                          );
                                        },
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
                                        itemBuilder: (context, i) {
                                          final p = filtered[i];
                                          return _PromoPickListTile(
                                            product: p,
                                            selected: _isSelected(p.id),
                                            onTap: () => _toggle(p.id),
                                          );
                                        },
                                      ),
                              ),
                            ),
            ),
            _PromoPickerBottomBar(
              count: _orderedIds.length,
              onClear: _orderedIds.isEmpty ? null : _clear,
              onDone: _orderedIds.isEmpty
                  ? null
                  : () => Navigator.of(context).pop<List<String>>(
                        List<String>.from(_orderedIds),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoPickerHeader extends StatelessWidget {
  const _PromoPickerHeader({
    required this.onClose,
    required this.count,
  });

  final VoidCallback onClose;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.hotDealColor.withValues(alpha: 0.25),
            AppColors.backgroundColor,
            AppColors.surfaceColor.withValues(alpha: 0.35),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.dividerColor),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Products in this promo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap items to include them. Order here is the order shoppers will see. You can fine-tune order on the previous screen.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(color: AppColors.primaryColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.checklist_rounded,
                          size: 18, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Text(
                        '$count in promo',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoPickGridTile extends StatelessWidget {
  const _PromoPickGridTile({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final ProductModel product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(
              color:
                  selected ? AppColors.primaryColor : AppColors.borderColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.18),
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
                                child: Icon(Icons.image_not_supported_outlined),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.inventory_2_outlined,
                                  size: 40, color: AppColors.textMuted),
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
                    if (selected)
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

class _PromoPickListTile extends StatelessWidget {
  const _PromoPickListTile({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final ProductModel product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceColor,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(
              color:
                  selected ? AppColors.primaryColor : AppColors.borderColor,
              width: selected ? 2 : 1,
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
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color:
                    selected ? AppColors.primaryColor : AppColors.textMuted,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoPickerBottomBar extends StatelessWidget {
  const _PromoPickerBottomBar({
    required this.count,
    required this.onClear,
    required this.onDone,
  });

  final int count;
  final VoidCallback? onClear;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
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
            border: Border(top: BorderSide(color: AppColors.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count selected',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      count == 0
                          ? 'Select at least one product'
                          : 'Tap Done to apply',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onClear, child: const Text('Clear all')),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onDone,
                icon: const Icon(Icons.done_rounded, size: 20),
                label: const Text('Done'),
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

class _EmptyPromoCatalog extends StatelessWidget {
  const _EmptyPromoCatalog({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No products loaded',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add products in the catalog first.',
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
    );
  }
}

class _NoPromoMatches extends StatelessWidget {
  const _NoPromoMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
        const Icon(Icons.search_off_rounded,
            size: 56, color: AppColors.textMuted),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'No matches',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Try different keywords or clear filters.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Clear filters'),
          ),
        ),
      ],
    );
  }
}

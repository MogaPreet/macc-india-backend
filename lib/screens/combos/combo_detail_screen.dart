import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../models/combo_model.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_description_view.dart';

/// Storefront-style immersive preview of a combo and each bundled product.
class ComboDetailScreen extends StatefulWidget {
  const ComboDetailScreen({super.key, required this.combo});

  final ProductComboModel combo;

  @override
  State<ComboDetailScreen> createState() => _ComboDetailScreenState();
}

class _ComboDetailScreenState extends State<ComboDetailScreen> {
  final _heroPage = PageController();
  int _heroIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _heroPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final combo = widget.combo;
    final products = context.watch<ProductProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: combo.images.isEmpty ? 140 : 280,
            backgroundColor: AppColors.surfaceColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 56,
                bottom: 16,
                end: 12,
              ),
              title: Text(
                combo.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              background: combo.images.isEmpty
                  ? Container(
                      color: AppColors.surfaceColor,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.layers_outlined,
                        size: 72,
                        color: AppColors.textMuted,
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          controller: _heroPage,
                          onPageChanged: (i) =>
                              setState(() => _heroIndex = i),
                          itemCount: combo.images.length,
                          itemBuilder: (context, i) {
                            return CachedNetworkImage(
                              imageUrl: combo.images[i],
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.surfaceColor,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.surfaceColor,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            );
                          },
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black87,
                              ],
                              stops: [0.55, 1],
                            ),
                          ),
                        ),
                        if (combo.images.length > 1)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                combo.images.length,
                                (i) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _heroIndex == i
                                        ? AppColors.primaryColor
                                        : Colors.white38,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                        label: Text(
                          '${combo.components.length} items',
                        ),
                      ),
                      Chip(
                        avatar: Icon(
                          combo.isActive
                              ? Icons.check_circle_outline
                              : Icons.pause_circle_outline,
                          size: 18,
                        ),
                        label: Text(
                          combo.isActive ? 'Active' : 'Inactive',
                        ),
                      ),
                      Chip(
                        label: Text('Stock: ${combo.stock}'),
                      ),
                      if (combo.isFeatured)
                        Chip(
                          avatar: const Icon(Icons.star, size: 18),
                          label: const Text('Featured combo'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${combo.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (combo.hasDiscount) ...[
                        const SizedBox(width: 12),
                        Text(
                          '₹${combo.originalPrice!.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textMuted,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusS),
                          ),
                          child: Text(
                            'Save ${combo.discountPercentage}%',
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (combo.description != null &&
                      combo.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.paddingL),
                    Text(
                      'About this bundle',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.paddingS),
                    ProductDescriptionView(
                      description: combo.description,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                  if (combo.youtubeUrl != null &&
                      combo.youtubeUrl!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.paddingM),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.ondemand_video_outlined),
                      title: const Text('Video'),
                      subtitle: Text(
                        combo.youtubeUrl!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.paddingXL),
                  Text(
                    "What's included",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Each product is shown with catalog details your customers will see.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  ...combo.components.map((line) {
                    final p = products.getProductById(line.productId);
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.paddingL,
                      ),
                      child: _BundleProductCard(
                        product: p,
                        line: line,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BundleProductCard extends StatefulWidget {
  const _BundleProductCard({
    required this.product,
    required this.line,
  });

  final ProductModel? product;
  final ComboComponent line;

  @override
  State<_BundleProductCard> createState() => _BundleProductCardState();
}

class _BundleProductCardState extends State<_BundleProductCard> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final line = widget.line;
    final name = p?.name ?? line.productNameSnapshot ?? 'Removed product';
    final images = p?.images ?? const <String>[];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.borderColor),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceColor,
            AppColors.surfaceColor.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (p == null)
            Container(
              color: AppColors.errorColor.withValues(alpha: 0.12),
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.errorColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This product is no longer in the catalog. Showing saved name: $name',
                      style: TextStyle(
                        color: AppColors.errorColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (images.isNotEmpty)
            SizedBox(
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: images.length,
                    itemBuilder: (context, i) {
                      return CachedNetworkImage(
                        imageUrl: images[i],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceColor,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceColor,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      );
                    },
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (i) => Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _page == i
                                  ? Colors.white
                                  : Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              height: 120,
              color: AppColors.surfaceColor,
              child: Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (p != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${p.brandName} · ${ProductType.label(p.productType)}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM),
                      ),
                      child: Text(
                        '× ${line.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (p != null) ...[
                  const SizedBox(height: AppDimensions.paddingM),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _smallMeta(Icons.verified_outlined, p.condition),
                      _smallMeta(
                        Icons.warehouse_outlined,
                        'Stock ${p.stock}',
                      ),
                      _smallMeta(
                        Icons.sell_outlined,
                        '₹${p.price.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                  if (p.description != null &&
                      p.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.paddingL),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.paddingS),
                    ProductDescriptionView(
                      description: p.description,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                  if (p.includedItems.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.paddingL),
                    Text(
                      'In the box',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.paddingS),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.includedItems
                          .where((e) => e.included)
                          .map(
                            (e) => Chip(
                              label: Text('${e.icon} ${e.name}'),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (p.warranty != null && p.warranty!.hasWarranty) ...[
                    const SizedBox(height: AppDimensions.paddingM),
                    Text(
                      'Warranty',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (p.warranty!.duration != null)
                          p.warranty!.duration,
                        if (p.warranty!.type != null) p.warranty!.type,
                        if (p.warranty!.description != null)
                          p.warranty!.description,
                      ].whereType<String>().join(' · '),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                  ..._specSection(context, p),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallMeta(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.textSecondary),
      label: Text(text),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: AppColors.borderColor),
      backgroundColor: AppColors.backgroundColor,
    );
  }

  List<Widget> _specSection(BuildContext context, ProductModel p) {
    final rows = _specRows(p);
    if (rows.isEmpty) return <Widget>[];

    return [
      const SizedBox(height: AppDimensions.paddingL),
      Text(
        'Specifications',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      const SizedBox(height: AppDimensions.paddingS),
      ...rows.map(
        (e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  e.$1,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  e.$2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

List<(String, String)> _specRows(ProductModel p) {
  final s = p.specs;
  final out = <(String, String)>[];
  void a(String k, String? v) {
    final t = v?.trim();
    if (t != null && t.isNotEmpty) out.add((k, t));
  }

  switch (p.productType) {
    case ProductType.monitor:
      a('Panel', s.panelType);
      a('Resolution', s.resolution);
      a('Refresh rate', s.refreshRate);
      a('Response time', s.responseTime);
      a('Display size', s.displaySize);
      a('Ports', s.ports);
      a('Weight', s.weight);
      break;
    case ProductType.phone:
    case ProductType.ipad:
      a('Screen', s.screenSize);
      a('Camera', s.camera);
      a('Chipset', s.chipset);
      a('SIM', s.simType);
      a('Connectivity', s.connectivity);
      a('Water resistance', s.waterResistance);
      a('Biometrics', s.biometrics);
      a('Colors', s.colorOptions);
      a('Pencil', s.pencilSupport);
      a('Keyboard', s.keyboardSupport);
      a('Battery', s.battery);
      a('OS', s.os);
      a('Weight', s.weight);
      break;
    default:
      a('Processor', s.processor);
      a('RAM', s.ram);
      a('Storage', s.storage);
      a('Screen', s.screen);
      a('Graphics', s.graphics);
      a('Battery', s.battery);
      a('OS', s.os);
      a('Ports', s.ports);
      a('Weight', s.weight);
  }
  return out;
}

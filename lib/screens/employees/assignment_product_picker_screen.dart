import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';

/// Single-product picker for employee assignments.
class AssignmentProductPickerScreen extends StatefulWidget {
  const AssignmentProductPickerScreen({super.key, this.selectedProductId});

  final String? selectedProductId;

  @override
  State<AssignmentProductPickerScreen> createState() =>
      _AssignmentProductPickerScreenState();
}

class _AssignmentProductPickerScreenState
    extends State<AssignmentProductPickerScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
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
          ProductType.label(p.productType).toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final filtered = _filtered(productProvider.products);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Select Product'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
            ),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _typeFilter == null,
                  onSelected: (_) => setState(() => _typeFilter = null),
                ),
                const SizedBox(width: 8),
                ...ProductType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(ProductType.label(type)),
                      selected: _typeFilter == type,
                      onSelected: (_) => setState(() => _typeFilter = type),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Expanded(
            child: productProvider.isLoading && productProvider.products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No products found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppDimensions.paddingL),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          final selected =
                              product.id == widget.selectedProductId;
                          final imageUrl = product.images.isNotEmpty
                              ? product.images.first
                              : null;

                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: AppDimensions.paddingM,
                            ),
                            color: selected
                                ? AppColors.primaryColor.withValues(alpha: 0.15)
                                : null,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(
                                AppDimensions.paddingM,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: imageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              const Icon(Icons.laptop),
                                        )
                                      : Container(
                                          color: AppColors.cardColor,
                                          child: const Icon(Icons.laptop),
                                        ),
                                ),
                              ),
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${product.brandName} · ${ProductType.label(product.productType)}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              trailing: selected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primaryColor,
                                    )
                                  : const Icon(
                                      Icons.chevron_right,
                                      color: AppColors.textMuted,
                                    ),
                              onTap: () => Navigator.pop(context, product),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

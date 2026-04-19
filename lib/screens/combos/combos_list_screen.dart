import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../models/combo_model.dart';
import '../../providers/combo_provider.dart';
import 'combo_detail_screen.dart';
import 'combo_editor_screen.dart';

/// Admin list of product combos.
class CombosListScreen extends StatefulWidget {
  const CombosListScreen({super.key});

  @override
  State<CombosListScreen> createState() => _CombosListScreenState();
}

class _CombosListScreenState extends State<CombosListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComboProvider>().fetchCombos();
    });
  }

  List<ProductComboModel> _filtered(List<ProductComboModel> combos) {
    if (_searchQuery.isEmpty) return combos;
    final q = _searchQuery.toLowerCase();
    return combos.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.slug.toLowerCase().contains(q) ||
          c.components.any(
            (x) => (x.productNameSnapshot ?? '').toLowerCase().contains(q),
          );
    }).toList();
  }

  Future<void> _handleAction(String value, ProductComboModel combo) async {
    final provider = context.read<ComboProvider>();
    switch (value) {
      case 'edit':
        if (!mounted) return;
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => ComboEditorScreen(existing: combo),
          ),
        );
        break;
      case 'activate':
      case 'deactivate':
        final ok = await provider.toggleComboActive(
          combo.id,
          value == 'activate',
        );
        if (mounted && !ok && provider.error != null) {
          Fluttertoast.showToast(msg: provider.error!);
        }
        break;
      case 'feature':
      case 'unfeature':
        final ok = await provider.toggleComboFeatured(
          combo.id,
          value == 'feature',
        );
        if (mounted && !ok && provider.error != null) {
          Fluttertoast.showToast(msg: provider.error!);
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete combo'),
            content: Text('Delete "${combo.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorColor,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true && mounted) {
          final ok = await provider.deleteCombo(combo.id, combo.images);
          if (mounted) {
            if (ok) {
              Fluttertoast.showToast(msg: 'Combo deleted');
            } else if (provider.error != null) {
              Fluttertoast.showToast(msg: provider.error!);
            }
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product combos',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Consumer<ComboProvider>(
                        builder: (context, provider, _) => Text(
                          '${provider.combos.length} combos total',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ComboEditorScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New combo'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search combos…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: Consumer<ComboProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.combos.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && provider.combos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: AppColors.errorColor),
                        const SizedBox(height: AppDimensions.paddingM),
                        Text(provider.error!),
                        const SizedBox(height: AppDimensions.paddingM),
                        ElevatedButton(
                          onPressed: () => provider.fetchCombos(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filtered = _filtered(provider.combos);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.layers_outlined,
                            size: 64, color: AppColors.textMuted),
                        const SizedBox(height: AppDimensions.paddingM),
                        Text(
                          provider.combos.isEmpty
                              ? 'No combos yet — bundle laptops, monitors, phones, and more.'
                              : 'No combos match your search',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchCombos(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final combo = filtered[index];
                      return _ComboCard(
                        combo: combo,
                        onOpenDetail: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ComboDetailScreen(combo: combo),
                            ),
                          );
                        },
                        onAction: (v) => _handleAction(v, combo),
                      );
                    },
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

class _ComboCard extends StatelessWidget {
  const _ComboCard({
    required this.combo,
    required this.onOpenDetail,
    required this.onAction,
  });

  final ProductComboModel combo;
  final VoidCallback onOpenDetail;
  final void Function(String) onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: InkWell(
        onTap: onOpenDetail,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                child: combo.images.isNotEmpty
                    ? Image.network(
                        combo.mainImage,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.surfaceColor,
                          child: const Icon(Icons.layers_outlined,
                              color: AppColors.textMuted),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppColors.surfaceColor,
                        child: const Icon(Icons.layers_outlined,
                            color: AppColors.textMuted),
                      ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusS),
                          ),
                          child: const Text(
                            'COMBO',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!combo.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusS),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(
                                color: AppColors.errorColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (combo.isFeatured) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.star,
                              size: 16, color: AppColors.primaryColor),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      combo.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${combo.components.length} products · ₹${combo.price.toStringAsFixed(0)} · Stock ${combo.stock}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: onAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: combo.isActive ? 'deactivate' : 'activate',
                    child: Row(
                      children: [
                        Icon(
                          combo.isActive
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(combo.isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: combo.isFeatured ? 'unfeature' : 'feature',
                    child: Row(
                      children: [
                        Icon(
                          combo.isFeatured ? Icons.star : Icons.star_border,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(combo.isFeatured ? 'Unfeature' : 'Feature'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppColors.errorColor),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: AppColors.errorColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

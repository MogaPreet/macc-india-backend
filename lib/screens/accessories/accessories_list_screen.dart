import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/accessory_provider.dart';
import '../../models/accessory_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import 'add_accessory_screen.dart';
import 'edit_accessory_screen.dart';

/// Screen for listing all accessories
class AccessoriesListScreen extends StatefulWidget {
  const AccessoriesListScreen({super.key});

  @override
  State<AccessoriesListScreen> createState() => _AccessoriesListScreenState();
}

class _AccessoriesListScreenState extends State<AccessoriesListScreen> {
  String _searchQuery = '';
  String? _filterType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccessoryProvider>().fetchAccessories();
    });
  }

  List<AccessoryModel> _filteredAccessories(List<AccessoryModel> accessories) {
    return accessories.where((accessory) {
      final matchesSearch = _searchQuery.isEmpty ||
          accessory.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          accessory.brandName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          AccessoryTypeValues.label(accessory.accessoryType)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesType =
          _filterType == null || accessory.accessoryType == _filterType;

      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
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
                        'Accessories',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Consumer<AccessoryProvider>(
                        builder: (context, provider, _) => Text(
                          '${provider.accessories.length} accessories total',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddAccessoryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Accessory'),
                ),
              ],
            ),
          ),

          // Search and Filter Row
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search accessories...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                // Type filter dropdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _filterType,
                      hint: const Text('All Types'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Types'),
                        ),
                        ...AccessoryTypeValues.values.map((type) {
                          return DropdownMenuItem<String?>(
                            value: type,
                            child: Text(
                              '${AccessoryTypeValues.icon(type)} ${AccessoryTypeValues.label(type)}',
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterType = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Accessories List
          Expanded(
            child: Consumer<AccessoryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.accessories.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && provider.accessories.isEmpty) {
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
                          onPressed: () => provider.fetchAccessories(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filtered = _filteredAccessories(provider.accessories);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard_outlined,
                            size: 64, color: AppColors.textMuted),
                        const SizedBox(height: AppDimensions.paddingM),
                        Text(
                          provider.accessories.isEmpty
                              ? 'No accessories yet'
                              : 'No accessories match your filters',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchAccessories(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final accessory = filtered[index];
                      return _buildAccessoryCard(context, accessory);
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

  Widget _buildAccessoryCard(BuildContext context, AccessoryModel accessory) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditAccessoryScreen(accessory: accessory),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                child: accessory.images.isNotEmpty
                    ? Image.network(
                        accessory.mainImage,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.surfaceColor,
                          child: const Icon(Icons.image_not_supported,
                              color: AppColors.textMuted),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppColors.surfaceColor,
                        child: const Icon(Icons.keyboard,
                            color: AppColors.textMuted),
                      ),
              ),
              const SizedBox(width: AppDimensions.paddingM),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge + Name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusS),
                          ),
                          child: Text(
                            '${AccessoryTypeValues.icon(accessory.accessoryType)} ${AccessoryTypeValues.label(accessory.accessoryType)}',
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!accessory.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorColor.withOpacity(0.15),
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accessory.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${accessory.brandName} • ₹${accessory.price.toStringAsFixed(0)} • Stock: ${accessory.stock}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                onSelected: (value) => _handleAction(value, accessory),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: const [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: accessory.isActive ? 'deactivate' : 'activate',
                    child: Row(
                      children: [
                        Icon(
                          accessory.isActive
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(accessory.isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: accessory.isFeatured ? 'unfeature' : 'feature',
                    child: Row(
                      children: [
                        Icon(
                          accessory.isFeatured ? Icons.star : Icons.star_border,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(accessory.isFeatured ? 'Unfeature' : 'Feature'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: const [
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

  void _handleAction(String action, AccessoryModel accessory) async {
    final provider = context.read<AccessoryProvider>();

    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditAccessoryScreen(accessory: accessory),
          ),
        );
        break;
      case 'activate':
      case 'deactivate':
        final success = await provider.toggleAccessoryActive(
          accessory.id,
          action == 'activate',
        );
        if (mounted) {
          Fluttertoast.showToast(
            msg: success
                ? 'Accessory ${action == "activate" ? "activated" : "deactivated"}'
                : provider.error ?? 'Failed to update',
            backgroundColor:
                success ? AppColors.successColor : AppColors.errorColor,
          );
        }
        break;
      case 'feature':
      case 'unfeature':
        final success = await provider.toggleAccessoryFeatured(
          accessory.id,
          action == 'feature',
        );
        if (mounted) {
          Fluttertoast.showToast(
            msg: success
                ? 'Accessory ${action == "feature" ? "featured" : "unfeatured"}'
                : provider.error ?? 'Failed to update',
            backgroundColor:
                success ? AppColors.successColor : AppColors.errorColor,
          );
        }
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Accessory'),
            content: Text('Delete "${accessory.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorColor,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          final success =
              await provider.deleteAccessory(accessory.id, accessory.images);
          if (mounted) {
            Fluttertoast.showToast(
              msg: success ? 'Accessory deleted' : provider.error ?? 'Failed',
              backgroundColor:
                  success ? AppColors.successColor : AppColors.errorColor,
            );
          }
        }
        break;
    }
  }
}

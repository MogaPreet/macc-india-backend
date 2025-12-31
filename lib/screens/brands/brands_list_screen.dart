import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/brand_provider.dart';
import '../../models/brand_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import 'add_brand_screen.dart';
import 'edit_brand_screen.dart';

/// Screen showing list of all brands
class BrandsListScreen extends StatefulWidget {
  const BrandsListScreen({super.key});

  @override
  State<BrandsListScreen> createState() => _BrandsListScreenState();
}

class _BrandsListScreenState extends State<BrandsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandProvider>().fetchBrands();
    });
  }

  Future<void> _deleteBrand(BrandModel brand) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Brand'),
        content: Text('Are you sure you want to delete "${brand.name}"?'),
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

    if (confirmed == true && mounted) {
      final provider = context.read<BrandProvider>();
      final success = await provider.deleteBrand(brand.id, brand.logo);

      if (success) {
        Fluttertoast.showToast(
          msg: 'Brand deleted successfully',
          backgroundColor: AppColors.successColor,
        );
      } else {
        Fluttertoast.showToast(
          msg: provider.error ?? 'Failed to delete brand',
          backgroundColor: AppColors.errorColor,
        );
      }
    }
  }

  Future<void> _toggleActive(BrandModel brand) async {
    final provider = context.read<BrandProvider>();
    final success = await provider.toggleBrandActive(brand.id, !brand.isActive);

    if (success) {
      Fluttertoast.showToast(
        msg: brand.isActive ? 'Brand deactivated' : 'Brand activated',
        backgroundColor: AppColors.successColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brands Management'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<BrandProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.brands.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.brands.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    'No brands yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    'Add your first brand to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 1.0,
              crossAxisSpacing: AppDimensions.paddingL,
              mainAxisSpacing: AppDimensions.paddingL,
            ),
            itemCount: provider.brands.length,
            itemBuilder: (context, index) {
              final brand = provider.brands[index];
              return _buildBrandCard(brand);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBrandScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Brand'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildBrandCard(BrandModel brand) {
    // Parse color from hex string
    Color? brandColor;
    if (brand.color != null && brand.color!.isNotEmpty) {
      try {
        final hexColor = brand.color!.replaceAll('#', '');
        brandColor = Color(int.parse('FF$hexColor', radix: 16));
      } catch (_) {}
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand Logo
              AspectRatio(
                aspectRatio: 1.5,
                child: Container(
                  color:
                      brandColor?.withValues(alpha: 0.1) ??
                      Colors.white.withValues(alpha: 0.05),
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: brand.logo != null && brand.logo!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: brand.logo!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              _buildLogoPlaceholder(brand.name, brandColor),
                        )
                      : _buildLogoPlaceholder(brand.name, brandColor),
                ),
              ),

              // Brand Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (brandColor != null) ...[
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: brandColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              brand.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditBrandScreen(brand: brand),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppDimensions.paddingS,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _deleteBrand(brand),
                            icon: const Icon(Icons.delete_outline),
                            color: AppColors.errorColor,
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Active/Inactive indicator
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _toggleActive(brand),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: brand.isActive
                      ? AppColors.successColor
                      : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  brand.isActive ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPlaceholder(String name, Color? brandColor) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: brandColor ?? AppColors.textMuted,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

/// Screen showing list of all products
class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    if (_searchQuery.isEmpty) {
      return products;
    }
    return products.where((product) {
      // Search by name
      if (product.name.toLowerCase().contains(_searchQuery)) {
        return true;
      }
      // Search by brand
      if (product.brandName.toLowerCase().contains(_searchQuery)) {
        return true;
      }
      // Search by processor
      if (product.specs.processor?.toLowerCase().contains(_searchQuery) ??
          false) {
        return true;
      }
      // Search by RAM
      if (product.specs.ram?.toLowerCase().contains(_searchQuery) ?? false) {
        return true;
      }
      // Search by storage
      if (product.specs.storage?.toLowerCase().contains(_searchQuery) ??
          false) {
        return true;
      }
      return false;
    }).toList();
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
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
      final provider = context.read<ProductProvider>();
      final success = await provider.deleteProduct(product.id, product.images);

      if (success) {
        Fluttertoast.showToast(
          msg: 'Product deleted successfully',
          backgroundColor: AppColors.successColor,
        );
      } else {
        Fluttertoast.showToast(
          msg: provider.error ?? 'Failed to delete product',
          backgroundColor: AppColors.errorColor,
        );
      }
    }
  }

  Future<void> _toggleActive(ProductModel product) async {
    final provider = context.read<ProductProvider>();
    final success = await provider.toggleProductActive(
      product.id,
      !product.isActive,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: product.isActive ? 'Product deactivated' : 'Product activated',
        backgroundColor: AppColors.successColor,
      );
    }
  }

  Future<void> _toggleFeatured(ProductModel product) async {
    final provider = context.read<ProductProvider>();
    final success = await provider.toggleProductFeatured(
      product.id,
      !product.isFeatured,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: product.isFeatured ? 'Removed from featured' : 'Added to featured',
        backgroundColor: AppColors.successColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by name, brand, processor, RAM...',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              )
            : const Text('Products Management'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                }
              });
            },
            tooltip: _isSearchVisible ? 'Close Search' : 'Search Products',
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.errorColor,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    'Error loading products',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchProducts(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    'No products yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    'Add your first product to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final filteredProducts = _filterProducts(provider.products);

          if (filteredProducts.isEmpty && _searchQuery.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    'No products found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    'Try a different search term',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.paddingM,
                    ),
                    child: Text(
                      'Found ${filteredProducts.length} product${filteredProducts.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: AppDimensions.paddingL,
                    mainAxisSpacing: AppDimensions.paddingL,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(product);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              AspectRatio(
                aspectRatio: 1.3,
                child: CachedNetworkImage(
                  imageUrl: product.mainImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.surfaceColor,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surfaceColor,
                    child: const Icon(
                      Icons.error,
                      size: 48,
                      color: AppColors.errorColor,
                    ),
                  ),
                ),
              ),

              // Product Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            product.brandName,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          Text(
                            product.condition,
                            style: TextStyle(
                              color: _getConditionColor(product.condition),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingS),
                      Row(
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: 8),
                            Text(
                              '₹${product.originalPrice?.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${product.discountPercentage}% off',
                              style: const TextStyle(
                                color: AppColors.successColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stock: ${product.stock}',
                        style: TextStyle(
                          color: product.inStock
                              ? AppColors.textSecondary
                              : AppColors.errorColor,
                          fontSize: 11,
                        ),
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
                                        EditProductScreen(product: product),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit, size: 14),
                              label: const Text(
                                'Edit',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddProductScreen(duplicateFrom: product),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_outlined, size: 20),
                            color: AppColors.primaryColor,
                            tooltip: 'Duplicate Product',
                          ),
                          IconButton(
                            onPressed: () => _toggleFeatured(product),
                            icon: Icon(
                              product.isFeatured
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 20,
                            ),
                            color: product.isFeatured
                                ? Colors.amber
                                : AppColors.textMuted,
                            tooltip: product.isFeatured
                                ? 'Remove from featured'
                                : 'Add to featured',
                          ),
                          IconButton(
                            onPressed: () => _deleteProduct(product),
                            icon: const Icon(Icons.delete_outline, size: 20),
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

          // Status badges
          Positioned(
            top: 8,
            left: 8,
            child: Row(
              children: [
                if (product.isFeatured)
                  _buildBadge('FEATURED', Colors.amber.shade700),
                if (!product.inStock)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _buildBadge('OUT OF STOCK', AppColors.errorColor),
                  ),
              ],
            ),
          ),

          // Active/Inactive indicator
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _toggleActive(product),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.isActive
                      ? AppColors.successColor
                      : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product.isActive ? 'Active' : 'Inactive',
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingS,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'Like New':
        return AppColors.successColor;
      case 'Excellent':
        return Colors.teal;
      case 'Good':
        return Colors.amber.shade700;
      case 'Fair':
        return Colors.orange;
      default:
        return AppColors.textMuted;
    }
  }
}

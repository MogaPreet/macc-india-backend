import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../providers/product_provider.dart';

/// Home/Dashboard tab showing overview with real-time data
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    // Fetch products on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            'Welcome to MACC INDIA Admin Portal',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.paddingXL),

          // Quick Stats Cards with Real Data
          Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              final products = productProvider.products;
              final totalProducts = products.length;
              final featuredCount = products.where((p) => p.isFeatured).length;
              final outOfStock = products.where((p) => !p.inStock).length;
              final activeCount = products.where((p) => p.isActive).length;

              return GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppDimensions.paddingL,
                mainAxisSpacing: AppDimensions.paddingL,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    icon: Icons.inventory_2,
                    title: 'Total Products',
                    value: totalProducts.toString(),
                    color: AppColors.primaryColor,
                  ),
                  _buildStatCard(
                    icon: Icons.star,
                    title: 'Featured',
                    value: featuredCount.toString(),
                    color: Colors.amber.shade700,
                  ),
                  _buildStatCard(
                    icon: Icons.check_circle_outline,
                    title: 'Active',
                    value: activeCount.toString(),
                    color: AppColors.successColor,
                  ),
                  _buildStatCard(
                    icon: Icons.remove_shopping_cart,
                    title: 'Out of Stock',
                    value: outOfStock.toString(),
                    color: AppColors.errorColor,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppDimensions.paddingXL),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),
          Wrap(
            spacing: AppDimensions.paddingM,
            runSpacing: AppDimensions.paddingM,
            children: [
              _buildActionButton(
                icon: Icons.add_box,
                label: 'Add Product',
                onTap: () {
                  // Navigate to products section
                  // The parent dashboard will handle this
                },
              ),
              _buildActionButton(
                icon: Icons.upload,
                label: 'Upload Banner',
                onTap: () {
                  // Will navigate to banner upload
                },
              ),
              _buildActionButton(
                icon: Icons.people,
                label: 'View Leads',
                onTap: () {
                  // Will navigate to leads
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingL,
          vertical: AppDimensions.paddingM,
        ),
      ),
    );
  }
}

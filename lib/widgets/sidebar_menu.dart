import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

/// Sidebar menu for navigation
class SidebarMenu extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;
  final VoidCallback onLogout;

  const SidebarMenu({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.sidebarWidth,
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.dividerColor)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.laptop_mac,
                  color: AppColors.primaryColor,
                  size: AppDimensions.iconL,
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MACC INDIA',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Admin Portal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingM,
              ),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                  route: 'home',
                ),
                _buildMenuItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  label: 'Products',
                  route: 'products',
                ),
                _buildMenuItem(
                  icon: Icons.business_outlined,
                  activeIcon: Icons.business,
                  label: 'Brands',
                  route: 'brands',
                ),
                _buildMenuItem(
                  icon: Icons.category_outlined,
                  activeIcon: Icons.category,
                  label: 'Categories',
                  route: 'categories',
                ),
                _buildMenuItem(
                  icon: Icons.inbox_outlined,
                  activeIcon: Icons.inbox,
                  label: 'Product Requests',
                  route: 'product_requests',
                ),
                _buildMenuItem(
                  icon: Icons.mail_outlined,
                  activeIcon: Icons.mail,
                  label: 'Contact Requests',
                  route: 'contact_requests',
                ),
                _buildMenuItem(
                  icon: Icons.local_offer_outlined,
                  activeIcon: Icons.local_offer,
                  label: 'Promo Offers',
                  route: 'promo_offers',
                ),
                _buildMenuItem(
                  icon: Icons.people_outlined,
                  activeIcon: Icons.people,
                  label: 'Leads',
                  route: 'leads',
                ),
              ],
            ),
          ),

          // Logout Button
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.dividerColor)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.errorColor),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: onLogout,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              hoverColor: AppColors.errorColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
  }) {
    final isActive = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      child: ListTile(
        leading: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? AppColors.primaryColor : AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primaryColor : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isActive,
        selectedTileColor: AppColors.primaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        onTap: () => onNavigate(route),
      ),
    );
  }
}

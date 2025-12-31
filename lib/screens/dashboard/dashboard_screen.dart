import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/sidebar_menu.dart';
import '../../core/constants/colors.dart';
import '../products/products_list_screen.dart';
import '../brands/brands_list_screen.dart';
import '../categories/categories_list_screen.dart';
import '../product_requests/product_requests_list_screen.dart';
import '../contact_requests/contact_requests_list_screen.dart';
import '../promo_offers/promo_offers_list_screen.dart';
import 'home_tab.dart';

/// Main dashboard screen with sidebar navigation
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentRoute = 'home';

  Widget _getCurrentScreen() {
    switch (_currentRoute) {
      case 'home':
        return const HomeTab();
      case 'products':
        return const ProductsListScreen();
      case 'brands':
        return const BrandsListScreen();
      case 'categories':
        return const CategoriesListScreen();
      case 'product_requests':
        return const ProductRequestsListScreen();
      case 'contact_requests':
        return const ContactRequestsListScreen();
      case 'promo_offers':
        return const PromoOffersListScreen();
      case 'leads':
        return const Center(
          child: Text(
            'Leads CRM (Coming Soon)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
          ),
        );
      default:
        return const HomeTab();
    }
  }

  void _handleNavigation(String route) {
    setState(() {
      _currentRoute = route;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          SidebarMenu(
            currentRoute: _currentRoute,
            onNavigate: _handleNavigation,
            onLogout: _handleLogout,
          ),

          // Main Content Area
          Expanded(
            child: Container(
              color: AppColors.backgroundColor,
              child: _getCurrentScreen(),
            ),
          ),
        ],
      ),
    );
  }
}

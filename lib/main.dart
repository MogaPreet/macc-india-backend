import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:macc_india_new/firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/brand_provider.dart';
import 'providers/category_provider.dart';
import 'providers/product_request_provider.dart';
import 'providers/contact_request_provider.dart';
import 'providers/promo_offer_provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // NOTE: You need to add your Firebase configuration files:
  // - For Web: Update web/index.html with Firebase config
  // - For Android: Add google-services.json to android/app/
  // - For iOS: Add GoogleService-Info.plist to ios/Runner/
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const MaccIndiaAdminApp());
}

class MaccIndiaAdminApp extends StatelessWidget {
  const MaccIndiaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => BrandProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductRequestProvider()),
        ChangeNotifierProvider(create: (_) => ContactRequestProvider()),
        ChangeNotifierProvider(create: (_) => PromoOfferProvider()),
        // Add more providers here as needed (LeadsProvider, etc.)
      ],
      child: MaterialApp(
        title: 'MACC INDIA Admin Portal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: AuthWrapper(),
      ),
    );
  }
}

/// Wrapper to handle authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show login screen if not authenticated
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Show dashboard if authenticated
        return const DashboardScreen();
      },
    );
  }
}

/// Firebase collection names and storage paths
class FirebaseConstants {
  // Firestore  // Collection names
  static const String productsCollection = 'products';
  static const String bannersCollection = 'banners';
  static const String leadsCollection = 'leads';
  static const String brandsCollection = 'brands';
  static const String categoriesCollection = 'categories';
  static const String settingsCollection = 'settings';
  static const String adminUsersCollection = 'admin_users';
  static const String productRequestsCollection = 'productRequests';
  static const String contactRequestsCollection = 'contactRequests';
  static const String promoOffersCollection = 'promoOffers';
  static const String accessoriesCollection = 'accessories';
  static const String combosCollection = 'combos';
  static const String blogsCollection = 'blogs';
  static const String employeesCollection = 'employees';
  static const String employeeAssignmentsCollection = 'employeeAssignments';

  // Settings Documents
  static const String tickerSettingsDoc = 'ticker';

  // Storage Paths
  static const String productImagesPath = 'products';
  static const String bannerImagesPath = 'banners';
  static const String brandImagesPath = 'brands/images';
  static const String categoryImagesPath = 'categories/images';
  static const String promoImagesPath = 'promos';
  static const String accessoryImagesPath = 'accessories';
  static const String comboImagesPath = 'combos';
  static const String blogImagesPath = 'blogs/images';

  // Authorized Admin Emails (TODO: Move to Firestore or environment config)
  static const List<String> authorizedAdminEmails = [
    'admin@maccindia.com',
    'superadmin@maccindia.com',
    // Add more authorized emails here
  ];
}

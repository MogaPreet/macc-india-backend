import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_html/html.dart' as html;
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
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
  String? _selectedTypeFilter;

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
    var filtered = products;

    // Filter by product type
    if (_selectedTypeFilter != null) {
      filtered = filtered
          .where((p) => p.productType == _selectedTypeFilter)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        if (product.name.toLowerCase().contains(_searchQuery)) return true;
        if (product.brandName.toLowerCase().contains(_searchQuery)) return true;
        if (product.specs.processor?.toLowerCase().contains(_searchQuery) ??
            false)
          return true;
        if (product.specs.ram?.toLowerCase().contains(_searchQuery) ?? false)
          return true;
        if (product.specs.storage?.toLowerCase().contains(_searchQuery) ??
            false)
          return true;
        return false;
      }).toList();
    }

    return filtered;
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

  /// Show export options dialog
  Future<void> _showExportDialog() async {
    final categoryProvider = context.read<CategoryProvider>();

    // Fetch categories if not already loaded
    if (categoryProvider.categories.isEmpty) {
      await categoryProvider.fetchCategories();
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => _ExportDialog(
        categories: categoryProvider.categories,
        onExport: (String? categoryId) => _exportProducts(categoryId),
      ),
    );
  }

  /// Export products to Excel
  Future<void> _exportProducts(String? categoryId) async {
    final provider = context.read<ProductProvider>();

    // Get products based on category filter
    List<ProductModel> productsToExport;
    String categoryName = 'All';

    if (categoryId == null) {
      // Export all products
      productsToExport = provider.products;
    } else {
      // Export products of selected category
      productsToExport = provider.products
          .where((p) => p.categoryIds.contains(categoryId))
          .toList();

      // Get category name for filename
      final categoryProvider = context.read<CategoryProvider>();
      final category = categoryProvider.categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => CategoryModel(
          id: '',
          name: 'Unknown',
          slug: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      categoryName = category.name;
    }

    if (productsToExport.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No products to export',
        backgroundColor: AppColors.warningColor,
      );
      return;
    }

    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Create Excel workbook
      final excel = xl.Excel.createExcel();
      final sheetName = 'Products';
      final sheet = excel[sheetName];

      // Remove default sheet if exists
      if (excel.getDefaultSheet() != sheetName) {
        excel.delete(excel.getDefaultSheet()!);
      }

      // Header style
      final headerStyle = xl.CellStyle(
        bold: true,
        backgroundColorHex: xl.ExcelColor.fromHexString('#4CAF50'),
        fontColorHex: xl.ExcelColor.white,
        horizontalAlign: xl.HorizontalAlign.Center,
      );

      // Add headers
      final headers = [
        'S.No',
        'Name',
        'Brand',
        'Categories',
        'Condition',
        'Price (₹)',
        'Original Price (₹)',
        'Discount %',
        'Stock',
        'Status',
        'Featured',
        'Processor',
        'RAM',
        'Storage',
        'Screen',
        'Graphics',
        'Battery',
        'OS',
        'Warranty',
        'Main Image URL',
        'Created At',
      ];

      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = xl.TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Add product data
      for (var rowIndex = 0; rowIndex < productsToExport.length; rowIndex++) {
        final product = productsToExport[rowIndex];
        final row = rowIndex + 1;

        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = xl.IntCellValue(
          rowIndex + 1,
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = xl.TextCellValue(
          product.name,
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = xl.TextCellValue(
          product.brandName,
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = xl.TextCellValue(
          product.categoryNames.join(', '),
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = xl.TextCellValue(
          product.condition,
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = xl.DoubleCellValue(
          product.price,
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = xl.DoubleCellValue(
          product.originalPrice ?? 0,
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
            .value = xl.IntCellValue(
          product.discountPercentage,
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
            .value = xl.IntCellValue(
          product.stock,
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row))
            .value = xl.TextCellValue(
          product.isActive ? 'Active' : 'Inactive',
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row))
            .value = xl.TextCellValue(
          product.isFeatured ? 'Yes' : 'No',
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row))
            .value = xl.TextCellValue(
          product.specs.processor ?? '',
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row))
            .value = xl.TextCellValue(
          product.specs.ram ?? '',
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row))
            .value = xl.TextCellValue(
          product.specs.storage ?? '',
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: row))
            .value = xl.TextCellValue(
          product.specs.screen ?? '',
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: row))
            .value = xl.TextCellValue(
          product.specs.graphics ?? '',
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: row))
            .value = xl.TextCellValue(
          product.specs.battery ?? '',
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: row))
            .value = xl.TextCellValue(
          product.specs.os ?? '',
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: row))
            .value = xl.TextCellValue(
          product.warranty?.duration ?? '',
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 19, rowIndex: row))
            .value = xl.TextCellValue(
          product.mainImage,
        );
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 20, rowIndex: row))
            .value = xl.TextCellValue(
          product.createdAt.toString().split(' ')[0],
        );
      }

      // Auto-fit column widths (approximate)
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }
      sheet.setColumnWidth(1, 40); // Name column wider
      sheet.setColumnWidth(19, 50); // URL column wider

      // Save file
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to encode Excel file');

      final sanitizedCategoryName = categoryName.replaceAll(
        RegExp(r'[^\w\s-]'),
        '',
      );
      final fileName =
          'Products_${sanitizedCategoryName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      if (kIsWeb) {
        // Web: Use browser download
        final blob = html.Blob([
          bytes,
        ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final _ = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Native: Save to file system
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        // Open the file
        await OpenFilex.open(filePath);
      }

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success message
      Fluttertoast.showToast(
        msg: 'Exported ${productsToExport.length} products to Excel',
        backgroundColor: AppColors.successColor,
      );
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      Fluttertoast.showToast(
        msg: 'Export failed: $e',
        backgroundColor: AppColors.errorColor,
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
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _showExportDialog,
            tooltip: 'Export Products',
          ),
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
                if (_searchQuery.isNotEmpty || _selectedTypeFilter != null)
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

                // Product type filter chips
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.paddingM,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTypeFilterChip('All', null),
                        const SizedBox(width: 8),
                        _buildTypeFilterChip('Laptop', ProductType.laptop),
                        const SizedBox(width: 8),
                        _buildTypeFilterChip('System', ProductType.system),
                        const SizedBox(width: 8),
                        _buildTypeFilterChip('Monitor', ProductType.monitor),
                      ],
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
                _buildBadge(
                  ProductType.label(product.productType).toUpperCase(),
                  product.productType == ProductType.monitor
                      ? Colors.deepPurple
                      : product.productType == ProductType.system
                      ? Colors.teal
                      : AppColors.primaryColor,
                ),
                if (product.isFeatured)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _buildBadge('FEATURED', Colors.amber.shade700),
                  ),
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

  Widget _buildTypeFilterChip(String label, String? type) {
    final isSelected = _selectedTypeFilter == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedTypeFilter = type;
        });
      },
      selectedColor: AppColors.primaryColor.withOpacity(0.2),
      checkmarkColor: AppColors.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryColor : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
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

/// Export dialog for selecting category filter
class _ExportDialog extends StatefulWidget {
  final List<CategoryModel> categories;
  final Function(String?) onExport;

  const _ExportDialog({required this.categories, required this.onExport});

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.file_download_outlined, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          const Text('Export Products'),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select category to export:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // All Products Option
            _buildExportOption(
              title: 'All Products',
              subtitle: 'Export all products from all categories',
              icon: Icons.all_inclusive,
              isSelected: _selectedCategoryId == null,
              onTap: () {
                setState(() {
                  _selectedCategoryId = null;
                });
              },
            ),

            const Divider(height: 24),

            // Category Options
            Text(
              'Or select a specific category:',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: Column(
                  children: widget.categories.map((category) {
                    return _buildExportOption(
                      title: category.name,
                      subtitle: category.isActive ? 'Active' : 'Inactive',
                      icon: Icons.category_outlined,
                      isSelected: _selectedCategoryId == category.id,
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = category.id;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            widget.onExport(_selectedCategoryId);
          },
          icon: const Icon(Icons.file_download, size: 18),
          label: const Text('Export'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildExportOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryColor : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}

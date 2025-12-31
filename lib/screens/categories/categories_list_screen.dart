import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';

/// Screen showing list of all categories
class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
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
      final provider = context.read<CategoryProvider>();
      final success = await provider.deleteCategory(
        category.id,
        category.image,
      );

      if (success) {
        Fluttertoast.showToast(
          msg: 'Category deleted successfully',
          backgroundColor: AppColors.successColor,
        );
      } else {
        Fluttertoast.showToast(
          msg: provider.error ?? 'Failed to delete category',
          backgroundColor: AppColors.errorColor,
        );
      }
    }
  }

  Future<void> _toggleActive(CategoryModel category) async {
    final provider = context.read<CategoryProvider>();
    final success = await provider.toggleCategoryActive(
      category.id,
      !category.isActive,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: category.isActive ? 'Category deactivated' : 'Category activated',
        backgroundColor: AppColors.successColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories Management'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    'No categories yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    'Add your first category to get started',
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
              childAspectRatio: 0.85,
              crossAxisSpacing: AppDimensions.paddingL,
              mainAxisSpacing: AppDimensions.paddingL,
            ),
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              return _buildCategoryCard(category);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCategoryScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    // Parse color from hex string
    Color? categoryColor;
    if (category.color != null && category.color!.isNotEmpty) {
      try {
        final hexColor = category.color!.replaceAll('#', '');
        categoryColor = Color(int.parse('FF$hexColor', radix: 16));
      } catch (_) {}
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Image or Icon
              AspectRatio(
                aspectRatio: 1.5,
                child: Container(
                  color:
                      categoryColor?.withValues(alpha: 0.1) ??
                      Colors.white.withValues(alpha: 0.05),
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: category.image != null && category.image!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: category.image!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              _buildIconOrPlaceholder(category, categoryColor),
                        )
                      : _buildIconOrPlaceholder(category, categoryColor),
                ),
              ),

              // Category Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (category.icon != null &&
                              category.icon!.isNotEmpty) ...[
                            Text(
                              category.icon!,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              category.name,
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
                      const SizedBox(height: 4),
                      Text(
                        '/${category.slug}',
                        style: TextStyle(
                          color: categoryColor ?? AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.order != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Order: ${category.order}',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
                                        EditCategoryScreen(category: category),
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
                            onPressed: () => _deleteCategory(category),
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
              onTap: () => _toggleActive(category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: category.isActive
                      ? AppColors.successColor
                      : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category.isActive ? 'Active' : 'Inactive',
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

  Widget _buildIconOrPlaceholder(CategoryModel category, Color? categoryColor) {
    if (category.icon != null && category.icon!.isNotEmpty) {
      return Center(
        child: Text(category.icon!, style: const TextStyle(fontSize: 48)),
      );
    }
    return Icon(
      Icons.category,
      size: 48,
      color: categoryColor ?? AppColors.textMuted,
    );
  }
}

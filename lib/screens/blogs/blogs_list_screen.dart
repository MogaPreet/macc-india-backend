import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/blog_provider.dart';
import '../../models/blog_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import 'add_blog_screen.dart';
import 'edit_blog_screen.dart';

/// Screen showing list of all blog posts
class BlogsListScreen extends StatefulWidget {
  const BlogsListScreen({super.key});

  @override
  State<BlogsListScreen> createState() => _BlogsListScreenState();
}

class _BlogsListScreenState extends State<BlogsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BlogProvider>().fetchBlogs();
    });
  }

  Future<void> _deleteBlog(BlogModel blog) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Blog Post'),
        content: Text('Are you sure you want to delete "${blog.title}"?'),
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
      final provider = context.read<BlogProvider>();
      final success = await provider.deleteBlog(blog.id, blog.coverImage);

      if (success) {
        Fluttertoast.showToast(
          msg: 'Blog post deleted successfully',
          backgroundColor: AppColors.successColor,
        );
      } else {
        Fluttertoast.showToast(
          msg: provider.error ?? 'Failed to delete blog post',
          backgroundColor: AppColors.errorColor,
        );
      }
    }
  }

  Future<void> _togglePublished(BlogModel blog) async {
    final provider = context.read<BlogProvider>();
    final success = await provider.togglePublished(
      blog.id,
      !blog.isPublished,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: blog.isPublished ? 'Blog unpublished' : 'Blog published',
        backgroundColor: AppColors.successColor,
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Management'),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddBlogScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Blog'),
          ),
          const SizedBox(width: AppDimensions.paddingM),
        ],
      ),
      body: Consumer<BlogProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.blogs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.blogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    'No blog posts yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    'Create SEO blog posts for search engines',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddBlogScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Blog'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchBlogs,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              itemCount: provider.blogs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.paddingM),
              itemBuilder: (context, index) {
                final blog = provider.blogs[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingL,
                      vertical: AppDimensions.paddingS,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: blog.isPublished
                          ? AppColors.successColor.withValues(alpha: 0.2)
                          : AppColors.textMuted.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.article,
                        color: blog.isPublished
                            ? AppColors.successColor
                            : AppColors.textMuted,
                      ),
                    ),
                    title: Text(
                      blog.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('/blog/${blog.slug}'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: blog.isPublished
                                    ? AppColors.successColor.withValues(alpha: 0.15)
                                    : AppColors.warningColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                blog.isPublished ? 'Published' : 'Draft',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: blog.isPublished
                                      ? AppColors.successColor
                                      : AppColors.warningColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Published: ${_formatDate(blog.publishedAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditBlogScreen(blog: blog),
                              ),
                            );
                            break;
                          case 'toggle':
                            _togglePublished(blog);
                            break;
                          case 'delete':
                            _deleteBlog(blog);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                blog.isPublished
                                    ? Icons.visibility_off
                                    : Icons.publish,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(blog.isPublished ? 'Unpublish' : 'Publish'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditBlogScreen(blog: blog),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

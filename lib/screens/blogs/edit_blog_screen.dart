import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/blog_provider.dart';
import '../../models/blog_model.dart';
import '../../widgets/image_uploader.dart';
import '../../widgets/product_description_codec.dart';
import '../../widgets/product_description_editor.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/utils/validators.dart';

/// Screen for editing an existing blog post
class EditBlogScreen extends StatefulWidget {
  final BlogModel blog;

  const EditBlogScreen({super.key, required this.blog});

  @override
  State<EditBlogScreen> createState() => _EditBlogScreenState();
}

class _EditBlogScreenState extends State<EditBlogScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _slugController;
  late final TextEditingController _excerptController;
  late final TextEditingController _metaTitleController;
  late final TextEditingController _metaDescriptionController;
  late final TextEditingController _keywordsController;
  late final QuillController _contentQuillController;
  late final FocusNode _contentFocusNode;
  late final ScrollController _contentScrollController;

  Uint8List? _newCoverImageBytes;
  late bool _isPublished;
  DateTime? _publishedAt;

  @override
  void initState() {
    super.initState();
    final blog = widget.blog;
    _titleController = TextEditingController(text: blog.title);
    _slugController = TextEditingController(text: blog.slug);
    _excerptController = TextEditingController(text: blog.excerpt);
    _metaTitleController = TextEditingController(text: blog.metaTitle ?? '');
    _metaDescriptionController =
        TextEditingController(text: blog.metaDescription ?? '');
    _keywordsController = TextEditingController(text: blog.keywords.join(', '));
    _contentQuillController = QuillController(
      document: ProductDescriptionCodec.documentFromStored(blog.content),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _contentFocusNode = FocusNode();
    _contentScrollController = ScrollController();
    _isPublished = blog.isPublished;
    _publishedAt = blog.publishedAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _excerptController.dispose();
    _metaTitleController.dispose();
    _metaDescriptionController.dispose();
    _keywordsController.dispose();
    _contentQuillController.dispose();
    _contentFocusNode.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  List<String> _parseKeywords() {
    return _keywordsController.text
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();
  }

  Future<void> _pickPublishedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _publishedAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _publishedAt = picked);
    }
  }

  Future<void> _saveBlog() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BlogProvider>();
    final success = await provider.updateBlog(
      blogId: widget.blog.id,
      title: _titleController.text.trim(),
      slug: _slugController.text.trim(),
      excerpt: _excerptController.text.trim(),
      content: ProductDescriptionCodec.serializeNullable(_contentQuillController),
      metaTitle: _metaTitleController.text.trim().isNotEmpty
          ? _metaTitleController.text.trim()
          : null,
      metaDescription: _metaDescriptionController.text.trim().isNotEmpty
          ? _metaDescriptionController.text.trim()
          : null,
      keywords: _parseKeywords(),
      newCoverImageFile: _newCoverImageBytes,
      existingCoverImageUrl: widget.blog.coverImage,
      isPublished: _isPublished,
      publishedAt: _publishedAt,
      existingPublishedAt: widget.blog.publishedAt,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: 'Blog post updated successfully!',
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
      );
      if (mounted) Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
        msg: provider.error ?? 'Failed to update blog post',
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Blog Post'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
          const SizedBox(width: AppDimensions.paddingM),
        ],
      ),
      body: Consumer<BlogProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: AppDimensions.maxContentWidth,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Cover Image'),
                          const SizedBox(height: AppDimensions.paddingM),
                          if (widget.blog.coverImage != null &&
                              _newCoverImageBytes == null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: widget.blog.coverImage!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: AppDimensions.paddingM),
                          ImageUploader(
                            onImageSelected: (bytes, fileName) {
                              setState(() => _newCoverImageBytes = bytes);
                            },
                            height: 180,
                          ),
                          const SizedBox(height: AppDimensions.paddingXL),

                          _buildSectionTitle('Post Information'),
                          const SizedBox(height: AppDimensions.paddingM),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title *',
                            ),
                            validator: (v) =>
                                Validators.required(v, fieldName: 'Title'),
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          TextFormField(
                            controller: _slugController,
                            decoration: const InputDecoration(
                              labelText: 'Slug *',
                              helperText: 'Used in URL: /blog/your-slug',
                            ),
                            validator: (v) =>
                                Validators.required(v, fieldName: 'Slug'),
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          TextFormField(
                            controller: _excerptController,
                            decoration: const InputDecoration(
                              labelText: 'Excerpt *',
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            validator: (v) =>
                                Validators.required(v, fieldName: 'Excerpt'),
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          ProductDescriptionEditor(
                            controller: _contentQuillController,
                            focusNode: _contentFocusNode,
                            scrollController: _contentScrollController,
                            label: 'Content',
                            hintText: 'Write blog content',
                            minHeight: 280,
                          ),
                          const SizedBox(height: AppDimensions.paddingXL),

                          _buildSectionTitle('SEO Settings'),
                          const SizedBox(height: AppDimensions.paddingM),
                          TextFormField(
                            controller: _metaTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Meta Title (optional)',
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          TextFormField(
                            controller: _metaDescriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Meta Description (optional)',
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          TextFormField(
                            controller: _keywordsController,
                            decoration: const InputDecoration(
                              labelText: 'Keywords (optional)',
                              helperText: 'Comma-separated keywords',
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingXL),

                          _buildSectionTitle('Publishing'),
                          const SizedBox(height: AppDimensions.paddingM),
                          SwitchListTile(
                            title: const Text('Published'),
                            subtitle: const Text(
                              'Only published posts appear on the website',
                            ),
                            value: _isPublished,
                            onChanged: (value) {
                              setState(() {
                                _isPublished = value;
                                if (value && _publishedAt == null) {
                                  _publishedAt = DateTime.now();
                                }
                              });
                            },
                          ),
                          if (_isPublished)
                            ListTile(
                              title: const Text('Published Date'),
                              subtitle: Text(
                                _publishedAt != null
                                    ? '${_publishedAt!.day}/${_publishedAt!.month}/${_publishedAt!.year}'
                                    : 'Not set',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: _pickPublishedDate,
                              ),
                            ),
                          const SizedBox(height: AppDimensions.paddingXL),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  provider.isLoading ? null : _saveBlog,
                              icon: const Icon(Icons.save),
                              label: const Text('Save Changes'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppDimensions.paddingM,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingXL),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (provider.isLoading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        if (provider.uploadProgress > 0) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Uploading: ${(provider.uploadProgress * 100).toInt()}%',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

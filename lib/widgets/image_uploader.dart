import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants/colors.dart';
import '../core/constants/dimensions.dart';

/// Reusable image uploader widget for web
class ImageUploader extends StatefulWidget {
  final Function(Uint8List?, String?) onImageSelected;
  final String? initialImageUrl;
  final double height;
  final double width;

  const ImageUploader({
    super.key,
    required this.onImageSelected,
    this.initialImageUrl,
    this.height = 200,
    this.width = double.infinity,
  });

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  Uint8List? _imageBytes;
  String? _fileName;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_imageBytes != null) {
      return _buildImagePreview();
    }

    if (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty) {
      return _buildNetworkImage();
    }

    return _buildPlaceholder();
  }

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
        ),
        Positioned(
          top: AppDimensions.paddingS,
          right: AppDimensions.paddingS,
          child: Row(
            children: [
              IconButton(
                onPressed: _pickImage,
                icon: const Icon(Icons.edit),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Change Image',
              ),
              const SizedBox(width: AppDimensions.paddingS),
              IconButton(
                onPressed: _clearImage,
                icon: const Icon(Icons.delete),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.errorColor,
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Remove Image',
              ),
            ],
          ),
        ),
        if (_fileName != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppDimensions.radiusL),
                  bottomRight: Radius.circular(AppDimensions.radiusL),
                ),
              ),
              child: Text(
                _fileName!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNetworkImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          child: Image.network(
            widget.initialImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          ),
        ),
        Positioned(
          top: AppDimensions.paddingS,
          right: AppDimensions.paddingS,
          child: IconButton(
            onPressed: _pickImage,
            icon: const Icon(Icons.edit),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            tooltip: 'Change Image',
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: AppDimensions.iconXL,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            'Click to upload image',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            'JPG, PNG (Max 5MB)',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size (5MB limit)
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size must be less than 5MB'),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
          return;
        }

        setState(() {
          _imageBytes = file.bytes;
          _fileName = file.name;
        });

        widget.onImageSelected(_imageBytes, _fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _fileName = null;
    });
    widget.onImageSelected(null, null);
  }
}

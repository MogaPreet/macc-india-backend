import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants/colors.dart';
import '../core/constants/dimensions.dart';

/// Reusable multi-image uploader widget for web
class MultiImageUploader extends StatefulWidget {
  final Function(List<Uint8List>, List<String>) onImagesChanged;
  final List<String> initialImageUrls;
  final double height;
  final double width;

  const MultiImageUploader({
    super.key,
    required this.onImagesChanged,
    this.initialImageUrls = const [],
    this.height = 200,
    this.width = double.infinity,
  });

  @override
  State<MultiImageUploader> createState() => _MultiImageUploaderState();
}

class _MultiImageUploaderState extends State<MultiImageUploader> {
  // New images selected by user
  List<Uint8List> _newImageBytes = [];
  List<String> _newFileNames = [];

  // Existing images (URLs)
  List<String> _existingImageUrls = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _existingImageUrls = List.from(widget.initialImageUrls);
  }

  @override
  void didUpdateWidget(covariant MultiImageUploader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImageUrls != oldWidget.initialImageUrls) {
      _existingImageUrls = List.from(widget.initialImageUrls);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildImageList()),
          const SizedBox(height: AppDimensions.paddingM),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildImageList() {
    final allItemsCount = _existingImageUrls.length + _newImageBytes.length;

    if (allItemsCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              'No images selected',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: allItemsCount,
      itemBuilder: (context, index) {
        // First show existing images, then new images
        if (index < _existingImageUrls.length) {
          return _buildExistingImageItem(index);
        } else {
          return _buildNewImageItem(index - _existingImageUrls.length);
        }
      },
    );
  }

  Widget _buildExistingImageItem(int index) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: AppDimensions.paddingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Image.network(_existingImageUrls[index], fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _removeExistingImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImageItem(int index) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: AppDimensions.paddingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Image.memory(_newImageBytes[index], fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _removeNewImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              color: Colors.black54,
              child: Text(
                _newFileNames[index],
                style: const TextStyle(color: Colors.white, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _pickImages,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate),
        label: Text(_isLoading ? 'Processing...' : 'Add Images'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
          side: const BorderSide(color: AppColors.primaryColor),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final List<Uint8List> newBytes = [];
        final List<String> newNames = [];

        for (var file in result.files) {
          if (file.size > 5 * 1024 * 1024) {
            // Skip files > 5MB
            continue;
          }
          if (file.bytes != null) {
            newBytes.add(file.bytes!);
            newNames.add(file.name);
          }
        }

        if (newBytes.isNotEmpty) {
          setState(() {
            _newImageBytes.addAll(newBytes);
            _newFileNames.addAll(newNames);
          });
          _notifyParent();
        }
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageBytes.removeAt(index);
      _newFileNames.removeAt(index);
    });
    _notifyParent();
  }

  void _removeExistingImage(int index) {
    // Note: This only removes it from the UI list.
    // The parent is notified of the remaining URLs so it can determine deletions.
    setState(() {
      _existingImageUrls.removeAt(index);
    });
    // In edit mode, we pass back the remaining *new* images and handle the URL list logic via callback if needed.
    // However, the interface asks for (bytes, filenames).
    // For editing, we typically need to know which URLs to keep.
    // Wait, the interface `onImagesSelected` returns (bytes, fileNames).
    // It doesn't natively support returning the modified list of initial URLs.
    // This is a limitation of the current signature.
    // I should probably update the signature or parent should manage deletions separately?
    // Actually, let's keep it simple: Adding images is separate from removing existing ones.
    // But wait, the parent needs to know the final state.
    // Let's rely on the parent checking 'initialImageUrls' vs what it has?
    // No, I should probably expose a callback for 'onUrlRemoved' or simply expose the current state.

    // For now, I will add a limitation: This widget mainly handles ADDING new images.
    // Handling removal of existing URLs might require a text callback.
    // Let's modify the class to support it if necessary.
    // Re-reading requirements: just "add option for adding multiple images".
    // But for Edit, we need to handle existing ones.

    // I will call a specialized callback if I add it, or just let the user handle it.
    // Let's modify the signature to be more robust?
    // Maybe `onImagesChanged(List<Uint8List> newBytes, List<String> keptUrls)`?
    // Yes, that is better.
    _notifyParent();
  }

  void _notifyParent() {
    widget.onImagesChanged(_newImageBytes, _existingImageUrls);
  }
}

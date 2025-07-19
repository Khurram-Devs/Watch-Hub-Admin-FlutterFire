import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io' as io;

class ImagePickerField extends StatelessWidget {
  final List<String> initialUrls;
  final int maxImages;
  final List<XFile> pickedFiles;
  final void Function(List<String> urls, List<XFile> pickedFiles)
  onImagesSelected;

  const ImagePickerField({
    super.key,
    required this.initialUrls,
    required this.maxImages,
    required this.onImagesSelected,
    this.pickedFiles = const [],
  });

  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      final newPicked = [...pickedFiles, ...images];
      final limited = newPicked.take(maxImages).toList();
      onImagesSelected(initialUrls, limited);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = initialUrls.length + pickedFiles.length;
    final canPickMore = totalImages < maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Images",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...initialUrls.map(
              (url) =>
                  _buildImagePreview(Image.network(url, fit: BoxFit.cover)),
            ),

            ...pickedFiles.map(
              (file) => FutureBuilder<Widget>(
                future: _buildPreview(file),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    return _buildImagePreview(snapshot.data!);
                  }
                  return const SizedBox(
                    width: 80,
                    height: 80,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),

            if (canPickMore) _buildImagePlaceholder(context),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickImages(context),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade100,
        ),
        child: const Center(
          child: Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
        ),
      ),
    );
  }

  Widget _buildImagePreview(Widget imageWidget) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: imageWidget,
      ),
    );
  }

  Future<Widget> _buildPreview(XFile file) async {
    try {
      if (kIsWeb) {
        Uint8List bytes = await file.readAsBytes();
        return Image.memory(bytes, fit: BoxFit.cover);
      } else {
        return Image.file(io.File(file.path), fit: BoxFit.cover);
      }
    } catch (_) {
      return const Icon(Icons.broken_image, color: Colors.red);
    }
  }
}

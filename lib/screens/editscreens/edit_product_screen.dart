import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'dart:typed_data';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Map<String, dynamic> categories;

  const EditProductScreen({
    super.key,
    required this.product,
    required this.categories,
  });

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _inventoryController = TextEditingController();
  final _caseSizeController = TextEditingController();
  final _waterResistanceController = TextEditingController();
  final _batteryController = TextEditingController();
  Map<String, dynamic> categoryMap = {};

  String? selectedBrand;
  List<String> selectedTypes = [];
  List<String> availableTypes = [];
  List<String> availableBrands = [];
  List<String> existingImages = [];
  List<XFile> newImages = [];
  bool isLoading = false;

  static const String API_BASE_URL = 'http://watch_hub_ep.atwebpages.com';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Add the image upload method
  Future<String?> uploadImage(
    dynamic imageFile, [
    String? originalFilename,
  ]) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$API_BASE_URL/simple_upload.php'),
      );

      if (kIsWeb) {
        String filename =
            originalFilename ??
            'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

        String mimeType = 'image/jpeg';
        String extension = filename.toLowerCase().split('.').last;

        switch (extension) {
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageFile as Uint8List,
            filename: filename,
            contentType: http_parser.MediaType.parse(mimeType),
          ),
        );
      } else {
        File file = imageFile as File;
        String extension = file.path.toLowerCase().split('.').last;
        String mimeType = 'image/jpeg';

        switch (extension) {
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            file.path,
            contentType: http_parser.MediaType.parse(mimeType),
          ),
        );
      }

      print('Uploading to: $API_BASE_URL/simple_upload.php');
      print('MIME Type: ${request.files.first.contentType}');

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      print('Response status: ${response.statusCode}');
      print('Response body: $responseString');

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseString);
        if (jsonResponse['success']) {
          return jsonResponse['image_url'];
        } else {
          print('Upload failed: ${jsonResponse['message']}');
          return null;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  String getCORSSafeImageUrl(String originalUrl) {
    if (originalUrl.startsWith('http://') ||
        originalUrl.startsWith('https://')) {
      Uri uri = Uri.parse(originalUrl);
      String filePath =
          uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
      return 'http://watch_hub_ep.atwebpages.com/cors_proxy.php?file=$filePath';
    }
    return 'http://watch_hub_ep.atwebpages.com/cors_proxy.php?file=$originalUrl';
  }

  Future<void> _initializeData() async {
    await _fetchCategories();

    _titleController.text = widget.product['title'] ?? '';
    _subtitleController.text = widget.product['subtitle'] ?? '';
    _descriptionController.text = widget.product['description'] ?? '';
    _priceController.text = widget.product['price']?.toString() ?? '';
    _inventoryController.text =
        widget.product['inventoryCount']?.toString() ?? '';

    if (widget.product['specs'] != null) {
      final specs = widget.product['specs'] as Map;
      _caseSizeController.text = specs['caseSize']?.toString() ?? '';
      _waterResistanceController.text =
          specs['waterResistance']?.toString() ?? '';
      _batteryController.text = specs['inBuiltBattery']?.toString() ?? '';
    }

    if (widget.product['brand'] != null) {
      final brandId = widget.product['brand'].toString();
      if (availableBrands.contains(brandId)) {
        selectedBrand = brandId;
      }
    }

    if (widget.product['categories'] != null) {
      selectedTypes.clear();
      for (var categoryId in widget.product['categories']) {
        if (availableTypes.contains(categoryId)) {
          selectedTypes.add(categoryId);
        }
      }
    }

    if (widget.product['images'] != null) {
      existingImages = List<String>.from(widget.product['images']);
    }

    setState(() {});

    print('Product data: ${widget.product}');
    print('Available brands: $availableBrands');
    print('Available types: $availableTypes');
    print('Selected brand: $selectedBrand');
    print('Selected types: $selectedTypes');
  }

  Future<void> _fetchCategories() async {
    final snapshot = await FirebaseDatabase.instance.ref("Category").get();
    if (!snapshot.exists) return;

    availableBrands.clear();
    availableTypes.clear();
    categoryMap.clear();

    for (var child in snapshot.children) {
      final data = Map<String, dynamic>.from(child.value as Map);
      categoryMap[child.key!] = data;

      if (data['type'] == '1') {
        availableBrands.add(child.key!);
      } else if (data['type'] == '2') {
        availableTypes.add(child.key!);
      }
    }

    print(
      'Fetched Categories - Brands: $availableBrands, Types: $availableTypes',
    );
  }

  String getCategoryName(String categoryId) {
    return categoryMap[categoryId]?['Name'] ?? 'Unknown';
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        int remainingSlots = 9 - existingImages.length - newImages.length;
        int imagesToAdd =
            images.length > remainingSlots ? remainingSlots : images.length;

        for (int i = 0; i < imagesToAdd; i++) {
          newImages.add(images[i]);
        }
      });
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      newImages.removeAt(index);
    });
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Upload new images first
      List<String> uploadedImageUrls = [];
      
      if (newImages.isNotEmpty) {
        for (int i = 0; i < newImages.length; i++) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uploading image ${i + 1}/${newImages.length}...'),
              duration: const Duration(seconds: 1),
            ),
          );

          String? imageUrl;
          if (kIsWeb) {
            // For web, convert XFile to Uint8List
            Uint8List imageBytes = await newImages[i].readAsBytes();
            imageUrl = await uploadImage(imageBytes, newImages[i].name);
          } else {
            // For mobile, convert XFile to File
            File imageFile = File(newImages[i].path);
            imageUrl = await uploadImage(imageFile);
          }

          if (imageUrl != null) {
            uploadedImageUrls.add(imageUrl);
          } else {
            throw Exception('Failed to upload image ${i + 1}');
          }
        }
      }

      // Combine existing images with newly uploaded ones
      List<String> allImageUrls = [...existingImages, ...uploadedImageUrls];

      // Prepare product data
      Map<String, dynamic> productData = {
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'inventoryCount': int.tryParse(_inventoryController.text) ?? 0,
        'brand': selectedBrand,
        'categories': selectedTypes,
        'specs': {
          'caseSize': _caseSizeController.text.trim(),
          'waterResistance': _waterResistanceController.text.trim(),
          'battery': _batteryController.text.trim(),
        },
        'images': allImageUrls, // Use the combined list
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Update product in Firebase
      DatabaseReference productRef = FirebaseDatabase.instance
          .ref()
          .child("Products")
          .child(widget.product['id']);

      await productRef.update(productData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B8A9A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Product',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _titleController,
                label: 'Product Title *',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _subtitleController,
                label: 'Product Subtitle',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Brand & Types Section
              _buildSectionTitle('Brand & Types'),
              const SizedBox(height: 16),
              _buildBrandDropdown(),
              const SizedBox(height: 16),
              _buildTypesSection(),
              const SizedBox(height: 24),

              // Pricing & Inventory Section
              _buildSectionTitle('Pricing & Inventory'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Price *',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _inventoryController,
                      label: 'Inventory Count *',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter inventory count';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Watch Specifications Section
              _buildSectionTitle('Watch Specifications'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _caseSizeController,
                label: 'Case Size (e.g., 42mm)',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _waterResistanceController,
                label: 'Water Resistance (e.g., 50m)',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _batteryController,
                label: 'Built-in Battery (e.g., 7 days)',
              ),
              const SizedBox(height: 24),

              // Product Images Section
              _buildSectionTitle('Product Images'),
              const SizedBox(height: 8),
              Text(
                'Current: ${existingImages.length + newImages.length}/9 images',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildImagesSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : _updateProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B8A9A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Update Product',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5B8A9A)),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildBrandDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedBrand,
      decoration: InputDecoration(
        labelText: 'Brand *',
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5B8A9A)),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: availableBrands.map((brandId) {
        return DropdownMenuItem(
          value: brandId,
          child: Text(getCategoryName(brandId)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedBrand = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a brand';
        }
        return null;
      },
    );
  }

  Widget _buildTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.category, size: 20, color: Color(0xFF6B7280)),
            const SizedBox(width: 8),
            const Text(
              'Product Types *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          selectedTypes.isEmpty
              ? 'No types selected'
              : '${selectedTypes.length} type(s) selected',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: availableTypes.map((typeId) {
              final isSelected = selectedTypes.contains(typeId);
              return Container(
                decoration: BoxDecoration(
                  border: availableTypes.last != typeId
                      ? Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        )
                      : null,
                ),
                child: CheckboxListTile(
                  title: Text(
                    getCategoryName(typeId),
                    style: const TextStyle(fontSize: 14),
                  ),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        if (!selectedTypes.contains(typeId)) {
                          selectedTypes.add(typeId);
                        }
                      } else {
                        selectedTypes.remove(typeId);
                      }
                    });
                  },
                  activeColor: const Color(0xFF5B8A9A),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      children: [
        if (existingImages.length + newImages.length < 9)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF5B8A9A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF5B8A9A),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Color(0xFF5B8A9A), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Add Images',
                      style: TextStyle(
                        color: Color(0xFF5B8A9A),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),

        if (existingImages.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Images:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: existingImages.length,
                itemBuilder: (context, index) {
                  return _buildExistingImageCard(index);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),

        if (newImages.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Images:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: newImages.length,
                itemBuilder: (context, index) {
                  return _buildNewImageCard(index);
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildExistingImageCard(int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              getCORSSafeImageUrl(existingImages[index]),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeExistingImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImageCard(int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.network(
                    newImages[index].path,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  )
                : Image.file(
                    File(newImages[index].path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeNewImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _inventoryController.dispose();
    _caseSizeController.dispose();
    _waterResistanceController.dispose();
    _batteryController.dispose();
    super.dispose();
  }
}
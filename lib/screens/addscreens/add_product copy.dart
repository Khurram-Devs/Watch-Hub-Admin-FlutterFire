import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Add this import
import 'dart:typed_data'; // Add this import
import 'package:http_parser/http_parser.dart' as http_parser;

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  TextEditingController productController = TextEditingController();
  TextEditingController productrateController = TextEditingController();
  TextEditingController productDescriptionController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController brandController = TextEditingController();
  TextEditingController modelController = TextEditingController();
  TextEditingController warrantyController = TextEditingController();
  String? selectedCategory;
  String? selectedQuality;
  Map<dynamic, dynamic>? categoriesMap;
  List<TextEditingController> imageControllers = [];
  List<String> imageUrls = [];

  // Modified to handle both File and Uint8List
  List<dynamic> selectedImages = []; // Can contain File or Uint8List
  List<String> uploadedImageUrls = [];
  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;

  static const String API_BASE_URL = 'http://watch_hub_ep.atwebpages.com';

  final List<String> qualityOptions = [
    'Premium',
    'Standard',
    'Basic',
    'Luxury',
  ];

  @override
  void initState() {
    super.initState();
    fetchCategories();
    // Initialize with 5 empty image slots
    for (int i = 0; i < 5; i++) {
      selectedImages.add(null);
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in imageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Fetch categories from Firebase Realtime Database
  void fetchCategories() {
    DatabaseReference categoryRef = FirebaseDatabase.instance.ref().child(
      "Category",
    );
    categoryRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          categoriesMap = data;
        });
      }
    });
  }

  void addProduct() async {
    String productName = productController.text.trim();
    String productRate = productrateController.text.trim();
    String productDescription = productDescriptionController.text.trim();
    String quantity = quantityController.text.trim();
    String brand = brandController.text.trim();
    String model = modelController.text.trim();
    String warranty = warrantyController.text.trim();

    if (productName.isNotEmpty &&
        productRate.isNotEmpty &&
        selectedCategory != null &&
        quantity.isNotEmpty) {
      setState(() {
        isUploading = true;
      });

      try {
        // Upload images first and get URLs
        List<String> imageUrls = [];
        for (var image in selectedImages) {
          if (image != null) {
            String? imageUrl;
            if (kIsWeb && image is Map) {
              // For web, pass both bytes and filename
              imageUrl = await uploadImage(image['bytes'], image['filename']);
            } else {
              // For mobile
              imageUrl = await uploadImage(image);
            }
            if (imageUrl != null) {
              imageUrls.add(imageUrl);
            }
          }
        }

        // Save product data to Firebase (with image URLs from MySQL)
        DatabaseReference dr = FirebaseDatabase.instance.ref().child("product");
        Map<String, dynamic> productData = {
          'name': productName,
          'rate': productRate,
          'description': productDescription,
          'category': selectedCategory,
          'quantity': quantity,
          'quality': selectedQuality ?? 'Standard',
          'brand': brand,
          'model': model,
          'warranty': warranty,
          'images': imageUrls, // These URLs come from MySQL server
          'dateAdded': DateTime.now().toIso8601String(),
        };

        await dr.push().set(productData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "$productName" added successfully!'),
            backgroundColor: const Color(0xFF4A90E2),
          ),
        );
        _clearFields();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: $error'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          isUploading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and select category.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String getMimeTypeFromExtension(String filename) {
    String extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

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
        // For web, imageFile is Uint8List
        // Use originalFilename if provided, otherwise default to .jpg
        String filename =
            originalFilename ??
            'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Determine MIME type based on file extension
        String mimeType = 'image/jpeg'; // Default fallback
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
        // For mobile, imageFile is File
        File file = imageFile as File;

        // Determine MIME type from file extension
        String extension = file.path.toLowerCase().split('.').last;
        String mimeType = 'image/jpeg'; // Default fallback

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
      print('MIME Type: ${request.files.first.contentType}'); // Debug print

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

  void _clearFields() {
    productController.clear();
    productrateController.clear();
    productDescriptionController.clear();
    quantityController.clear();
    brandController.clear();
    modelController.clear();
    warrantyController.clear();

    setState(() {
      selectedCategory = null;
      selectedQuality = null;
      selectedImages = List.filled(5, null);
      uploadedImageUrls.clear();
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: '$label${required ? ' *' : ''}',
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        if (kIsWeb) {
          // For web, read as bytes and store both bytes and filename
          image.readAsBytes().then((bytes) {
            setState(() {
              // Store as a map containing both bytes and filename
              selectedImages[index] = {'bytes': bytes, 'filename': image.name};
            });
          });
        } else {
          // For mobile, use File
          selectedImages[index] = File(image.path);
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages[index] = null;
    });
  }

  void _addImageSlot() {
    if (selectedImages.length < 9) {
      setState(() {
        selectedImages.add(null);
      });
    }
  }

  void _removeImageSlot(int index) {
    if (selectedImages.length > 5) {
      setState(() {
        selectedImages.removeAt(index);
      });
    }
  }

  Widget _buildImageDisplayWidget(dynamic image) {
    if (kIsWeb && image is Map && image['bytes'] != null) {
      return Image.memory(image['bytes'], fit: BoxFit.cover);
    } else if (!kIsWeb && image is File) {
      return Image.file(image, fit: BoxFit.cover);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Product Images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            if (selectedImages.length < 9)
              IconButton(
                onPressed: _addImageSlot,
                icon: const Icon(Icons.add_circle, color: Color(0xFF4A90E2)),
                tooltip: 'Add Image Slot',
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Add ${selectedImages.length}/9 images',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        const SizedBox(height: 16),
        ...selectedImages.asMap().entries.map((entry) {
          int index = entry.key;
          dynamic image = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      color: Colors.white,
                    ),
                    child:
                        image != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    child: _buildImageDisplayWidget(image),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Image ${index + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            kIsWeb
                                                ? 'Selected Image'
                                                : (image as File).path
                                                    .split('/')
                                                    .last,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed:
                                                () => _removeImage(index),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                            ),
                                            child: const Text(
                                              'Remove',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : InkWell(
                              onTap: () => _pickImage(index),
                              child: Container(
                                width: double.infinity,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_photo_alternate,
                                      size: 40,
                                      color: Color(0xFF6B7280),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add Image ${index + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                  ),
                ),
                if (selectedImages.length > 5)
                  IconButton(
                    onPressed: () => _removeImageSlot(index),
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    tooltip: 'Remove Image Slot',
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    bool required = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: '$label${required ? ' *' : ''}',
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        value: value,
        items: items,
        onChanged: onChanged,
      ),
    );
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
          'Add Product', // Updated from 'Add Product' to match the image
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false, // Aligns title to the left
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information Section
            _buildSectionHeader('Basic Information'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: productController,
              label: 'Watch Name',
              required: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: brandController,
                    label: 'Brand',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: modelController,
                    label: 'Model',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: productDescriptionController,
              label: 'Description',
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Pricing & Inventory Section
            _buildSectionHeader('Pricing & Inventory'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: productrateController,
                    label: 'Price',
                    keyboardType: TextInputType.number,
                    required: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: quantityController,
                    label: 'Quantity',
                    keyboardType: TextInputType.number,
                    required: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child:
                      categoriesMap != null
                          ? _buildDropdown<String>(
                            label: 'Category',
                            value: selectedCategory,
                            required: true,
                            items:
                                categoriesMap!.entries
                                    .map(
                                      (entry) => DropdownMenuItem<String>(
                                        value: entry.key,
                                        child: Text(
                                          entry.value['Name'] ?? 'No Name',
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCategory = value;
                              });
                            },
                          )
                          : const Center(child: CircularProgressIndicator()),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown<String>(
                    label: 'Quality',
                    value: selectedQuality,
                    items:
                        qualityOptions
                            .map(
                              (quality) => DropdownMenuItem<String>(
                                value: quality,
                                child: Text(quality),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedQuality = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Additional Information Section
            _buildSectionHeader('Additional Information'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: warrantyController,
              label: 'Warranty Period (e.g., 2 years)',
            ),
            const SizedBox(height: 24),

            // Images Section
            _buildImageSection(),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isUploading ? null : addProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child:
                        isUploading
                            ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Uploading...'),
                              ],
                            )
                            : const Text(
                              'Add Product',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF374151),
      ),
    );
  }
}

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart' as http_parser;

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  // Controllers matching database structure
  TextEditingController titleController = TextEditingController();
  TextEditingController subtitleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController inventoryCountController = TextEditingController();
  TextEditingController caseSizeController = TextEditingController();
  TextEditingController waterResistanceController = TextEditingController();
  TextEditingController inBuiltBatteryController = TextEditingController();

  String? selectedBrand; // Brand reference (single selection)
  List<String> selectedTypes = []; // Type references (multiple selection)
  Map<dynamic, dynamic>? brandsMap; // Categories with type = "1"
  Map<dynamic, dynamic>? typesMap; // Categories with type = "2"
  Map<String, dynamic> specs = {};

  // Image handling (keeping original functionality)
  List<dynamic> selectedImages = [];
  List<String> uploadedImageUrls = [];
  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;
  bool isLoadingData = true;
  static const String API_BASE_URL = 'http://watch_hub_ep.atwebpages.com';

  @override
  void initState() {
    super.initState();
    fetchCategoriesData();
    // Initialize with 5 empty image slots
    for (int i = 0; i < 5; i++) {
      selectedImages.add(null);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    subtitleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    inventoryCountController.dispose();
    caseSizeController.dispose();
    waterResistanceController.dispose();
    inBuiltBatteryController.dispose();
    super.dispose();
  }

  void fetchCategoriesData() {
    DatabaseReference categoryRef = FirebaseDatabase.instance.ref().child(
      "Category",
    );
    categoryRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        Map<dynamic, dynamic> brands = {};
        Map<dynamic, dynamic> types = {};

        // Separate categories by type
        data.forEach((key, value) {
          if (value['isActive'] == true) {
            // Only include active categories
            if (value['type'] == "1") {
              brands[key] = value;
            } else if (value['type'] == "2") {
              types[key] = value;
            }
          }
        });

        setState(() {
          brandsMap = brands;
          typesMap = types;
          isLoadingData = false;
        });
      } else {
        setState(() {
          isLoadingData = false;
        });
      }
    });
  }

  void addProduct() async {
    String title = titleController.text.trim();
    String subtitle = subtitleController.text.trim();
    String description = descriptionController.text.trim();
    String price = priceController.text.trim();
    String inventoryCount = inventoryCountController.text.trim();
    String caseSize = caseSizeController.text.trim();
    String waterResistance = waterResistanceController.text.trim();
    String inBuiltBattery = inBuiltBatteryController.text.trim();

    if (title.isNotEmpty &&
        price.isNotEmpty &&
        selectedBrand != null &&
        inventoryCount.isNotEmpty &&
        selectedTypes.isNotEmpty) {
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
              imageUrl = await uploadImage(image['bytes'], image['filename']);
            } else {
              imageUrl = await uploadImage(image);
            }
            if (imageUrl != null) {
              imageUrls.add(imageUrl);
            }
          }
        }

        // Prepare specs map
        Map<String, dynamic> productSpecs = {
          'caseSize': caseSize,
          'waterResistance': waterResistance,
          'inBuiltBattery': inBuiltBattery,
        };

        // Save product data to Firebase with proper references
        DatabaseReference dr = FirebaseDatabase.instance.ref().child(
          "Products",
        );
        Map<String, dynamic> productData = {
          'title': title,
          'subtitle': subtitle,
          'description': description,
          'brand': selectedBrand, // Reference to brand category (single)
          'price': double.tryParse(price) ?? 0.0,
          'inventoryCount': int.tryParse(inventoryCount) ?? 0,
          'images': imageUrls,
          'categories': selectedTypes, // Array of type category references
          'specs': productSpecs,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'averageRating': 0.0,
          'totalRatings': 0,
          'reviews': [], // Empty subcollection initially
        };

        await dr.push().set(productData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text('Product "$title" added successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _clearFields();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Text('Failed to add product: $error'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } finally {
        setState(() {
          isUploading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Removed `const` here
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Please fill all required fields and select brand and types.',
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // ✅ This now works
          ),
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
        return 'image/jpeg';
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

  void _clearFields() {
    titleController.clear();
    subtitleController.clear();
    descriptionController.clear();
    priceController.clear();
    inventoryCountController.clear();
    caseSizeController.clear();
    waterResistanceController.clear();
    inBuiltBatteryController.clear();

    setState(() {
      selectedBrand = null;
      selectedTypes.clear();
      selectedImages = List.filled(5, null);
      uploadedImageUrls.clear();
      specs.clear();
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
          image.readAsBytes().then((bytes) {
            setState(() {
              selectedImages[index] = {'bytes': bytes, 'filename': image.name};
            });
          });
        } else {
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

  Widget _buildMultiSelectTypes() {
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.style, color: Color(0xFF6B7280)),
                const SizedBox(width: 8),
                const Text(
                  'Product Types *',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedTypes.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    selectedTypes.map((typeId) {
                      String typeName = typesMap?[typeId]?['Name'] ?? typeId;
                      return Chip(
                        label: Text(typeName),
                        backgroundColor: const Color(0xFF4A90E2),
                        labelStyle: const TextStyle(color: Colors.white),
                        deleteIcon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                        onDeleted: () {
                          setState(() {
                            selectedTypes.remove(typeId);
                          });
                        },
                      );
                    }).toList(),
              )
            else
              const Text(
                'No types selected',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            if (typesMap != null)
              ...typesMap!.entries.map((entry) {
                String typeId = entry.key;
                String typeName = entry.value['Name'] ?? 'No Name';
                bool isSelected = selectedTypes.contains(typeId);

                return CheckboxListTile(
                  dense: true,
                  title: Text(typeName),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedTypes.add(typeId);
                      } else {
                        selectedTypes.remove(typeId);
                      }
                    });
                  },
                  activeColor: const Color(0xFF4A90E2),
                  contentPadding: EdgeInsets.zero,
                );
              }).toList()
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
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
          'Add Product',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body:
          isLoadingData
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF5B8A9A)),
                    SizedBox(height: 16),
                    Text(
                      'Loading categories...',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information Section
                    _buildSectionHeader('Basic Information'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: titleController,
                      label: 'Product Title',
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: subtitleController,
                      label: 'Product Subtitle',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: descriptionController,
                      label: 'Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Brand & Types Section
                    _buildSectionHeader('Brand & Types'),
                    const SizedBox(height: 16),

                    // Brand Dropdown (Single Selection)
                    brandsMap != null && brandsMap!.isNotEmpty
                        ? _buildDropdown<String>(
                          label: 'Brand',
                          value: selectedBrand,
                          required: true,
                          items:
                              brandsMap!.entries
                                  .map(
                                    (entry) => DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.branding_watermark,
                                            color: Color(0xFF6B7280),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            entry.value['Name'] ?? 'No Name',
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedBrand = value;
                            });
                          },
                        )
                        : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                'No brands available. Please add brands first.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 16),

                    // Types Multi-Select (Checkboxes)
                    typesMap != null && typesMap!.isNotEmpty
                        ? _buildMultiSelectTypes()
                        : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                'No types available. Please add types first.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 24),

                    // Pricing & Inventory Section
                    _buildSectionHeader('Pricing & Inventory'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: priceController,
                            label: 'Price',
                            keyboardType: TextInputType.number,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: inventoryCountController,
                            label: 'Inventory Count',
                            keyboardType: TextInputType.number,
                            required: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Watch Specifications Section
                    _buildSectionHeader('Watch Specifications'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: caseSizeController,
                      label: 'Case Size (e.g., 42mm)',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: waterResistanceController,
                      label: 'Water Resistance (e.g., 50m)',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: inBuiltBatteryController,
                      label: 'Built-in Battery (e.g., 7 days)',
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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

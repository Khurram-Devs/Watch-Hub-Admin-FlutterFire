import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:watch_hub_ep/models/product_model.dart';
import 'package:watch_hub_ep/models/category_model.dart';
import 'package:watch_hub_ep/services/product_service.dart';
import 'package:watch_hub_ep/services/category_service.dart';
import 'package:watch_hub_ep/widgets/product_table/brand_dropdown.dart';
import 'package:watch_hub_ep/widgets/product_table/categories_multiselect.dart';
import 'package:watch_hub_ep/widgets/product_table/image_picker_field.dart';
import 'package:watch_hub_ep/widgets/product_table/product_text_field.dart';
import 'package:watch_hub_ep/widgets/product_table/specs_editor.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? existingProduct;
  const AddProductScreen({super.key, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'title': TextEditingController(),
    'subtitle': TextEditingController(),
    'description': TextEditingController(),
    'price': TextEditingController(),
    'discountPercentage': TextEditingController(),
    'inventoryCount': TextEditingController(),
  };

  List<String> _uploadedImageUrls = [];
  List<XFile> _newPickedImages = [];
  Map<String, dynamic> _specs = {};
  CategoryModel? _selectedBrand;
  List<CategoryModel> _selectedCategories = [];
  List<CategoryModel> _brands = [];
  List<CategoryModel> _categories = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.existingProduct != null) {
      _populateForm(widget.existingProduct!);
    }
  }
  

  Future<void> _loadCategories() async {
    final brands = await CategoryService.fetchByType(1);
    final categories = await CategoryService.fetchByType(2);
    setState(() {
      _brands = brands;
      _categories = categories;
    });
  }
void _populateForm(ProductModel product) {
  _controllers['title']!.text = product.title;
  _controllers['subtitle']!.text = product.subtitle;
  _controllers['description']!.text = product.description;
  _controllers['price']!.text = product.price.toString();
  _controllers['discountPercentage']!.text = product.discountPercentage.toString();
  _controllers['inventoryCount']!.text = product.inventoryCount.toString();
  _uploadedImageUrls = product.images;
  _specs = product.specs;

  _selectedBrand = _brands.isEmpty
      ? null
      : _brands.firstWhere(
          (b) => b.id == product.brand,
          orElse: () => _brands.first,
        );

  _selectedCategories = _categories.where((c) => product.categories.contains(c.id)).toList();
}

  Future<List<String>> _uploadImagesToImgbb(List<XFile> files) async {
    List<String> urls = [];
    const apiKey = '35e23c1d07b073e59906736c89bb77c5';
    for (var file in files) {
      final base64Image = base64Encode(await file.readAsBytes());
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
        body: {'image': base64Image},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        urls.add(data['data']['url']);
      }
    }
    return urls;
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isLoading = true);

    final newImageUrls = await _uploadImagesToImgbb(_newPickedImages);

    final product = ProductModel(
      id: widget.existingProduct?.id ?? '',
      title: _controllers['title']!.text,
      subtitle: _controllers['subtitle']!.text,
      description: _controllers['description']!.text,
      price: num.tryParse(_controllers['price']!.text) ?? 0,
      discountPercentage:
          num.tryParse(_controllers['discountPercentage']!.text) ?? 0,
      inventoryCount: int.tryParse(_controllers['inventoryCount']!.text) ?? 0,
      averageRating: widget.existingProduct?.averageRating ?? 0,
      totalRatings: widget.existingProduct?.totalRatings ?? 0,
      images: [..._uploadedImageUrls, ...newImageUrls],
      specs: _specs,
      brand: _selectedBrand?.id,
      categories: _selectedCategories.map((e) => e.id).toList(),
      createdAt: widget.existingProduct?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ProductService.addOrUpdateProduct(product);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingProduct == null
                ? 'Product added successfully'
                : 'Product updated successfully',
          ),
        ),
      );
      Navigator.pop(context);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingProduct == null ? "Add New Product" : "Edit Product",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                runSpacing: 12,
                children: [
                  ProductTextField(
                    label: "Title",
                    controller: _controllers['title']!,
                  ),
                  ProductTextField(
                    label: "Subtitle",
                    controller: _controllers['subtitle']!,
                  ),
                  ProductTextField(
                    label: "Description",
                    controller: _controllers['description']!,
                    maxLines: 3,
                  ),
                  ProductTextField(
                    label: "Price",
                    controller: _controllers['price']!,
                    keyboardType: TextInputType.number,
                  ),
                  ProductTextField(
                    label: "Discount (%)",
                    controller: _controllers['discountPercentage']!,
                    keyboardType: TextInputType.number,
                  ),
                  ProductTextField(
                    label: "Inventory Count",
                    controller: _controllers['inventoryCount']!,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ImagePickerField(
                initialUrls: _uploadedImageUrls,
                pickedFiles: _newPickedImages,
                maxImages: 8,
                onImagesSelected: (urls, pickedFiles) {
                  setState(() {
                    _uploadedImageUrls = urls;
                    _newPickedImages = pickedFiles;
                  });
                },
              ),
              const SizedBox(height: 16),
              SpecsEditor(
                initialSpecs: _specs,
                onSpecsChanged: (specs) => setState(() => _specs = specs),
              ),
              const SizedBox(height: 16),
              BrandDropdown(
                brands: _brands,
                selectedBrand: _selectedBrand,
                onChanged: (brand) => setState(() => _selectedBrand = brand),
              ),
              const SizedBox(height: 16),
              CategoriesMultiSelect(
                categories: _categories,
                selectedCategories: _selectedCategories,
                onSelectionChanged:
                    (selected) =>
                        setState(() => _selectedCategories = selected),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(
                    widget.existingProduct == null ? Icons.add : Icons.save,
                  ),
                  label: Text(
                    widget.existingProduct == null
                        ? "Add Product"
                        : "Update Product",
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController subtitleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController inventoryController = TextEditingController();
  final TextEditingController image1Controller = TextEditingController();
  final TextEditingController image2Controller = TextEditingController();
  final TextEditingController caseSizeController = TextEditingController();
  final TextEditingController batteryController = TextEditingController();
  final TextEditingController waterResistantController = TextEditingController();

  DocumentReference? selectedBrand;
  List<DocumentReference> selectedCategories = [];

  List<DocumentReference> brandOptions = [];
  List<DocumentReference> categoryOptions = [];

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    final categorySnapshot = await FirebaseFirestore.instance.collection('categories').get();
    final brandSnapshot = await FirebaseFirestore.instance.collection('brands').get();

    setState(() {
      categoryOptions = categorySnapshot.docs.map((doc) => doc.reference).toList();
      brandOptions = brandSnapshot.docs.map((doc) => doc.reference).toList();
    });
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate() || selectedBrand == null || selectedCategories.isEmpty) return;

    final productData = {
      'title': titleController.text.trim(),
      'subtitle': subtitleController.text.trim(),
      'description': descriptionController.text.trim(),
      'price': double.tryParse(priceController.text.trim()) ?? 0,
      'discountPercentage': int.tryParse(discountController.text.trim()) ?? 0,
      'inventoryCount': int.tryParse(inventoryController.text.trim()) ?? 0,
      'images': [image1Controller.text.trim(), image2Controller.text.trim()],
      'brand': selectedBrand,
      'categories': selectedCategories,
      'averageRating': 0,
      'totalRatings': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'specs': {
        'caseSize': caseSizeController.text.trim(),
        'inBuiltBattery': batteryController.text.trim(),
        'waterResistance': waterResistantController.text.trim(),
      },
    };

    await FirebaseFirestore.instance.collection('products').add(productData);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: titleController, decoration: const InputDecoration(labelText: 'Title'), validator: (val) => val!.isEmpty ? 'Required' : null),
              TextFormField(controller: subtitleController, decoration: const InputDecoration(labelText: 'Subtitle')),
              TextFormField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
              TextFormField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              TextFormField(controller: discountController, decoration: const InputDecoration(labelText: 'Discount %'), keyboardType: TextInputType.number),
              TextFormField(controller: inventoryController, decoration: const InputDecoration(labelText: 'Inventory Count'), keyboardType: TextInputType.number),
              TextFormField(controller: image1Controller, decoration: const InputDecoration(labelText: 'Image 1 URL')),
              TextFormField(controller: image2Controller, decoration: const InputDecoration(labelText: 'Image 2 URL')),
              TextFormField(controller: caseSizeController, decoration: const InputDecoration(labelText: 'Case Size')),
              TextFormField(controller: batteryController, decoration: const InputDecoration(labelText: 'In-Built Battery')),
              TextFormField(controller: waterResistantController, decoration: const InputDecoration(labelText: 'Water Resistance')),
              const SizedBox(height: 16),
              DropdownButtonFormField<DocumentReference>(
                value: selectedBrand,
                decoration: const InputDecoration(labelText: 'Brand'),
                items: brandOptions.map((ref) => DropdownMenuItem(value: ref, child: Text(ref.id))).toList(),
                onChanged: (val) => setState(() => selectedBrand = val),
                validator: (val) => val == null ? 'Select brand' : null,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: categoryOptions.map((ref) {
                  final isSelected = selectedCategories.contains(ref);
                  return FilterChip(
                    label: Text(ref.id),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedCategories.add(ref);
                        } else {
                          selectedCategories.remove(ref);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitProduct,
                child: const Text('Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watch_hub_ep/models/category_model.dart';
import 'package:watch_hub_ep/services/category_service.dart';
import 'package:watch_hub_ep/utils/image_upload_helper.dart';

class AddBrandScreen extends StatefulWidget {
  final CategoryModel? brandToEdit;

  const AddBrandScreen({super.key, this.brandToEdit});

  @override
  State<AddBrandScreen> createState() => _AddBrandScreenState();
}

class _AddBrandScreenState extends State<AddBrandScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _selectedType = 1;
  String? _uploadedIconUrl;
  XFile? _newPickedIcon;

  bool get isEditing => widget.brandToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.brandToEdit!.name;
      _selectedType = widget.brandToEdit!.type;
      _uploadedIconUrl = widget.brandToEdit!.iconUrl;
    }
  }

  Future<void> _pickIconImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newPickedIcon = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    String? finalIconUrl = _uploadedIconUrl;

    if (_newPickedIcon != null) {
      finalIconUrl = await ImageUploadHelper.uploadImageToImgBB(
        _newPickedIcon!,
      );
    }

    final category = CategoryModel(
      id: isEditing ? widget.brandToEdit!.id : '',
      name: _nameController.text.trim(),
      type: _selectedType,
      iconUrl: finalIconUrl ?? '',
      createdAt: isEditing ? widget.brandToEdit!.createdAt : DateTime.now(),
    );

    if (isEditing) {
      await CategoryService.updateCategory(category);
    } else {
      await CategoryService.addCategory(category);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Brand' : 'Add Brand')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Brand Name'),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
              ),
              const SizedBox(height: 16),

              // Type Dropdown
              DropdownButtonFormField<int>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Brand')),
                  DropdownMenuItem(value: 2, child: Text('Category')),
                ],
                decoration: const InputDecoration(labelText: 'Type'),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),

              // Icon Picker
              GestureDetector(
                onTap: _pickIconImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                    color: Colors.grey.shade100,
                  ),
                  child:
                      _newPickedIcon != null
                          ? FutureBuilder<Uint8List>(
                            future: _newPickedIcon!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              } else {
                                return const SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                            },
                          )
                          : _uploadedIconUrl != null &&
                              _uploadedIconUrl!.isNotEmpty
                          ? Image.network(_uploadedIconUrl!, fit: BoxFit.cover)
                          : const Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.grey,
                          ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Update Brand' : 'Add Brand'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

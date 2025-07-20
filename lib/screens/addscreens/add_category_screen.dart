import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watch_hub_ep/models/category_model.dart';
import 'package:watch_hub_ep/services/category_service.dart';
import 'package:watch_hub_ep/utils/image_upload_helper.dart';

class AddCategoryScreen extends StatefulWidget {
  final CategoryModel? brandToEdit;

  const AddCategoryScreen({super.key, this.brandToEdit});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _iconUrlController = TextEditingController();

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
      if (_selectedType == 2) {
        _iconUrlController.text = _uploadedIconUrl ?? '';
      }
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

    String? finalIconUrl;

    if (_selectedType == 1) {
      // Brand: Upload picked image
      if (_newPickedIcon != null) {
        finalIconUrl = await ImageUploadHelper.uploadImageToImgBB(
          _newPickedIcon!,
        );
      } else {
        finalIconUrl = _uploadedIconUrl;
      }
    } else {
      // Category: Use manually entered URL
      finalIconUrl = _iconUrlController.text.trim();
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
    final isBrand = _selectedType == 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Brand/Category' : 'Add Brand/Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
              ),
              const SizedBox(height: 16),

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

              if (isBrand)
                GestureDetector(
                  onTap: _pickIconImage,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 200,
                      maxHeight: 200,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
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
                                      fit: BoxFit.contain,
                                    );
                                  } else {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                },
                              )
                              : _uploadedIconUrl != null &&
                                  _uploadedIconUrl!.isNotEmpty
                              ? Image.network(
                                _uploadedIconUrl!,
                                fit: BoxFit.contain,
                              )
                              : const Center(
                                child: Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                    ),
                  ),
                )
              else
                TextFormField(
                  controller: _iconUrlController,
                  decoration: const InputDecoration(labelText: 'Icon URL'),
                  validator: (value) {
                    if (_selectedType == 2 &&
                        (value == null || value.trim().isEmpty)) {
                      return 'URL required for category';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Update' : 'Add'),
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

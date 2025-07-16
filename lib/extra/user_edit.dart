import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EditUserPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditUserPage({super.key, required this.userData});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController numberController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userData['name']);
    ageController = TextEditingController(text: widget.userData['age']);
    numberController = TextEditingController(text: widget.userData['number']);
    addressController = TextEditingController(text: widget.userData['address']);
  }

  void _saveChanges() {
    final updatedData = {
      'name': nameController.text.trim(),
      'email': widget.userData['email'], // not editable
      'age': int.tryParse(ageController.text.trim()) ?? 0,
      'number': numberController.text.trim(),
      'address': addressController.text.trim(),
    };

    DatabaseReference dbRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(widget.userData['key']);

    dbRef.update(updatedData).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully')),
      );
      Navigator.pop(context);
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit User")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: ageController, decoration: const InputDecoration(labelText: "Age"), keyboardType: TextInputType.number),
            TextField(controller: numberController, decoration: const InputDecoration(labelText: "Phone")),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveChanges, child: const Text("Save Changes")),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ProductTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final int maxLines;

  const ProductTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
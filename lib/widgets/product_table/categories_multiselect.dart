import 'package:flutter/material.dart';
import 'package:watch_hub_ep/models/category_model.dart';

class CategoriesMultiSelect extends StatelessWidget {
  final List<CategoryModel> categories;
  final List<CategoryModel> selectedCategories;
  final Function(List<CategoryModel>) onSelectionChanged;

  const CategoriesMultiSelect({super.key, required this.categories, required this.selectedCategories, required this.onSelectionChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      children: categories.map((cat) {
        final isSelected = selectedCategories.contains(cat);
        return FilterChip(
          label: Text(cat.name),
          selected: isSelected,
          onSelected: (selected) {
            final updated = List<CategoryModel>.from(selectedCategories);
            selected ? updated.add(cat) : updated.remove(cat);
            onSelectionChanged(updated);
          },
        );
      }).toList(),
    );
  }
}
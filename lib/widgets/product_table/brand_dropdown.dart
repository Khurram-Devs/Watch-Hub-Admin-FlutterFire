import 'package:flutter/material.dart';
import 'package:watch_hub_ep/models/category_model.dart';

class BrandDropdown extends StatelessWidget {
  final List<CategoryModel> brands;
  final CategoryModel? selectedBrand;
  final Function(CategoryModel?) onChanged;

  const BrandDropdown({
    super.key,
    required this.brands,
    required this.selectedBrand,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CategoryModel>(
      value: selectedBrand,
      items:
          brands
              .map(
                (brand) =>
                    DropdownMenuItem(value: brand, child: Text(brand.name)),
              )
              .toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(labelText: 'Brand'),
    );
  }
}

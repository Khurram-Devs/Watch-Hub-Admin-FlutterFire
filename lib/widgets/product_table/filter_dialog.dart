import 'package:flutter/material.dart';
import 'package:watch_hub_ep/utils/string_utils.dart';

class FilterDialog extends StatefulWidget {
  final String selectedBrand;
  final String selectedCategory;
  final double minPrice;
  final double maxPrice;
  final String sortBy;
  final List<String> brandOptions;
  final List<String> categoryOptions;
  final Function(String, String, double, double, String) onApply;

  const FilterDialog({
    super.key,
    required this.selectedBrand,
    required this.selectedCategory,
    required this.minPrice,
    required this.maxPrice,
    required this.sortBy,
    required this.brandOptions,
    required this.categoryOptions,
    required this.onApply,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late String _brand;
  late String _category;
  late double _minPrice;
  late double _maxPrice;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _brand = widget.selectedBrand;
    _category = widget.selectedCategory;
    _minPrice = widget.minPrice;
    _maxPrice = widget.maxPrice;
    _sortBy = widget.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Products'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown('Brand', _brand, widget.brandOptions, (val) => setState(() => _brand = val)),
              _buildDropdown('Category', _category, widget.categoryOptions, (val) => setState(() => _category = val)),
              const SizedBox(height: 12),
              const Text('Price Range:', style: TextStyle(fontWeight: FontWeight.bold)),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: 10000,
                divisions: 100,
                labels: RangeLabels('\$${_minPrice.toStringAsFixed(0)}', '\$${_maxPrice.toStringAsFixed(0)}'),
                onChanged: (values) {
                  setState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildDropdown('Sort By', _sortBy, const [
                'newest', 'oldest', 'priceAsc', 'priceDesc', 'nameAsc', 'nameDesc'
              ], (val) => setState(() => _sortBy = val)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _brand = 'All';
              _category = 'All';
              _minPrice = 0;
              _maxPrice = 10000;
              _sortBy = 'newest';
            });
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onApply(_brand, _category, _minPrice, _maxPrice, _sortBy);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

Widget _buildDropdown(
  String label,
  String value,
  List<String> options,
  ValueChanged<String> onChanged,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      DropdownButton<String>(
        value: value,
        isExpanded: true,
        onChanged: (val) => onChanged(val!),
        items: options.map(
          (opt) => DropdownMenuItem(
            value: opt,
            child: Text(capitalizeEachWord(opt)),
          ),
        ).toList(),
      ),
      const SizedBox(height: 12),
    ],
  );
}}
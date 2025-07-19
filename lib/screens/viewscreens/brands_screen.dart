import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:watch_hub_ep/models/category_model.dart';
import 'package:watch_hub_ep/services/category_service.dart';
import 'package:watch_hub_ep/utils/string_utils.dart';
import 'package:watch_hub_ep/screens/addscreens/add_brand_screen.dart';
import 'package:watch_hub_ep/widgets/product_table/search_bar.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  List<CategoryModel> _brands = [];
  List<CategoryModel> _filteredBrands = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBrands();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBrands() async {
    setState(() => _isLoading = true);
    final type1 = await CategoryService.fetchByType(1);
    final type2 = await CategoryService.fetchByType(2);
    final brands = [...type1, ...type2];
    setState(() {
      _brands = brands;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      _filteredBrands =
          _brands
              .where(
                (b) => b.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
              )
              .toList();
    });
  }

  void _onEdit(CategoryModel brand) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddBrandScreen(brandToEdit: brand)),
    );
    if (updated == true) _fetchBrands();
  }

  void _onDelete(CategoryModel brand) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: Text("Delete \"${brand.name}\"?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await CategoryService.deleteCategory(brand.id);
      _fetchBrands();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ProductSearchBar(controller: _searchController, onFilterTap: () {}),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredBrands.isEmpty
                    ? const Center(
                      child: Text("No brands or categories found."),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: _filteredBrands.length,
                      itemBuilder: (_, i) {
                        final brand = _filteredBrands[i];
                        final isSvg = brand.iconUrl.toLowerCase().endsWith(
                          '.svg',
                        );
                        final iconUrl =
                            'https://corsproxy.io/?${brand.iconUrl}';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              radius: 22,
                              child:
                                  isSvg
                                      ? SvgPicture.network(
                                        iconUrl,
                                        width: 32,
                                        height: 32,
                                        placeholderBuilder:
                                            (_) =>
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                      )
                                      : Image.network(
                                        brand.iconUrl,
                                        width: 32,
                                        height: 32,
                                        errorBuilder:
                                            (_, __, ___) =>
                                                const Icon(Icons.image),
                                      ),
                            ),
                            title: Text(capitalizeEachWord(brand.name)),
                            subtitle: Text(
                              brand.type == 1 ? "Brand" : "Product Category",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _onEdit(brand),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _onDelete(brand),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBrandScreen()),
          );
          if (created == true) _fetchBrands();
        },
        backgroundColor: const Color(0xFF5B8A9A),
        child: const Icon(Icons.add),
      ),
    );
  }
}

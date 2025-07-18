import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../services/product_service.dart';
import '../../widgets/product_table/search_bar.dart';
import '../../widgets/product_table/filter_dialog.dart';
import '../../widgets/product_table/product_card.dart';
import '../addscreens/add_product_screen.dart';

class ProductTableScreen extends StatefulWidget {
  const ProductTableScreen({super.key});

  @override
  State<ProductTableScreen> createState() => _ProductTableScreenState();
}

class _ProductTableScreenState extends State<ProductTableScreen> {
  List<ProductModel> products = [];
  List<ProductModel> filteredProducts = [];
  Map<String, CategoryModel> categories = {};
  bool isLoading = true;
  String error = '';

  final searchController = TextEditingController();
  String selectedBrand = 'All';
  String selectedCategory = 'All';
  double minPrice = 0;
  double maxPrice = 10000;
  String sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _fetchData();
    searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final fetchedCats = await ProductService.getCategories();
      final fetchedProds = await ProductService.getProducts();

      setState(() {
        categories = fetchedCats.map((key, value) {
          return MapEntry(key, CategoryModel.fromMap(value, key));
        });
        products = fetchedProds;
        filteredProducts = fetchedProds;
        isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  void _applyFilters() {
    List<ProductModel> temp = List.from(products);
    final search = searchController.text.toLowerCase();

    if (search.isNotEmpty) {
      temp =
          temp.where((p) {
            final brand = _getBrandName(p.brand).toLowerCase();
            return p.title.toLowerCase().contains(search) ||
                p.subtitle.toLowerCase().contains(search) ||
                brand.contains(search);
          }).toList();
    }

    if (selectedBrand != 'All') {
      temp =
          temp.where((p) => _getBrandName(p.brand) == selectedBrand).toList();
    }

    if (selectedCategory != 'All') {
      temp =
          temp.where((p) {
            return p.categories.any((id) {
              return categories[id]?.name == selectedCategory;
            });
          }).toList();
    }

    temp =
        temp.where((p) => p.price >= minPrice && p.price <= maxPrice).toList();

    switch (sortBy) {
      case 'priceAsc':
        temp.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'priceDesc':
        temp.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'nameAsc':
        temp.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'nameDesc':
        temp.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'oldest':
        temp.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      default:
        temp.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    setState(() => filteredProducts = temp);
  }

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder:
          (_) => FilterDialog(
            selectedBrand: selectedBrand,
            selectedCategory: selectedCategory,
            minPrice: minPrice,
            maxPrice: maxPrice,
            sortBy: sortBy,
            brandOptions:
                {
                  'All',
                  ...products.map((p) => _getBrandName(p.brand)),
                }.toList(),
            categoryOptions:
                {'All', ...categories.values.map((c) => c.name)}.toList(),
            onApply: (b, c, min, max, s) {
              setState(() {
                selectedBrand = b;
                selectedCategory = c;
                minPrice = min;
                maxPrice = max;
                sortBy = s;
              });
              _applyFilters();
            },
          ),
    );
  }

  String _getBrandName(String? brandId) {
    final brand = categories[brandId];
    if (brand?.type == 1) return brand?.name ?? 'Unknown Brand';
    return 'Unknown Brand';
  }

  String _getCategoryNames(List<String> ids) {
    return ids.map((id) => categories[id]?.name ?? 'Unknown').join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ProductSearchBar(
            controller: searchController,
            onFilterTap: _openFilterDialog,
          ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : error.isNotEmpty
                    ? Center(child: Text('Error: $error'))
                    : filteredProducts.isEmpty
                    ? const Center(child: Text('No products found'))
                    : ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (_, index) {
                        final p = filteredProducts[index];
                        return ProductCard(
                          product: p,
                          brandName: _getBrandName(p.brand),
                          categoryNames: _getCategoryNames(p.categories),
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => AddProductScreen(existingProduct: p),
                              ),
                            );
                          },
                          onDelete: () async {
                            await ProductService.deleteProduct(p.id);
                            _fetchData();
                          },
                        );
                      },
                    ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
          if (result == true) _fetchData();
        },
        backgroundColor: const Color(0xFF5B8A9A),
        child: const Icon(Icons.add),
      ),
    );
  }
}

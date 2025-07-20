import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:watch_hub_ep/models/category_model.dart';
import 'package:watch_hub_ep/services/category_service.dart';
import 'package:watch_hub_ep/services/product_service.dart';
import 'package:watch_hub_ep/utils/string_utils.dart';
import 'package:watch_hub_ep/screens/addscreens/add_category_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<CategoryModel> _brands = [];
  List<CategoryModel> _filteredBrands = [];
  Map<String, int> _productCounts = {};
  bool _isLoading = true;
  String _filterType = 'all';

  final TextEditingController _searchController = TextEditingController();
  StreamSubscription? _categorySub;

  @override
  void initState() {
    super.initState();
    _listenToCategories();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categorySub?.cancel();
    super.dispose();
  }

  void _listenToCategories() {
    setState(() => _isLoading = true);
    _categorySub = FirebaseFirestore.instance
        .collection('categories')
        .snapshots()
        .listen((snapshot) async {
      final docs = snapshot.docs;
      final brands = docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .where((c) => c.type == 1 || c.type == 2)
          .toList();

      final products = await ProductService.getProducts();

      final Map<String, int> counts = {};
      for (final c in brands) {
        if (c.type == 1) {
          counts[c.id] = products.where((p) => p.brand?.id == c.id).length;
        } else {
          counts[c.id] =
              products.where((p) => p.categories.any((cat) => cat.id == c.id)).length;
        }
      }

      setState(() {
        _brands = brands;
        _productCounts = counts;
        _applyFilter();
        _isLoading = false;
      });
    });
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBrands = _brands.where((b) {
        final matchesText = b.name.toLowerCase().contains(query);
        final matchesType = _filterType == 'all' ||
            (_filterType == 'brands' && b.type == 1) ||
            (_filterType == 'categories' && b.type == 2);
        return matchesText && matchesType;
      }).toList();
    });
  }

  void _onEdit(CategoryModel brand) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddCategoryScreen(brandToEdit: brand)),
    );
    if (updated == true) _listenToCategories();
  }

  void _onDelete(CategoryModel brand) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete \"${capitalizeEachWord(brand.name)}\"?"),
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
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _filterType == 'all',
                onSelected: (_) {
                  _filterType = 'all';
                  _applyFilter();
                },
              ),
              FilterChip(
                label: const Text('Brands'),
                selected: _filterType == 'brands',
                onSelected: (_) {
                  _filterType = 'brands';
                  _applyFilter();
                },
              ),
              FilterChip(
                label: const Text('Categories'),
                selected: _filterType == 'categories',
                onSelected: (_) {
                  _filterType = 'categories';
                  _applyFilter();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<CategoryModel> items) {
    if (items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...items.map((brand) {
          final isSvg = brand.iconUrl.toLowerCase().endsWith('.svg');
          final iconUrl = 'https://corsproxy.io/?${brand.iconUrl}';
          final productCount = _productCounts[brand.id] ?? 0;

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                radius: 22,
                child: isSvg
                    ? SvgPicture.network(
                        iconUrl,
                        width: 32,
                        height: 32,
                        placeholderBuilder: (_) => const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Image.network(
                        brand.iconUrl,
                        width: 32,
                        height: 32,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image),
                      ),
              ),
              title: Text(capitalizeEachWord(brand.name)),
              subtitle: Text(
                (brand.type == 1 ? "Brand" : "Category") + " • $productCount product${productCount == 1 ? '' : 's'}",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _onEdit(brand),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _onDelete(brand),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBrands.isEmpty
                    ? const Center(child: Text("No brands or categories found."))
                    : ListView(
                        children: [
                          _buildSection("Brands", _filteredBrands.where((b) => b.type == 1).toList()),
                          _buildSection("Categories", _filteredBrands.where((b) => b.type == 2).toList()),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
          );
          if (created == true) _listenToCategories();
        },
        backgroundColor: const Color(0xFF5B8A9A),
        child: const Icon(Icons.add),
      ),
    );
  }
}

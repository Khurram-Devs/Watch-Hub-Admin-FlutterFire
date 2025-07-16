import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:watch_hub_ep/screens/addscreens/add_product.dart';
import 'package:watch_hub_ep/screens/editscreens/edit_product_screen.dart';

class ProductTablePage extends StatefulWidget {
  const ProductTablePage({super.key});

  @override
  _ProductTablePageState createState() => _ProductTablePageState();
}

class _ProductTablePageState extends State<ProductTablePage> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  Map<String, dynamic> categories = {};
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  TextEditingController searchController = TextEditingController();
  String selectedBrand = 'All';
  String selectedCategory = 'All';
  double minPrice = 0;
  double maxPrice = 10000;
  String sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    fetchData();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });
      await fetchCategories();
      await fetchProducts();
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchCategories() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      Map<String, dynamic> catMap = {};
      for (var doc in snapshot.docs) {
        catMap[doc.id] = doc.data();
      }
      setState(() {
        categories = catMap;
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> fetchProducts() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('products').get();

      List<Map<String, dynamic>> productList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        if (data['brand'] is DocumentReference) {
          data['brand'] = (data['brand'] as DocumentReference).id;
        }

        if (data['categories'] is List) {
          data['categories'] =
              (data['categories'] as List)
                  .map((cat) => cat is DocumentReference ? cat.id : cat)
                  .toList();
        }

        productList.add(data);
      }

      setState(() {
        products = productList;
        filteredProducts = productList;
        isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Error fetching products: $e';
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(products);

    if (searchController.text.isNotEmpty) {
      filtered =
          filtered.where((product) {
            final searchTerm = searchController.text.toLowerCase();
            final title = (product['title'] ?? '').toString().toLowerCase();
            final subtitle =
                (product['subtitle'] ?? '').toString().toLowerCase();
            final brand = getBrandName(product['brand']).toLowerCase();
            return title.contains(searchTerm) ||
                subtitle.contains(searchTerm) ||
                brand.contains(searchTerm);
          }).toList();
    }

    if (selectedBrand != 'All') {
      filtered =
          filtered
              .where(
                (product) => getBrandName(product['brand']) == selectedBrand,
              )
              .toList();
    }

    if (selectedCategory != 'All') {
      filtered =
          filtered.where((product) {
            final categories = product['categories'] as List<dynamic>?;
            if (categories == null) return false;
            return categories.any(
              (catId) =>
                  this.categories[catId.toString()]?['Name'] ==
                  selectedCategory,
            );
          }).toList();
    }

    filtered =
        filtered.where((product) {
          final price = (product['price'] ?? 0.0).toDouble();
          return price >= minPrice && price <= maxPrice;
        }).toList();

    switch (sortBy) {
      case 'newest':
        filtered.sort((a, b) {
          final createdAtA = a['createdAt'];
          final createdAtB = b['createdAt'];

          DateTime dateA =
              createdAtA is Timestamp
                  ? createdAtA.toDate()
                  : DateTime.tryParse(createdAtA.toString()) ?? DateTime(1970);
          DateTime dateB =
              createdAtB is Timestamp
                  ? createdAtB.toDate()
                  : DateTime.tryParse(createdAtB.toString()) ?? DateTime(1970);

          return dateB.compareTo(dateA);
        });
        break;
      case 'oldest':
        filtered.sort((a, b) {
          final createdAtA = a['createdAt'];
          final createdAtB = b['createdAt'];

          DateTime dateA =
              createdAtA is Timestamp
                  ? createdAtA.toDate()
                  : DateTime.tryParse(createdAtA.toString()) ?? DateTime(1970);
          DateTime dateB =
              createdAtB is Timestamp
                  ? createdAtB.toDate()
                  : DateTime.tryParse(createdAtB.toString()) ?? DateTime(1970);

          return dateA.compareTo(dateB);
        });
        break;
      case 'priceAsc':
        filtered.sort((a, b) {
          double priceA = (a['price'] ?? 0.0).toDouble();
          double priceB = (b['price'] ?? 0.0).toDouble();
          return priceA.compareTo(priceB);
        });
        break;
      case 'priceDesc':
        filtered.sort((a, b) {
          double priceA = (a['price'] ?? 0.0).toDouble();
          double priceB = (b['price'] ?? 0.0).toDouble();
          return priceB.compareTo(priceA);
        });
        break;
      case 'nameAsc':
        filtered.sort((a, b) {
          String nameA = (a['title'] ?? '').toString();
          String nameB = (b['title'] ?? '').toString();
          return nameA.compareTo(nameB);
        });
        break;
      case 'nameDesc':
        filtered.sort((a, b) {
          String nameA = (a['title'] ?? '').toString();
          String nameB = (b['title'] ?? '').toString();
          return nameB.compareTo(nameA);
        });
        break;
    }

    setState(() {
      filteredProducts = filtered;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Filter Products'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Brand:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: selectedBrand,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setStateDialog(() {
                            selectedBrand = newValue!;
                          });
                        },
                        items: _getBrandOptions(),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Category:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setStateDialog(() {
                            selectedCategory = newValue!;
                          });
                        },
                        items: _getCategoryOptions(),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Price Range:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      RangeSlider(
                        values: RangeValues(minPrice, maxPrice),
                        min: 0,
                        max: 10000,
                        divisions: 100,
                        labels: RangeLabels(
                          '\$${minPrice.toStringAsFixed(0)}',
                          '\$${maxPrice.toStringAsFixed(0)}',
                        ),
                        onChanged: (RangeValues values) {
                          setStateDialog(() {
                            minPrice = values.start;
                            maxPrice = values.end;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Sort By:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: sortBy,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setStateDialog(() {
                            sortBy = newValue!;
                          });
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text('Newest First'),
                          ),
                          DropdownMenuItem(
                            value: 'oldest',
                            child: Text('Oldest First'),
                          ),
                          DropdownMenuItem(
                            value: 'priceAsc',
                            child: Text('Price: Low to High'),
                          ),
                          DropdownMenuItem(
                            value: 'priceDesc',
                            child: Text('Price: High to Low'),
                          ),
                          DropdownMenuItem(
                            value: 'nameAsc',
                            child: Text('Name: A to Z'),
                          ),
                          DropdownMenuItem(
                            value: 'nameDesc',
                            child: Text('Name: Z to A'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setStateDialog(() {
                      selectedBrand = 'All';
                      selectedCategory = 'All';
                      minPrice = 0;
                      maxPrice = 10000;
                      sortBy = 'newest';
                    });
                  },
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _applyFilters();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<DropdownMenuItem<String>> _getBrandOptions() {
    Set<String> brands = {'All'};
    for (var product in products) {
      brands.add(getBrandName(product['brand']));
    }
    return brands
        .map((brand) => DropdownMenuItem(value: brand, child: Text(brand)))
        .toList();
  }

  List<DropdownMenuItem<String>> _getCategoryOptions() {
    Set<String> categoryNames = {'All'};
    categories.forEach((key, value) {
      if (value['Name'] != null) {
        categoryNames.add(value['Name']);
      }
    });
    return categoryNames
        .map(
          (category) =>
              DropdownMenuItem(value: category, child: Text(category)),
        )
        .toList();
  }

  String getBrandName(String? brandId) {
    if (brandId == null || brandId.isEmpty) return 'No Brand';
    return categories[brandId]?['Name'] ?? 'Unknown Brand';
  }

  String getTypeNames(List<dynamic>? typeIds) {
    if (typeIds == null || typeIds.isEmpty) return 'No Types';

    List<String> typeNames = [];
    for (var typeId in typeIds) {
      String typeName = categories[typeId.toString()]?['Name'] ?? 'Unknown';
      typeNames.add(typeName);
    }

    return typeNames.join(', ');
  }

  String getCORSSafeImageUrl(String originalUrl) {
    if (originalUrl.startsWith('http://') ||
        originalUrl.startsWith('https://')) {
      Uri uri = Uri.parse(originalUrl);
      String filePath =
          uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
      return 'http://watch_hub_ep.atwebpages.com/cors_proxy.php?file=$filePath';
    }
    return 'http://watch_hub_ep.atwebpages.com/cors_proxy.php?file=$originalUrl';
  }

  void deleteProduct(String productId, String productTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete "$productTitle"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteProduct(productId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5B8A9A)),
                suffixIcon:
                    searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF5B8A9A)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Filter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B8A9A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          // Results Count
          // Text(
          //   '${filteredProducts.length} product${filteredProducts.length != 1 ? 's' : ''}',
          //   style: TextStyle(
          //     color: Colors.grey.shade600,
          //     fontSize: 14,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final imageList = (product['images'] as List?)?.cast<String>() ?? [];
final imageUrl = imageList.isNotEmpty ? imageList.first : null;
    return Card(
      color: Color(0xFFF8FAFC),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    
                    child:
                        product['images'] != null &&
                                (product['images'] as List).isNotEmpty
                            ? Image.network(
                              getCORSSafeImageUrl(product['images'][0]),
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                );
                              },
                            )
                            : const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product['subtitle'] != null &&
                          product['subtitle'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            product['subtitle'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Brand',
                          getBrandName(product['brand']),
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Stock',
                          '${product['inventoryCount'] ?? 0}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Rating',
                          '${product['averageRating']?.toStringAsFixed(1) ?? '0.0'} (${product['totalRatings'] ?? 0})',
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Categories',
                          getTypeNames(product['categories']),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (product['specs'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Specifications:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            spacing: 8,
                            runSpacing: 4,
                            children: _buildSpecsWidgets(product['specs']),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EditProductScreen(
                              product: product,
                              categories: categories,
                            ),
                      ),
                    ).then((result) {
                      if (result == true) {
                        fetchData();
                      }
                    });
                  },

                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4A90E2),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    deleteProduct(
                      product['id'],
                      product['title'] ?? 'Unknown Product',
                    );
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSpecsWidgets(dynamic specs) {
    if (specs == null) return [];

    List<Widget> widgets = [];

    try {
      if (specs is Map) {
        specs.forEach((key, value) {
          widgets.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF5B8A9A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${key.toString()}: ${value.toString()}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5B8A9A)),
              ),
            ),
          );
        });
      } else if (specs is List) {
        for (var spec in specs) {
          if (spec is Map) {
            spec.forEach((key, value) {
              widgets.add(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B8A9A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${key.toString()}: ${value.toString()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5B8A9A),
                    ),
                  ),
                ),
              );
            });
          } else {
            widgets.add(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B8A9A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  spec.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5B8A9A),
                  ),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF5B8A9A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Specs available',
            style: TextStyle(fontSize: 12, color: Color(0xFF5B8A9A)),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child:
                isLoading
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF5B8A9A)),
                          SizedBox(height: 16),
                          Text(
                            'Loading products...',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    )
                    : hasError
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: fetchData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : filteredProducts.isEmpty
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Color(0xFF6B7280),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Try adjusting your search or filters',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(filteredProducts[index]);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          ).then((_) {
            fetchData();
          });
        },
        backgroundColor: const Color(0xFF5B8A9A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

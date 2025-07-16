import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_hub_ep/screens/addscreens/add_category.dart';

class CategoryList extends StatefulWidget {
  const CategoryList({super.key});

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseReference categoryRef = FirebaseDatabase.instance.ref().child(
    "Category",
  );

  String _searchQuery = '';
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  String _filterBy = 'all';
  String _typeFilter = 'all'; // all, brand, type
  bool _isFilterApplied = false;

  // Helper method to safely convert type to int
  int _getTypeAsInt(dynamic type) {
    if (type is int) return type;
    if (type is String) return int.tryParse(type) ?? 1;
    return 1; // default to brand
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search categories...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value.toLowerCase());
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildIconButton(Icons.tune, _showSortDialog),
                const SizedBox(width: 10),
                _buildIconButton(Icons.filter_list, _showFilterDialog),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: categoryRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Something went wrong"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final Map<dynamic, dynamic>? categoriesMap =
                    snapshot.data?.snapshot.value as Map?;
                if (categoriesMap == null) {
                  return const Center(child: Text("No categories found"));
                }

                var categoryEntries = categoriesMap.entries.toList();

                // Search filter
                categoryEntries = categoryEntries.where((entry) {
                  final category = entry.value;
                  return category['Name']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery);
                }).toList();

                // Type filter
                if (_typeFilter != 'all') {
                  categoryEntries = categoryEntries.where((entry) {
                    final category = entry.value;
                    final type = _getTypeAsInt(category['type']);
                    return (_typeFilter == 'brand' && type == 1) ||
                        (_typeFilter == 'type' && type == 2);
                  }).toList();
                }

                // Filter by date
                if (_filterBy != 'all') {
                  categoryEntries = categoryEntries.where((entry) {
                    final createdDate = entry.value['createdAt'] ?? 0;
                    final createdDateTime = createdDate is int
                        ? DateTime.fromMillisecondsSinceEpoch(createdDate)
                        : DateTime.now();
                    final difference = DateTime.now().difference(createdDateTime).inDays;
                    return _filterBy == 'recent' ? difference <= 7 : difference > 7;
                  }).toList();
                }

                // Sort logic
                categoryEntries.sort((a, b) {
                  if (_sortBy == 'name') {
                    final nameA = a.value['Name'].toString().toLowerCase();
                    final nameB = b.value['Name'].toString().toLowerCase();
                    return _sortOrder == 'asc'
                        ? nameA.compareTo(nameB)
                        : nameB.compareTo(nameA);
                  } else if (_sortBy == 'type') {
                    final typeA = _getTypeAsInt(a.value['type']);
                    final typeB = _getTypeAsInt(b.value['type']);
                    return _sortOrder == 'asc'
                        ? typeA.compareTo(typeB)
                        : typeB.compareTo(typeA);
                  } else {
                    final dateA = a.value['createdAt'] ?? 0;
                    final dateB = b.value['createdAt'] ?? 0;
                    return _sortOrder == 'asc'
                        ? dateA.compareTo(dateB)
                        : dateB.compareTo(dateA);
                  }
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categoryEntries.length,
                  itemBuilder: (context, index) {
                    final categoryId = categoryEntries[index].key;
                    final category = categoryEntries[index].value;
                    final categoryType = _getTypeAsInt(category['type']);
                    final typeLabel = categoryType == 1 ? 'Brand' : 'Type';
                    final typeColor = categoryType == 1 ? Colors.blue : Colors.green;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category['Name'] ?? 'Untitled',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: typeColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        typeLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: typeColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    onPressed: () => _showEditDialog(
                                      categoryId,
                                      category,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () => _showDeleteDialog(
                                      categoryId,
                                      category['Name'],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                categoryType == 1 ? Icons.business : Icons.category,
                                color: typeColor,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                categoryType == 1 ? 'Brand Category' : 'Type Category',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.grey,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _getTimeAgo(category['createdAt']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5B8A9A),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCategoryScreen()),
          );
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _buildIconButton(IconData icon, void Function(BuildContext) onTap) {
    return Container(
      decoration: BoxDecoration(
        color: _isFilterApplied ? const Color(0xFF5B8A9A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: _isFilterApplied ? Colors.white : Colors.grey),
        onPressed: () => onTap(context),
      ),
    );
  }

  void _showEditDialog(String categoryId, Map category) {
    final controller = TextEditingController(text: category['Name']);
    bool isActive = category['isActive'] ?? true;
    int selectedType = _getTypeAsInt(category['type']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF5B8A9A),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(25),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text(
                              'Edit Category',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form Content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Basic Information Section
                              const Text(
                                'Basic Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Category Name Field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: const TextSpan(
                                      text: 'Category Name ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '*',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      hintText: 'Enter category name',
                                      filled: true,
                                      fillColor: const Color(0xFFF5F5F5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Category Type Field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: const TextSpan(
                                      text: 'Category Type ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '*',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: selectedType,
                                        hint: const Text('Select category type'),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 1,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.business,
                                                  color: Colors.blue,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Brand'),
                                              ],
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 2,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.category,
                                                  color: Colors.green,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Type'),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setModalState(() => selectedType = value);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 30),

                              // Status Section
                              const Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Active Status
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.toggle_on,
                                      color: Color(0xFF5B8A9A),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Active Status',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: isActive,
                                      onChanged: (value) {
                                        setModalState(() => isActive = value);
                                      },
                                      activeColor: const Color(0xFF5B8A9A),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Update Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5B8A9A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final name = controller.text.trim();
                                    if (name.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Category name is required'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    try {
                                      await categoryRef.child(categoryId).update({
                                        'Name': name,
                                        'isActive': isActive,
                                        'type': selectedType,
                                        'updatedAt': DateTime.now().millisecondsSinceEpoch,
                                      });

                                      if (mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Category updated successfully'),
                                            backgroundColor: Color(0xFF5B8A9A),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error updating category: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text(
                                    'Update Category',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(String categoryId, String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category"),
        content: Text("Are you sure you want to delete '$categoryName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await categoryRef.child(categoryId).remove();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category deleted successfully'),
                      backgroundColor: Color(0xFF5B8A9A),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting category: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sort Categories"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioTile("Sort by Name", 'name', _sortBy, (value) {
              setState(() => _sortBy = value!);
              _updateFilterStatus();
            }),
            _buildRadioTile("Sort by Type", 'type', _sortBy, (value) {
              setState(() => _sortBy = value!);
              _updateFilterStatus();
            }),
            _buildRadioTile("Sort by Date", 'date', _sortBy, (value) {
              setState(() => _sortBy = value!);
              _updateFilterStatus();
            }),
            const Divider(),
            _buildRadioTile("Ascending", 'asc', _sortOrder, (value) {
              setState(() => _sortOrder = value!);
              _updateFilterStatus();
            }),
            _buildRadioTile("Descending", 'desc', _sortOrder, (value) {
              setState(() => _sortOrder = value!);
              _updateFilterStatus();
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _sortBy = 'name';
                _sortOrder = 'asc';
                _updateFilterStatus();
              });
            },
            child: const Text("Reset"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B8A9A),
            ),
            child: const Text("Apply", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Filter Categories"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date filters
            const Text(
              'Filter by Date',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildRadioTile("All Categories", 'all', _filterBy, (value) {
              setState(() => _filterBy = value!);
              _updateFilterStatus();
            }),
            _buildRadioTile("Recent (Last 7 days)", 'recent', _filterBy, (value) {
              setState(() => _filterBy = value!);
              _updateFilterStatus();
            }),
            _buildRadioTile("Older (More than 7 days)", 'older', _filterBy, (value) {
              setState(() => _filterBy = value!);
              _updateFilterStatus();
            }),
            const Divider(),
            // Type filters
            const Text(
              'Filter by Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildRadioTile("All Types", 'all', _typeFilter, (value) {
              setState(() => _typeFilter = value!);
              _updateFilterStatus();
            }),
            _buildRadioTile("Brands Only", 'brand', _typeFilter, (value) {
              setState(() => _typeFilter = value!);
              _updateFilterStatus();
            }),
            _buildRadioTile("Types Only", 'type', _typeFilter, (value) {
              setState(() => _typeFilter = value!);
              _updateFilterStatus();
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterBy = 'all';
                _typeFilter = 'all';
                _updateFilterStatus();
              });
            },
            child: const Text("Reset"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B8A9A),
            ),
            child: const Text("Apply", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  ListTile _buildRadioTile(
    String title,
    String value,
    String group,
    void Function(String?) onChanged,
  ) {
    return ListTile(
      title: Text(title),
      leading: Radio<String>(
        value: value,
        groupValue: group,
        onChanged: onChanged,
      ),
    );
  }

  void _updateFilterStatus() {
    setState(() {
      _isFilterApplied = _sortBy != 'name' ||
          _sortOrder != 'asc' ||
          _filterBy != 'all' ||
          _typeFilter != 'all';
    });
  }

  String _getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return 'Unknown';
    
    try {
      final date = createdAt is int 
          ? DateTime.fromMillisecondsSinceEpoch(createdAt)
          : DateTime.now();
      return DateFormat('hh:mm a').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
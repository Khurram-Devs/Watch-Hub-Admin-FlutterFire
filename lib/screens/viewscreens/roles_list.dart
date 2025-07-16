import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_hub_ep/screens/addscreens/add_roles.dart';
import 'package:watch_hub_ep/screens/editscreens/edit_roles.dart';

class RoleListScreen extends StatefulWidget {
  const RoleListScreen({super.key});

  @override
  State<RoleListScreen> createState() => _RoleListScreenState();
}

class _RoleListScreenState extends State<RoleListScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseReference roleRef = FirebaseDatabase.instance.ref().child(
    "Roles",
  );

  late AnimationController _listAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  String _searchQuery = '';
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  String _levelFilter = 'all';
  bool _isFilterApplied = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _listAnimationController.forward();
    _fabAnimationController.forward();
  }

  int _getRoleLevelAsInt(dynamic level) {
    if (level == null) return 1;
    if (level is int) return level;
    if (level is String) return int.tryParse(level) ?? 1;
    return 1;
  }

  String _getRoleLevelLabel(int level) {
    switch (level) {
      case 1:
        return 'Super Admin';
      case 2:
        return 'Admin';
      case 3:
        return 'Moderator';
      case 4:
        return 'User';
      default:
        return 'Unknown';
    }
  }

  Color _getRoleLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleLevelIcon(int level) {
    switch (level) {
      case 1:
        return Icons.security;
      case 2:
        return Icons.admin_panel_settings;
      case 3:
        return Icons.supervisor_account;
      case 4:
        return Icons.person;
      default:
        return Icons.help;
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sort Options'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Sort by Name'),
                  leading: Radio<String>(
                    value: 'name',
                    groupValue: _sortBy,
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Sort by Level'),
                  leading: Radio<String>(
                    value: 'level',
                    groupValue: _sortBy,
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Sort by Created Date'),
                  leading: Radio<String>(
                    value: 'created',
                    groupValue: _sortBy,
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Ascending Order'),
                  value: _sortOrder == 'asc',
                  onChanged: (value) {
                    setState(() {
                      _sortOrder = value ? 'asc' : 'desc';
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Options'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Filter by Level:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: _levelFilter,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Levels')),
                    DropdownMenuItem(value: '1', child: Text('Super Admin')),
                    DropdownMenuItem(value: '2', child: Text('Admin')),
                    DropdownMenuItem(value: '3', child: Text('Moderator')),
                    DropdownMenuItem(value: '4', child: Text('User')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _levelFilter = value!;
                      _isFilterApplied = _levelFilter != 'all';
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _clearAllFilters();
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _levelFilter = 'all';
      _sortBy = 'name';
      _sortOrder = 'asc';
      _searchQuery = '';
      _searchController.clear();
      _isFilterApplied = false;
    });
  }

  List<MapEntry<String, dynamic>> _applyFilters(
    List<MapEntry<String, dynamic>> entries,
  ) {
    var filtered = entries;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((entry) {
            final role = entry.value;
            final name = (role['name'] ?? '').toString().toLowerCase();
            final description =
                (role['description'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) ||
                description.contains(_searchQuery);
          }).toList();
    }

    // Apply level filter
    if (_levelFilter != 'all') {
      filtered =
          filtered.where((entry) {
            final roleLevel = _getRoleLevelAsInt(entry.value['level']);
            return roleLevel.toString() == _levelFilter;
          }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      dynamic aValue, bValue;

      switch (_sortBy) {
        case 'name':
          aValue = (a.value['name'] ?? '').toString();
          bValue = (b.value['name'] ?? '').toString();
          break;
        case 'level':
          aValue = _getRoleLevelAsInt(a.value['level']);
          bValue = _getRoleLevelAsInt(b.value['level']);
          break;
        case 'created':
          aValue = a.value['createdAt'] ?? '';
          bValue = b.value['createdAt'] ?? '';
          break;
        default:
          aValue = (a.value['name'] ?? '').toString();
          bValue = (b.value['name'] ?? '').toString();
      }

      final comparison = aValue.compareTo(bValue);
      return _sortOrder == 'asc' ? comparison : -comparison;
    });

    return filtered;
  }

  Widget _buildRoleCard(
    String roleId,
    Map<dynamic, dynamic> role,
    int roleLevel,
    int activePermissions,
  ) {
    final roleName = (role['name'] ?? 'Unknown Role').toString();
    final roleDescription = (role['description'] ?? '').toString();
    final createdAt = role['createdAt'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToRoleDetail(roleId, role),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getRoleLevelColor(roleLevel),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getRoleLevelIcon(roleLevel),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleLevelColor(roleLevel),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getRoleLevelLabel(roleLevel),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, roleId, role),
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(
                                Icons.content_copy,
                                size: 16,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 8),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  createdAt != null
                      ? _formatCreatedAt(createdAt)
                      : 'Unknown time',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRoleDetail(String roleId, Map<dynamic, dynamic> role) {
    print('Navigate to role detail: $roleId');
  }

  String _formatCreatedAt(dynamic createdAt) {
    try {
      DateTime dateTime;

      if (createdAt is int) {
        // Firebase might store timestamps as integers (milliseconds since epoch)
        dateTime = DateTime.fromMillisecondsSinceEpoch(createdAt);
      } else if (createdAt is String) {
        dateTime = DateTime.parse(createdAt);
      } else {
        return 'Invalid time';
      }

      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid time';
    }
  }

  void _handleMenuAction(
    String action,
    String roleId,
    Map<dynamic, dynamic> role,
  ) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => EditRoleScreen(roleId: roleId, existingRole: role),
          ),
        );

        break;
      case 'duplicate':
        _duplicateRole(roleId, role);
        break;
      case 'delete':
        _confirmDeleteRole(roleId, role);
        break;
    }
  }

  void _duplicateRole(String roleId, Map<dynamic, dynamic> role) {
    final duplicatedRole = Map<String, dynamic>.from(role);
    duplicatedRole['name'] = '${role['name']} (Copy)';
    duplicatedRole['createdAt'] = DateTime.now().toIso8601String();

    roleRef
        .push()
        .set(duplicatedRole)
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Role duplicated successfully')),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error duplicating role: $error')),
          );
        });
  }

  void _confirmDeleteRole(String roleId, Map<dynamic, dynamic> role) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Role'),
            content: Text(
              'Are you sure you want to delete "${role['name']}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteRole(roleId);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _deleteRole(String roleId) {
    roleRef
        .child(roleId)
        .remove()
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Role deleted successfully')),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting role: $error')),
          );
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search Roles...',
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
                Row(
                  children: [
                    _buildIconButton(Icons.tune, (ctx) => _showSortDialog()),
                    const SizedBox(width: 10),
                    _buildIconButton(
                      Icons.filter_list,
                      (ctx) => _showFilterDialog(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Role List
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: roleRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF5B8A9A),
                      ),
                    ),
                  );
                }

                final data = snapshot.data?.snapshot.value;
                if (data == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No roles found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first role to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Safe type casting
                Map<String, dynamic> rolesMap = {};
                if (data is Map) {
                  rolesMap = Map<String, dynamic>.from(data);
                }

                var roleEntries = rolesMap.entries.toList();
                roleEntries = _applyFilters(roleEntries);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: roleEntries.length,
                  itemBuilder: (context, index) {
                    final roleId = roleEntries[index].key;
                    final role = roleEntries[index].value;
                    final roleLevel = _getRoleLevelAsInt(role['level']);
                    final permissions = role['permissions'] ?? {};
                    final activePermissions =
                        permissions.values
                            .where((value) => value == true)
                            .length;

                    return _buildRoleCard(
                      roleId,
                      role,
                      roleLevel,
                      activePermissions,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF5B8A9A),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddRoleScreen()),
            );
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

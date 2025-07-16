import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:watch_hub_ep/screens/addscreens/add_user.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  List<Map<String, dynamic>> roles = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;

  // Filter variables
  String? selectedFilterRole;
  bool? selectedFilterActiveStatus;
  bool isFilterApplied = false;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
    _fetchUsers();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchRoles() async {
    try {
      DatabaseEvent event = await _databaseReference.child('Roles').once();
      final data = event.snapshot.value;
      
      if (data != null) {
        final Map<String, dynamic> rolesData = Map<String, dynamic>.from(data as Map);
        List<Map<String, dynamic>> rolesList = [];
        
        rolesData.forEach((key, value) {
          Map<String, dynamic> role = Map<String, dynamic>.from(value as Map);
          role['key'] = key;
          rolesList.add(role);
        });
        
        setState(() {
          roles = rolesList;
        });
      }
    } catch (e) {
      print('Error fetching roles: $e');
    }
  }

  String _getRoleName(String? roleId) {
    if (roleId == null) return 'No Role';
    try {
      final role = roles.firstWhere((role) => role['key'] == roleId);
      return role['name'] ?? 'Unknown Role';
    } catch (e) {
      return 'Unknown Role';
    }
  }

  void _fetchUsers() async {
    try {
      DatabaseEvent event = await _databaseReference.child('admin').once();
      final data = event.snapshot.value;
      
      if (data != null) {
        final Map<String, dynamic> usersData = Map<String, dynamic>.from(data as Map);
        List<Map<String, dynamic>> usersList = [];
        
        usersData.forEach((key, value) {
          Map<String, dynamic> user = Map<String, dynamic>.from(value as Map);
          user['key'] = key; // Add the key for reference
          usersList.add(user);
        });
        
        setState(() {
          users = usersList;
          filteredUsers = usersList;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = users.where((user) {
        // Search filter
        String name = (user['name'] ?? '').toString().toLowerCase();
        String email = (user['email'] ?? '').toString().toLowerCase();
        String roleName = _getRoleName(user['roleId']).toLowerCase();
        bool matchesSearch = name.contains(query) || email.contains(query) || roleName.contains(query);
        
        // Role filter
        bool matchesRole = selectedFilterRole == null || user['roleId'] == selectedFilterRole;
        
        // Active status filter
        bool matchesActiveStatus = selectedFilterActiveStatus == null || (user['isActive'] ?? false) == selectedFilterActiveStatus;
        
        return matchesSearch && matchesRole && matchesActiveStatus;
      }).toList();
      
      // Update filter applied status
      isFilterApplied = selectedFilterRole != null || selectedFilterActiveStatus != null;
    });
  }

  void _showFilterDialog() {
    String? tempSelectedRole = selectedFilterRole;
    bool? tempSelectedActiveStatus = selectedFilterActiveStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Filter Users'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role Filter
                Text('Filter by Role:', style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: tempSelectedRole,
                      hint: Text('All Roles'),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Roles'),
                        ),
                        ...roles.map((role) {
                          return DropdownMenuItem<String>(
                            value: role['key'],
                            child: Text(role['name'] ?? 'Unknown Role'),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          tempSelectedRole = value;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Active Status Filter
                Text('Filter by Status:', style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<bool>(
                      value: tempSelectedActiveStatus,
                      hint: Text('All Status'),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem<bool>(
                          value: null,
                          child: Text('All Status'),
                        ),
                        DropdownMenuItem<bool>(
                          value: true,
                          child: Text('Active'),
                        ),
                        DropdownMenuItem<bool>(
                          value: false,
                          child: Text('Inactive'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          tempSelectedActiveStatus = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Clear all filters
                setState(() {
                  selectedFilterRole = null;
                  selectedFilterActiveStatus = null;
                });
                _applyFilters();
                Navigator.pop(context);
              },
              child: Text('Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedFilterRole = tempSelectedRole;
                  selectedFilterActiveStatus = tempSelectedActiveStatus;
                });
                _applyFilters();
                Navigator.pop(context);
              },
              child: Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteUser(String userKey) async {
    try {
      await _databaseReference.child('admin').child(userKey).remove();
      _fetchUsers(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      print('Error deleting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user')),
      );
    }
  }

  void _showEditDialog(Map<String, dynamic> user) {
    String? selectedRoleId = user['roleId'];
    bool isActive = user['isActive'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit User'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User: ${user['name'] ?? 'Unknown'}',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 16),
                
                // Role Dropdown
                Text('Role:', style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRoleId,
                      hint: Text('Select Role'),
                      isExpanded: true,
                      items: roles.map((role) {
                        return DropdownMenuItem<String>(
                          value: role['key'],
                          child: Text(role['name'] ?? 'Unknown Role'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedRoleId = value;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Active Status
                Row(
                  children: [
                    Text('Active Status:', style: TextStyle(fontWeight: FontWeight.w500)),
                    Spacer(),
                    Switch(
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() {
                          isActive = value;
                        });
                      },
                      activeColor: Color(0xFF4CAF50),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateUser(user['key'], selectedRoleId, isActive);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateUser(String userKey, String? roleId, bool isActive) async {
    try {
      Map<String, dynamic> updates = {
        'isActive': isActive,
      };
      
      if (roleId != null) {
        updates['roleId'] = roleId;
      }
      
      await _databaseReference.child('admin').child(userKey).update(updates);
      _fetchUsers(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User updated successfully')),
      );
    } catch (e) {
      print('Error updating user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user')),
      );
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp.toString()));
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return timestamp.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            color: Color(0xFFF5F5F5),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFFE0E0E0)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search users...',
                            hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                            prefixIcon: Icon(Icons.search, color: Color(0xFF9E9E9E)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isFilterApplied ? Color(0xFF5B7C8A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFE0E0E0)),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_list,
                          color: isFilterApplied ? Colors.white : Color(0xFF9E9E9E),
                        ),
                        onPressed: _showFilterDialog,
                      ),
                    ),
                  ],
                ),
                
                // Active filters display
                if (isFilterApplied) ...[
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (selectedFilterRole != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFF5B7C8A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Role: ${_getRoleName(selectedFilterRole)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedFilterRole = null;
                                    });
                                    _applyFilters();
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (selectedFilterActiveStatus != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFF5B7C8A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Status: ${selectedFilterActiveStatus! ? 'Active' : 'Inactive'}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedFilterActiveStatus = null;
                                    });
                                    _applyFilters();
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // User List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Color(0xFF5B7C8A)))
                : filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        user['fullName'] ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit, color: Color(0xFF2196F3), size: 20),
                                            onPressed: () {
                                              _showEditDialog(user);
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Color(0xFFFF5252), size: 20),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: Text('Delete User'),
                                                  content: Text('Are you sure you want to delete this user?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        _deleteUser(user['key']);
                                                      },
                                                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFE8F5E8),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getRoleName(user['roleId']),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF4CAF50),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (user['isActive'] ?? false) ? Color(0xFFE8F5E8) : Color(0xFFFFEBEE),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          (user['isActive'] ?? false) ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: (user['isActive'] ?? false) ? Color(0xFF4CAF50) : Color(0xFFFF5252),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  
                                  // User Details
                                  // _buildDetailRow(Icons.access_time, 'Created At', _formatTimestamp(user['createdAt'])),
                                  _buildDetailRow(Icons.email, 'Email', user['email'] ?? 'N/A'),
                                  _buildDetailRow(Icons.account_circle, 'Username', user['username'] ?? 'N/A'),
                                  _buildDetailRow(Icons.lock, 'Password', user['password'] ?? 'N/A'),
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>AddUserPage()),
            );
          },
        backgroundColor: Color(0xFF5B7C8A),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFF9E9E9E)),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
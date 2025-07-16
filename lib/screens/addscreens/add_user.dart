import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class AddUserPage extends StatefulWidget {
  @override
  _AddUserPageState createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController(); // Changed from loginId to username
  final _passwordController = TextEditingController();
  
  String? _selectedRole;
  String? _selectedRoleId;
  bool _isActive = true;
  bool _isLoading = false;
  
  // Firebase Database reference
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // Roles list from Firebase
  List<Map<String, dynamic>> _roles = [];
  
  // Store existing users data for validation
  List<Map<String, dynamic>> _existingUsers = [];

  @override
  void initState() {
    super.initState();
    _generateCredentials();
    _fetchRoles();
    _fetchExistingUsers();
  }

  // Fetch existing users from Firebase admin table
  Future<void> _fetchExistingUsers() async {
    try {
      final snapshot = await _database.child('admin').get();
      
      if (snapshot.exists) {
        final usersData = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> fetchedUsers = [];
        
        usersData.forEach((key, value) {
          final userMap = value as Map<dynamic, dynamic>;
          fetchedUsers.add({
            'id': key,
            'fullName': userMap['fullName']?.toString().toLowerCase() ?? '',
            'email': userMap['email']?.toString().toLowerCase() ?? '',
            'username': userMap['username']?.toString() ?? '',
          });
        });
        
        setState(() {
          _existingUsers = fetchedUsers;
        });
      }
    } catch (e) {
      print('Error fetching existing users: $e');
    }
  }

  // Check if name already exists
  bool _isNameExists(String name) {
    return _existingUsers.any((user) => 
      user['fullName'] == name.toLowerCase().trim()
    );
  }

  // Check if email already exists
  bool _isEmailExists(String email) {
    return _existingUsers.any((user) => 
      user['email'] == email.toLowerCase().trim()
    );
  }

  // Check if username already exists
  bool _isUsernameExists(String username) {
    return _existingUsers.any((user) => 
      user['username'] == username.toLowerCase().trim()
    );
  }

  // Fetch roles from Firebase Realtime Database
  Future<void> _fetchRoles() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final snapshot = await _database.child('Roles').get();
      
      if (snapshot.exists) {
        final rolesData = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> fetchedRoles = [];
        
        rolesData.forEach((key, value) {
          final roleMap = value as Map<dynamic, dynamic>;
          fetchedRoles.add({
            'id': key,
            'name': roleMap['name'] ?? 'Unknown Role',
            'level': roleMap['level']?.toString() ?? '',
            'description': roleMap['description'] ?? '',
          });
        });
        
        setState(() {
          _roles = fetchedRoles;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No roles found in database'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching roles: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _generateCredentials() {
    // Generate username from name (will be updated when name changes)
    String username = _nameController.text.toLowerCase().replaceAll(' ', '');
    if (username.isEmpty) {
      username = 'user${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
    _usernameController.text = username;
    
    // Generate random password
    String password = _generateRandomPassword();
    _passwordController.text = password;
  }

  // Generate username from full name
  void _generateUsernameFromName(String fullName) {
    String username = fullName.toLowerCase().replaceAll(' ', '').replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (username.isEmpty) {
      username = 'user${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
    
    // Check if username already exists and modify if needed
    String originalUsername = username;
    int counter = 1;
    while (_isUsernameExists(username)) {
      username = originalUsername + counter.toString();
      counter++;
    }
    
    _usernameController.text = username;
  }

  String _generateRandomPassword() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  void _regenerateCredentials() {
    _generateCredentials();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xFF6B9AC4),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add User',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Color(0xFF6B9AC4),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Color(0xFF6B9AC4),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Create New Admin User',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add admin details and assign permissions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Full Name Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
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
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 20,
                              color: Color(0xFF6B9AC4),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Full Name',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B9AC4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter full name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFF6B9AC4)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            // Auto-generate username when name changes
                            _generateUsernameFromName(value);
                            setState(() {});
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter full name';
                            }
                            if (_isNameExists(value)) {
                              return 'This name already exists';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Email Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
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
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 20,
                              color: Color(0xFF6B9AC4),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Email Address',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B9AC4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter email address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFF6B9AC4)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email address';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            if (_isEmailExists(value)) {
                              return 'This email already exists';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Role Selection
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
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
                          children: [
                            Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 20,
                              color: Color(0xFF6B9AC4),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Role',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B9AC4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            if (_isLoading)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B9AC4)),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRole,
                              hint: Text(_isLoading ? 'Loading roles...' : 'Select a role'),
                              icon: Icon(Icons.keyboard_arrow_down),
                              isExpanded: true,
                              items: _roles.map((role) {
                                return DropdownMenuItem<String>(
                                  value: role['name'],
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        role['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (role['description'] != null && role['description'].isNotEmpty)
                                        Text(
                                          role['description'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: _isLoading ? null : (String? newValue) {
                                setState(() {
                                  _selectedRole = newValue;
                                  _selectedRoleId = _roles.firstWhere(
                                    (role) => role['name'] == newValue,
                                  )['id'];
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Generated Credentials Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
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
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 20,
                              color: Color(0xFF6B9AC4),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Generated Credentials',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B9AC4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            TextButton.icon(
                              onPressed: _regenerateCredentials,
                              icon: Icon(Icons.refresh, size: 16),
                              label: Text('Regenerate'),
                              style: TextButton.styleFrom(
                                foregroundColor: Color(0xFF6B9AC4),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        
                        // Username
                        Text(
                          'Username',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _usernameController.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.copy, size: 16),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _usernameController.text));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Username copied to clipboard')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Password
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _passwordController.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.copy, size: 16),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _passwordController.text));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Password copied to clipboard')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Active Status
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.toggle_on,
                          size: 20,
                          color: Color(0xFF6B9AC4),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Active Status',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        Switch(
                          value: _isActive,
                          onChanged: (bool value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                          activeColor: Colors.white,
                          activeTrackColor: Color(0xFF4CAF50),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Create User Button
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6B9AC4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Create Admin User',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a role')),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Double-check for duplicates before creating user
        await _fetchExistingUsers();
        
        if (_isNameExists(_nameController.text)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This name already exists'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        if (_isEmailExists(_emailController.text)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This email already exists'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        if (_isUsernameExists(_usernameController.text)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This username already exists'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        // Create user object with correct structure for admin table
        Map<String, dynamic> newUser = {
          'fullName': _nameController.text,
          'email': _emailController.text,
          'username': _usernameController.text,
          'password': _passwordController.text,
          'role': _selectedRole, // Store role name directly
          'roleId': _selectedRoleId,
          'isActive': _isActive,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        };
        
        // Generate unique user ID
        String userId = _database.child('admin').push().key!;
        
        // Save user to Firebase Realtime Database admin table
        await _database.child('admin').child(userId).set(newUser);
        
        setState(() {
          _isLoading = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Admin user created successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate back with the new user data
        Navigator.pop(context, {...newUser, 'id': userId});
        
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error creating user: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
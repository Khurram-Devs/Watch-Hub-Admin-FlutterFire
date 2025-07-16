import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AddRoleScreen extends StatefulWidget {
  const AddRoleScreen({super.key});

  @override
  _AddRoleScreenState createState() => _AddRoleScreenState();
}

class _AddRoleScreenState extends State<AddRoleScreen>
    with SingleTickerProviderStateMixin {
  // Controllers and variables
  TextEditingController roleNameController = TextEditingController();
  TextEditingController roleDescriptionController = TextEditingController();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool isActive = true;
  bool isLoading = false;
  String selectedRoleLevel =
      "2"; // 2: Admin, 3: Moderator, 4: User (Super Admin removed)

  // Permission checkboxes
  Map<String, bool> permissions = {
    'manage_users': false,
    'manage_categories': false,
    'manage_products': false,
    'manage_orders': false,
    'manage_roles': false,
    'view_analytics': false,
    'system_settings': false,
    'content_management': false,
  };

  // Role level options (Super Admin removed)
  final List<Map<String, String>> roleLevels = [
    {"value": "2", "label": "Admin", "description": "Administrative access"},
    {"value": "3", "label": "Moderator", "description": "Content moderation"},
    {"value": "4", "label": "User", "description": "Basic user access"},
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Slide animation from bottom to top
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    // Scale animation for permissions
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Start animation when screen loads
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    roleNameController.dispose();
    roleDescriptionController.dispose();
    super.dispose();
  }

  // Helper method to get responsive padding
  EdgeInsets _getResponsivePadding(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 768) {
      return const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0);
    } else if (screenWidth > 480) {
      return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0);
    }
  }

  // Helper method to get responsive font size
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 768) {
      return baseSize * 1.2;
    } else if (screenWidth > 480) {
      return baseSize * 1.1;
    } else {
      return baseSize;
    }
  }

  // Helper method to get responsive icon size
  double _getResponsiveIconSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 768) {
      return baseSize * 1.3;
    } else if (screenWidth > 480) {
      return baseSize * 1.15;
    } else {
      return baseSize;
    }
  }

  void addRole() async {
    String roleName = roleNameController.text.trim();
    String roleDescription = roleDescriptionController.text.trim();

    if (roleName.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      try {
        DatabaseReference dr = FirebaseDatabase.instance.ref().child("Roles");

        // Adding the role to the database
        await dr.push().set({
          'name': roleName,
          'description': roleDescription,
          'level': selectedRoleLevel,
          'permissions': permissions,
          'isActive': isActive,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });

        // Show success animation
        _showSuccessAnimation();

        String levelLabel =
            roleLevels.firstWhere(
              (level) => level['value'] == selectedRoleLevel,
            )['label']!;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Role "$roleName" ($levelLabel) added successfully!',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: _getResponsivePadding(context),
          ),
        );

        // Clear the input fields
        roleNameController.clear();
        roleDescriptionController.clear();
        setState(() {
          isActive = true;
          selectedRoleLevel = "2"; // Reset to Admin (first available option)
          permissions.updateAll((key, value) => false);
        });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Failed to add role: $error',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: _getResponsivePadding(context),
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please enter a role name.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: _getResponsivePadding(context),
        ),
      );
    }
  }

  void _showSuccessAnimation() {
    _animationController.reset();
    _animationController.forward();
  }

  String _getPermissionLabel(String key) {
    switch (key) {
      case 'manage_users':
        return 'Manage Users';
      case 'manage_categories':
        return 'Manage Categories';
      case 'manage_products':
        return 'Manage Products';
      case 'manage_orders':
        return 'Manage Orders';
      case 'manage_roles':
        return 'Manage Roles';
      case 'view_analytics':
        return 'View Analytics';
      case 'system_settings':
        return 'System Settings';
      case 'content_management':
        return 'Content Management';
      default:
        return key;
    }
  }

  IconData _getPermissionIcon(String key) {
    switch (key) {
      case 'manage_users':
        return Icons.people;
      case 'manage_categories':
        return Icons.category;
      case 'manage_products':
        return Icons.inventory;
      case 'manage_orders':
        return Icons.shopping_cart;
      case 'manage_roles':
        return Icons.admin_panel_settings;
      case 'view_analytics':
        return Icons.analytics;
      case 'system_settings':
        return Icons.settings;
      case 'content_management':
        return Icons.content_paste;
      default:
        return Icons.security;
    }
  }

  // Helper method to get responsive spacing
  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 768) {
      return baseSpacing * 1.5;
    } else if (screenWidth > 480) {
      return baseSpacing * 1.2;
    } else {
      return baseSpacing;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool isTablet = screenWidth > 768;
    bool isLandscape = screenWidth > screenHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B8A9A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Role',
          style: TextStyle(
            color: Colors.white,
            fontSize: _getResponsiveFontSize(context, 20),
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: _getResponsivePadding(context),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 600 : double.infinity,
                    ),
                    child: Column(
                      children: [
                        // Header Icon and Title
                        Container(
                          width: _getResponsiveIconSize(context, 80),
                          height: _getResponsiveIconSize(context, 80),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B8A9A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              _getResponsiveIconSize(context, 40),
                            ),
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: _getResponsiveIconSize(context, 40),
                            color: const Color(0xFF5B8A9A),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSpacing(context, 20)),

                        Text(
                          'Create New Role',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 24),
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: _getResponsiveSpacing(context, 8)),

                        Text(
                          'Define permissions and access levels',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 16),
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: _getResponsiveSpacing(context, 30)),

                        // Role Level Selection
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveSpacing(context, 20),
                              vertical: _getResponsiveSpacing(context, 14),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selectedRoleLevel,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Role Level',
                                prefixIcon: Icon(
                                  Icons.security,
                                  color: const Color.fromARGB(
                                    255,
                                    86,
                                    102,
                                    107,
                                  ),
                                  size: _getResponsiveIconSize(context, 24),
                                ),
                                border: InputBorder.none,
                                labelStyle: TextStyle(
                                  color: const Color(0xFF5B8A9A),
                                  fontSize: _getResponsiveFontSize(context, 16),
                                ),
                              ),
                              dropdownColor: Colors.white,
                              itemHeight: null, // Allow dynamic height
                              isDense: false,
                              items:
                                  roleLevels.map((level) {
                                    return DropdownMenuItem<String>(
                                      value: level['value'],
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: _getResponsiveSpacing(
                                            context,
                                            8,
                                          ),
                                          horizontal: _getResponsiveSpacing(
                                            context,
                                            4,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              level['label']!,
                                              style: TextStyle(
                                                fontSize:
                                                    _getResponsiveFontSize(
                                                      context,
                                                      16,
                                                    ),
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            SizedBox(
                                              height: _getResponsiveSpacing(
                                                context,
                                                4,
                                              ),
                                            ),
                                            Text(
                                              level['description']!,
                                              style: TextStyle(
                                                fontSize:
                                                    _getResponsiveFontSize(
                                                      context,
                                                      12,
                                                    ),
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedRoleLevel = value!;
                                });
                              },
                              // Add custom styling for better mobile experience
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context, 16),
                                color: Colors.black87,
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: const Color(0xFF5B8A9A),
                                size: _getResponsiveIconSize(context, 28),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSpacing(context, 20)),

                        // Role Name Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: roleNameController,
                            decoration: InputDecoration(
                              labelText: 'Role Name',
                              hintText: 'e.g., Content Manager, Sales Admin',
                              prefixIcon: Icon(
                                Icons.badge,
                                color: const Color(0xFF5B8A9A),
                                size: _getResponsiveIconSize(context, 24),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(
                                _getResponsiveSpacing(context, 20),
                              ),
                              labelStyle: TextStyle(
                                color: const Color(0xFF5B8A9A),
                                fontSize: _getResponsiveFontSize(context, 16),
                              ),
                            ),
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 16),
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSpacing(context, 20)),

                        // Role Description Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: roleDescriptionController,
                            maxLines: isTablet ? 4 : 3,
                            decoration: InputDecoration(
                              labelText: 'Role Description',
                              hintText: 'Describe the role responsibilities...',
                              prefixIcon: Icon(
                                Icons.description,
                                color: const Color(0xFF5B8A9A),
                                size: _getResponsiveIconSize(context, 24),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(
                                _getResponsiveSpacing(context, 20),
                              ),
                              labelStyle: TextStyle(
                                color: const Color(0xFF5B8A9A),
                                fontSize: _getResponsiveFontSize(context, 16),
                              ),
                            ),
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 16),
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSpacing(context, 30)),

                        // Permissions Section
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                _getResponsiveSpacing(context, 20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lock,
                                        color: const Color(0xFF5B8A9A),
                                        size: _getResponsiveIconSize(
                                          context,
                                          24,
                                        ),
                                      ),
                                      SizedBox(
                                        width: _getResponsiveSpacing(
                                          context,
                                          10,
                                        ),
                                      ),
                                      Text(
                                        'Permissions',
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                            context,
                                            18,
                                          ),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: _getResponsiveSpacing(context, 20),
                                  ),

                                  // Responsive grid for permissions
                                  if (isTablet && !isLandscape)
                                    _buildPermissionsGrid(context, 2)
                                  else if (isTablet && isLandscape)
                                    _buildPermissionsGrid(context, 3)
                                  else
                                    _buildPermissionsList(context),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSpacing(context, 20)),

                        // Active Status Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              _getResponsiveSpacing(context, 16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isActive
                                          ? Icons.toggle_on
                                          : Icons.toggle_off,
                                      color:
                                          isActive ? Colors.green : Colors.grey,
                                      size: _getResponsiveIconSize(context, 24),
                                    ),
                                    SizedBox(
                                      width: _getResponsiveSpacing(context, 10),
                                    ),
                                    Text(
                                      'Active Status',
                                      style: TextStyle(
                                        fontSize: _getResponsiveFontSize(
                                          context,
                                          16,
                                        ),
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: isActive,
                                  onChanged: (value) {
                                    setState(() {
                                      isActive = value;
                                    });
                                  },
                                  activeColor: Colors.green,
                                  inactiveThumbColor: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSpacing(context, 30)),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: _getResponsiveSpacing(context, 55),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : addRole,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B8A9A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child:
                                isLoading
                                    ? SizedBox(
                                      width: _getResponsiveIconSize(
                                        context,
                                        20,
                                      ),
                                      height: _getResponsiveIconSize(
                                        context,
                                        20,
                                      ),
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          size: _getResponsiveIconSize(
                                            context,
                                            20,
                                          ),
                                        ),
                                        SizedBox(
                                          width: _getResponsiveSpacing(
                                            context,
                                            8,
                                          ),
                                        ),
                                        Text(
                                          'Create Role',
                                          style: TextStyle(
                                            fontSize: _getResponsiveFontSize(
                                              context,
                                              16,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSpacing(context, 20)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionsList(BuildContext context) {
    return Column(
      children:
          permissions.entries.map((entry) {
            return _buildPermissionItem(context, entry);
          }).toList(),
    );
  }

  Widget _buildPermissionsGrid(BuildContext context, int crossAxisCount) {
    List<MapEntry<String, bool>> permissionEntries =
        permissions.entries.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 4.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: permissionEntries.length,
      itemBuilder: (context, index) {
        return _buildPermissionItem(context, permissionEntries[index]);
      },
    );
  }

  Widget _buildPermissionItem(
    BuildContext context,
    MapEntry<String, bool> entry,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(bottom: _getResponsiveSpacing(context, 10)),
      decoration: BoxDecoration(
        color:
            entry.value
                ? const Color(0xFF5B8A9A).withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: entry.value ? const Color(0xFF5B8A9A) : Colors.transparent,
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        value: entry.value,
        onChanged: (bool? value) {
          setState(() {
            permissions[entry.key] = value ?? false;
          });
        },
        title: Row(
          children: [
            Icon(
              _getPermissionIcon(entry.key),
              color: entry.value ? const Color(0xFF5B8A9A) : Colors.grey,
              size: _getResponsiveIconSize(context, 20),
            ),
            SizedBox(width: _getResponsiveSpacing(context, 10)),
            Expanded(
              child: Text(
                _getPermissionLabel(entry.key),
                style: TextStyle(
                  fontWeight: entry.value ? FontWeight.w600 : FontWeight.normal,
                  fontSize: _getResponsiveFontSize(context, 14),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        activeColor: const Color(0xFF5B8A9A),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: EdgeInsets.symmetric(
          horizontal: _getResponsiveSpacing(context, 8),
          vertical: 0,
        ),
      ),
    );
  }
}
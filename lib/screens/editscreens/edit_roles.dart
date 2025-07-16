import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class EditRoleScreen extends StatefulWidget {
  final String roleId;
  final Map<dynamic, dynamic> existingRole;

  const EditRoleScreen({
    super.key,
    required this.roleId,
    required this.existingRole,
  });

  @override
  _EditRoleScreenState createState() => _EditRoleScreenState();
}

class _EditRoleScreenState extends State<EditRoleScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController roleNameController = TextEditingController();
  TextEditingController roleDescriptionController = TextEditingController();

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool isActive = true;
  bool isLoading = false;
  bool hasChanges = false;
  String selectedRoleLevel = "2";
  String originalRoleLevel = "2";

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

  Map<String, bool> originalPermissions = {};

  final List<Map<String, String>> roleLevels = [
    {"value": "2", "label": "Admin", "description": "Administrative access"},
    {"value": "3", "label": "Moderator", "description": "Content moderation"},
    {"value": "4", "label": "User", "description": "Basic user access"},
  ];

  @override
  void initState() {
    super.initState();
    _initializeWithExistingData();
    _initializeAnimations();
    _setupChangeListeners();
  }

  void _initializeWithExistingData() {
    roleNameController.text = widget.existingRole['name']?.toString() ?? '';
    roleDescriptionController.text = widget.existingRole['description']?.toString() ?? '';
    isActive = widget.existingRole['isActive'] ?? true;
    selectedRoleLevel = widget.existingRole['level']?.toString() ?? "2";
    originalRoleLevel = selectedRoleLevel;

    if (widget.existingRole['permissions'] != null) {
      Map<String, dynamic> existingPermissions =
          Map<String, dynamic>.from(widget.existingRole['permissions']);
      permissions.forEach((key, value) {
        permissions[key] = existingPermissions[key] ?? false;
      });
    }

    originalPermissions = Map.from(permissions);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  void _setupChangeListeners() {
    roleNameController.addListener(_checkForChanges);
    roleDescriptionController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    bool currentHasChanges = false;

    if (roleNameController.text != (widget.existingRole['name']?.toString() ?? '') ||
        roleDescriptionController.text != (widget.existingRole['description']?.toString() ?? '') ||
        selectedRoleLevel != originalRoleLevel ||
        isActive != (widget.existingRole['isActive'] ?? true)) {
      currentHasChanges = true;
    }

    for (String key in permissions.keys) {
      if (permissions[key] != originalPermissions[key]) {
        currentHasChanges = true;
        break;
      }
    }

    if (currentHasChanges != hasChanges) {
      setState(() {
        hasChanges = currentHasChanges;
      });
    }
  }

  void updateRole() async {
    String roleName = roleNameController.text.trim();
    String roleDescription = roleDescriptionController.text.trim();

    if (roleName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a role name.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref().child("Roles").child(widget.roleId);

      await ref.update({
        'name': roleName,
        'description': roleDescription,
        'level': selectedRoleLevel,
        'permissions': permissions,
        'isActive': isActive,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      _animationController.reset();
      _animationController.forward();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Role "$roleName" updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        hasChanges = false;
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update role: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: _getResponsivePadding(context),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildRoleLevelSelector() {
    return Padding(
      padding: _getResponsivePadding(context),
      child: DropdownButtonFormField<String>(
        value: selectedRoleLevel,
        decoration: const InputDecoration(
          labelText: 'Role Level',
          border: OutlineInputBorder(),
        ),
        items: roleLevels.map((level) {
          return DropdownMenuItem(
            value: level['value'],
            child: Text(level['label']!),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              selectedRoleLevel = value;
            });
            _checkForChanges();
          }
        },
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Padding(
      padding: _getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Permissions", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: permissions.keys.map((key) {
              return FilterChip(
                selected: permissions[key]!,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getPermissionIcon(key), size: 18),
                    const SizedBox(width: 4),
                    Text(_getPermissionLabel(key)),
                  ],
                ),
                onSelected: (value) {
                  setState(() {
                    permissions[key] = value;
                  });
                  _checkForChanges();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
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

  EdgeInsets _getResponsivePadding(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 768) return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    if (width > 480) return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  @override
  void dispose() {
    _animationController.dispose();
    roleNameController.dispose();
    roleDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B8A9A),
        title: const Text('Edit Role', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: hasChanges ? updateRole : null,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              _buildRoleLevelSelector(),
              _buildTextField(
                controller: roleNameController,
                label: 'Role Name',
                icon: Icons.badge,
                hint: 'Enter role name',
              ),
              _buildTextField(
                controller: roleDescriptionController,
                label: 'Description',
                icon: Icons.description,
                hint: 'Enter description',
                maxLines: 3,
              ),
              _buildPermissionsSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

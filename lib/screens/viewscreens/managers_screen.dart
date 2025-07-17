import 'package:flutter/material.dart';
import 'package:watch_hub_ep/widgets/managers/manager_form_dialog.dart';
import '../../models/admin_model.dart';
import '../../services/admin_service.dart';

class ManagersScreen extends StatefulWidget {
  const ManagersScreen({super.key});

  @override
  State<ManagersScreen> createState() => _ManagersScreenState();
}

class _ManagersScreenState extends State<ManagersScreen> {
  List<AdminModel> _managers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadManagers();
  }

  Future<void> _loadManagers() async {
    setState(() => _isLoading = true);
    _managers = await AdminService.fetchManagers();
    setState(() => _isLoading = false);
  }

  void _openForm({AdminModel? manager, String? docId}) {
    showDialog(
      context: context,
      builder: (_) => ManagerFormDialog(
        manager: manager,
        docId: docId,
        onSaved: _loadManagers,
      ),
    );
  }

  Future<void> _deleteManager(String docId) async {
    final confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this manager?"),
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

    if (confirmed == true) {
      await AdminService.deleteManager(docId);
      _loadManagers();
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER ADMIN':
        return Colors.redAccent;
      case 'PRODUCT MANAGER':
        return Colors.deepPurple;
      case 'BRANDS MANAGER':
        return Colors.teal;
      case 'CUSTOMER SERVICE':
        return Colors.orange;
      case 'ORDERS MANAGER':
        return Colors.lightGreen;
      default:
        return Colors.grey;
    }
  }

  Widget _buildManagerCard(AdminModel m, String? docId) {
    final roleColor = _getRoleColor(m.role);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            const Icon(Icons.person, size: 40, color: Colors.deepPurple),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.id,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      m.role.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _openForm(manager: m, docId: docId),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: docId == null ? null : () => _deleteManager(docId!),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 100),
              itemCount: _managers.length,
              itemBuilder: (context, index) {
                final m = _managers[index];
                return FutureBuilder<String?>(
                  future: AdminService.getDocIdByAdminId(m.id),
                  builder: (context, snapshot) {
                    return _buildManagerCard(m, snapshot.data);
                  },
                );
              },
            ),
    );
  }
}

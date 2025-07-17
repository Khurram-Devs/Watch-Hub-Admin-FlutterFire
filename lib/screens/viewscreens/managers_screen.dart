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
      builder:
          (_) => ManagerFormDialog(
            manager: manager,
            docId: docId,
            onSaved: _loadManagers,
          ),
    );
  }

  Future<void> _deleteManager(String docId) async {
    final confirmed = await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text(
              "Are you sure you want to delete this manager?",
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Managers")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _managers.length,
                itemBuilder: (context, index) {
                  final m = _managers[index];
                  return FutureBuilder(
                    future: AdminService.getDocIdByAdminId(m.id),
                    builder: (_, snapshot) {
                      final docId = snapshot.data;
                      return ListTile(
                        title: Text(m.id),
                        subtitle: Text(m.role),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed:
                                  () => _openForm(manager: m, docId: docId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed:
                                  docId == null
                                      ? null
                                      : () => _deleteManager(docId!),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}

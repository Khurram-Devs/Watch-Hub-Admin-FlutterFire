import 'package:flutter/material.dart';
import '../../models/admin_model.dart';
import '../../services/admin_service.dart';

class ManagerFormDialog extends StatefulWidget {
  final AdminModel? manager;
  final String? docId;
  final VoidCallback onSaved;

  const ManagerFormDialog({
    super.key,
    this.manager,
    this.docId,
    required this.onSaved,
  });

  @override
  State<ManagerFormDialog> createState() => _ManagerFormDialogState();
}

class _ManagerFormDialogState extends State<ManagerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSaving = false;
  String? _selectedRole;
  @override
  void initState() {
    super.initState();
    if (widget.manager != null) {
      _idController.text = widget.manager!.id;
      _passwordController.text = widget.manager!.password;
      _selectedRole = widget.manager!.role;
    } else {
      _selectedRole = 'SUPER ADMIN';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final manager = AdminModel(
      id: _idController.text.trim(),
      password: _passwordController.text.trim(),
      role: _selectedRole!,
      createdAt: widget.manager?.createdAt ?? DateTime.now(),
    );

    if (widget.docId != null) {
      await AdminService.updateManager(widget.docId!, manager);
    } else {
      await AdminService.createManager(manager);
    }

    widget.onSaved();
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.manager == null ? 'Add Manager' : 'Edit Manager'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'Manager ID'),
              validator:
                  (val) =>
                      val == null || val.isEmpty ? 'Enter Manager ID' : null,
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator:
                  (val) => val == null || val.isEmpty ? 'Enter Password' : null,
            ),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(
                  value: 'PRODUCT MANAGER',
                  child: Text('Product Manager'),
                ),
                DropdownMenuItem(
                  value: 'BRANDS MANAGER',
                  child: Text('Brands Manager'),
                ),
                DropdownMenuItem(
                  value: 'CUSTOMER SERVICE',
                  child: Text('Customer Service'),
                ),
                DropdownMenuItem(
                  value: 'ORDERS MANAGER',
                  child: Text('Orders Manager'),
                ),
                DropdownMenuItem(
                  value: 'SUPER ADMIN',
                  child: Text('Super Admin'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child:
              _isSaving
                  ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Save'),
        ),
      ],
    );
  }
}

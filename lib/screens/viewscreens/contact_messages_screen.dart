import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/contact_message_model.dart';
import '../../services/contact_message_service.dart';
import '../../widgets/layout/app_drawer.dart';
import '../../widgets/layout/app_bottom_navbar.dart';

class ContactMessagesScreen extends StatefulWidget {
  const ContactMessagesScreen({super.key});

  @override
  State<ContactMessagesScreen> createState() => _ContactMessagesScreenState();
}

class _ContactMessagesScreenState extends State<ContactMessagesScreen> {
  List<ContactMessageModel> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final msgs = await ContactMessageService.fetchAll();
    setState(() {
      _messages = msgs;
      _isLoading = false;
    });
  }

  Future<void> _delete(ContactMessageModel message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Message"),
        content: Text("Delete message from ${message.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirm == true) {
      await ContactMessageService.delete(message.id);
      _loadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? const Center(child: Text("No contact messages found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(msg.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 6),
                            Text(msg.message),
                            const SizedBox(height: 8),
                            Text(timeago.format(msg.createdAt.toDate()), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _delete(msg),
                        ),
                      ),
                    );
                  },
                ),
 
    );
  }
}

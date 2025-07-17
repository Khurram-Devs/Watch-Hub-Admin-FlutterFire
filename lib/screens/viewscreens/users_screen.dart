import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:watch_hub_ep/models/user_model.dart';
import 'package:watch_hub_ep/services/user_service.dart';
import 'package:watch_hub_ep/widgets/layout/app_drawer.dart';
import 'package:watch_hub_ep/widgets/layout/app_bottom_navbar.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    _users = await UserService.fetchAll();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text("No users found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(u.avatarUrl),
                        ),
                        title: Text(u.fullName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Email: ${u.email}"),
                            Text("Phone: ${u.phone}"),
                            Text("Occupation: ${u.occupation}"),
                            Text("Joined: ${timeago.format(u.createdAt.toDate())}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

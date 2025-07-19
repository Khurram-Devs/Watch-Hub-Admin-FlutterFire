import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onLogoutTapped;

  const AppDrawer({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onLogoutTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView.builder(
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == items.length) {
            return ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: onLogoutTapped,
            );
          }
          return ListTile(
            leading: Icon(items[index]['icon']),
            title: Text(items[index]['title']),
            selected: index == selectedIndex,
            onTap: () => onItemTapped(index),
          );
        },
      ),
    );
  }
}

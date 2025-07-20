import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_hub_ep/main.dart';

class AdminLayout extends StatelessWidget {
  final String title;
  final int? drawerIndex;
  final int? bottomNavIndex;
  final Widget body;
  final String role;

  final int unseenOrders;
  final int unseenMessages;

  const AdminLayout({
    super.key,
    required this.title,
    required this.drawerIndex,
    required this.bottomNavIndex,
    required this.body,
    required this.role,
    this.unseenOrders = 0,
    this.unseenMessages = 0,
  });

  Future<void> _onDrawerTap(BuildContext context, int index) async {
    switch (index) {
      case 0:
        context.go('/products');
        break;
      case 1:
        context.go('/categories');
        break;
      case 2:
        context.go('/testimonials');
        break;
      case 3:
        context.go('/contact-messages');
        break;
      case 4:
        context.go('/faq');
        break;
      case 5:
        context.go('/codes');
        break;
      case 6:
        context.go('/users');
        break;
      case 7:
        context.go('/orders');
        break;
      case 8:
        context.go('/managers');
        break;
      case 99:
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('role');
        currentAdminRole = null;
        loginStateNotifier.value = false;
        if (context.mounted) {
          context.go('/login');
        }
        break;
    }
  }

  void _onBottomTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/orders');
        break;
      case 2:
        context.go('/products');
        break;
      case 3:
        context.go('/users');
        break;
    }
  }

  bool _canAccess(int index) {
    switch (index) {
      case 0:
        return role == 'SUPER ADMIN' || role == 'PRODUCT MANAGER';
      case 1:
        return role == 'SUPER ADMIN' || role == 'CATEGORY MANAGER';
      case 2:
      case 3:
        return role == 'SUPER ADMIN' || role == 'CUSTOMER SERVICE';
      case 4:
      case 5:
        return role == 'SUPER ADMIN' || role == 'PRODUCT MANAGER';
      case 6:
      case 8:
        return role == 'SUPER ADMIN';
      case 7:
        return role == 'SUPER ADMIN' ||
            role == 'ORDERS MANAGER' ||
            role == 'CUSTOMER SERVICE';
      default:
        return true;
    }
  }

  List<Map<String, dynamic>> _getBottomNavTabs() {
    final tabs = <Map<String, dynamic>>[];

    if (role == 'SUPER ADMIN') {
      tabs.add({
        'index': 0,
        'icon': Icons.dashboard,
        'label': 'Dashboard',
      });
      tabs.add({
        'index': 2,
        'icon': Icons.watch,
        'label': 'Products',
      });
      tabs.add({
        'index': 1,
        'icon': Icons.receipt,
        'label': 'Orders',
      });
      tabs.add({'index': 6, 'icon': Icons.people, 'label': 'Users'}); // /users
    }

    else if (role == 'PRODUCT MANAGER') {
      tabs.add({'index': 0, 'icon': Icons.dashboard, 'label': 'Dashboard'});
      tabs.add({'index': 2, 'icon': Icons.watch, 'label': 'Products'});
      tabs.add({'index': 4, 'icon': Icons.question_answer, 'label': 'FAQ'});
      tabs.add({'index': 5, 'icon': Icons.discount, 'label': 'Promo Codes'});
    }

    else if (role == 'CATEGORY MANAGER') {
      tabs.add({'index': 0, 'icon': Icons.dashboard, 'label': 'Dashboard'});
      tabs.add({'index': 1, 'icon': Icons.category, 'label': 'Categories'});
      tabs.add({'index': 4, 'icon': Icons.question_answer, 'label': 'FAQ'});
    }

    else if (role == 'CUSTOMER SERVICE') {
      tabs.add({'index': 0, 'icon': Icons.dashboard, 'label': 'Dashboard'});
      tabs.add({'index': 2, 'icon': Icons.reviews, 'label': 'Testimonials'});
      tabs.add({'index': 3, 'icon': Icons.message, 'label': 'Messages'});
    }

    else if (role == 'ORDERS MANAGER') {
      tabs.add({'index': 0, 'icon': Icons.dashboard, 'label': 'Dashboard'});
      tabs.add({'index': 1, 'icon': Icons.receipt, 'label': 'Orders'});
      tabs.add({'index': 6, 'icon': Icons.people, 'label': 'Users'});
      tabs.add({'index': 3, 'icon': Icons.message, 'label': 'Messages'});
    }

    return tabs.take(4).toList();
  }

  int _getBottomNavIndex(int? rawIndex) {
    final tabs = _getBottomNavTabs();
    if (rawIndex == null) return 0;
    final tabIndex = tabs.indexWhere((tab) => tab['index'] == rawIndex);
    return tabIndex != -1 ? tabIndex : 0;
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    int index, {
    int badgeCount = 0,
  }) {
    if (index != 99 && !_canAccess(index)) return const SizedBox.shrink();
    final isSelected = drawerIndex == index;

    final iconWidget =
        badgeCount > 0
            ? badges.Badge(
              badgeContent: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              position: badges.BadgePosition.topEnd(top: -12, end: -6),
              child: Icon(icon),
            )
            : Icon(icon);

    return ListTile(
      selected: isSelected,
      selectedTileColor: const Color(0xFF5B8A9A),
      leading: iconWidget,
      title: Text(title),
      onTap: () => _onDrawerTap(context, index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _getBottomNavTabs();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(title),
            const Spacer(),
            if (unseenOrders > 0)
              badges.Badge(
                badgeContent: Text(
                  '$unseenOrders',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                position: badges.BadgePosition.topEnd(top: 0, end: 0),
                child: const Icon(Icons.notifications),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF5B8A9A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 100,
              color: const Color(0xFFA2CBDA),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Admin Panel',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    role,
                    style: TextStyle(
                      color:
                          role.toUpperCase() == 'SUPER ADMIN'
                              ? Colors.redAccent
                              : role.toUpperCase() == 'PRODUCT MANAGER'
                              ? Colors.deepPurple
                              : role.toUpperCase() == 'CATEGORY MANAGER'
                              ? Colors.teal
                              : role.toUpperCase() == 'CUSTOMER SERVICE'
                              ? Colors.orange
                              : role.toUpperCase() == 'ORDERS MANAGER'
                              ? Colors.lightGreen
                              : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            _buildDrawerItem(context, 'Products', Icons.watch, 0),
            _buildDrawerItem(
              context,
              'Categories',
              Icons.branding_watermark,
              1,
            ),
            _buildDrawerItem(context, 'Testimonials', Icons.reviews, 2),
            _buildDrawerItem(
              context,
              'Contact Messages',
              Icons.message,
              3,
              badgeCount: unseenMessages,
            ),
            _buildDrawerItem(context, 'Product FAQs', Icons.question_answer, 4),
            _buildDrawerItem(context, 'Promo Codes', Icons.discount, 5),
            _buildDrawerItem(context, 'Users', Icons.people, 6),
            _buildDrawerItem(
              context,
              'Orders',
              Icons.receipt,
              7,
              badgeCount: unseenOrders,
            ),
            _buildDrawerItem(
              context,
              'Managers',
              Icons.supervised_user_circle_sharp,
              8,
              badgeCount: unseenOrders,
            ),
            const Divider(),
            _buildDrawerItem(context, 'Logout', Icons.logout, 99),
          ],
        ),
      ),
      body: body,
      bottomNavigationBar:
          tabs.length >= 2
              ? BottomNavigationBar(
                currentIndex: _getBottomNavIndex(bottomNavIndex),
                onTap: (i) {
                  if (i < tabs.length) {
                    _onBottomTap(context, tabs[i]['index']);
                  }
                },
                selectedItemColor: const Color(0xFF5B8A9A),
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                items:
                    tabs.map((tab) {
                      return BottomNavigationBarItem(
                        icon: Icon(tab['icon'] as IconData),
                        label: tab['label'] as String,
                      );
                    }).toList(),
              )
              : null,
    );
  }
}

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
        context.go('/brands');
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

      case 99: // Logout
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
        return role == 'SUPER ADMIN' || role == 'BRANDS MANAGER';
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
              child: Icon(icon),
              position: badges.BadgePosition.topEnd(top: -12, end: -6),
            )
            : Icon(icon);

    return ListTile(
      selected: isSelected,
      selectedTileColor: Color(0xFF5B8A9A),
      leading: iconWidget,
      title: Text(title),
      onTap: () => _onDrawerTap(context, index),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Color(0xFF5B8A9A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF5B8A9A)),
              child: Text(
                'Admin Panel',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            _buildDrawerItem(context, 'Products', Icons.watch, 0),
            _buildDrawerItem(context, 'Brands', Icons.branding_watermark, 1),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex:
            (bottomNavIndex != null &&
                    bottomNavIndex! >= 0 &&
                    bottomNavIndex! < 4)
                ? bottomNavIndex!
                : 0,
        onTap: (i) => _onBottomTap(context, i),
        selectedItemColor: Color(0xFF5B8A9A),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.watch), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        ],
      ),
    );
  }
}

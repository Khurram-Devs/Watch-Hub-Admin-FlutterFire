import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_hub_ep/extra/order.dart';
import 'package:watch_hub_ep/screens/viewscreens/category_list.dart';
import 'package:watch_hub_ep/screens/viewscreens/dashboard.dart';
// import 'package:watch_hub_ep/screens/viewscreens/product_list.dart';
import 'package:watch_hub_ep/screens/viewscreens/profile_screen.dart';
import 'package:watch_hub_ep/screens/viewscreens/roles_list.dart';
import 'package:watch_hub_ep/screens/viewscreens/user_list.dart';
import 'package:watch_hub_ep/widgets/layout/app_bottom_navbar.dart';
import 'package:watch_hub_ep/widgets/layout/app_drawer.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int selectedDrawerIndex = -1;
  int selectedBottomNavIndex = 0;
  Widget _currentPage = const Dashboard();

  final List<Map<String, dynamic>> drawerItems = [
    {'icon': Icons.dashboard, 'title': 'Dashboard'},
    {'icon': Icons.security, 'title': 'Roles & Permissions'},
    {'icon': Icons.inventory_2, 'title': 'Products'},
    {'icon': Icons.category, 'title': 'Categories'},
    {'icon': Icons.group, 'title': 'Customers'},
    {'icon': Icons.person, 'title': 'Users'},
    {'icon': Icons.rate_review, 'title': 'Product Reviews'},
  ];

  final List<Widget> _bottomNavPages = [
    const Dashboard(),
    // ProductTablePage(),
    const OrdersPage(),
    AdminProfilePage(),
  ];

  final List<String> _bottomNavTitles = [
    'Dashboard',
    'Product List',
    'Orders',
    'Profile',
  ];

  final Map<String, Widget> _drawerPages = {
    'Dashboard': const Dashboard(),
    'Roles & Permissions': const RoleListScreen(),
    // 'Products': ProductTablePage(),
    'Categories': const CategoryList(),
    'Users': UserListPage(),
  };

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performLogout();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  Future<void> _performLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      setState(() {
        selectedDrawerIndex = -1;
        selectedBottomNavIndex = 0;
        _currentPage = const Dashboard();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      selectedBottomNavIndex = index;
      selectedDrawerIndex = -1;
      _currentPage = _bottomNavPages[index];
    });
  }

  void _onDrawerItemTapped(int index) {
    String pageTitle = drawerItems[index]['title'];
    Widget? page = _drawerPages[pageTitle];
    if (page != null) {
      setState(() {
        selectedDrawerIndex = index;
        selectedBottomNavIndex = -1;
        _currentPage = page;
      });
    }
    Navigator.pop(context);
  }

  String _getAppBarTitle() {
    if (selectedDrawerIndex != -1 && selectedDrawerIndex < drawerItems.length) {
      return drawerItems[selectedDrawerIndex]['title'];
    }
    if (selectedBottomNavIndex != -1 &&
        selectedBottomNavIndex < _bottomNavTitles.length) {
      return _bottomNavTitles[selectedBottomNavIndex];
    }
    return 'watch_hub_ep';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: const Color(0xFF5B8A9A),
        foregroundColor: Colors.white,
        elevation: 1,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: AppDrawer(
        items: drawerItems,
        selectedIndex: selectedDrawerIndex,
        onItemTapped: _onDrawerItemTapped,
        onLogoutTapped: _showLogoutDialog,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder:
            (child, animation) =>
                FadeTransition(opacity: animation, child: child),
        child: _currentPage,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: selectedBottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}

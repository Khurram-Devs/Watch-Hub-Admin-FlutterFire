import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_hub_ep/extra/order.dart';
import 'package:watch_hub_ep/screens/viewscreens/category_list.dart';
import 'package:watch_hub_ep/screens/viewscreens/dashboard.dart';
import 'package:watch_hub_ep/screens/viewscreens/product_list.dart';
import 'package:watch_hub_ep/screens/viewscreens/profile_screen.dart';
import 'package:watch_hub_ep/screens/viewscreens/roles_list.dart';
import 'package:watch_hub_ep/screens/viewscreens/user_list.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool isDarkMode = false;
  int selectedDrawerIndex = -1; // -1 means no drawer item selected
  int selectedBottomNavIndex = 0;
  Widget _currentPage = const Dashboard(); // Default to Home

  // Drawer items configuration
  final List<Map<String, dynamic>> drawerItems = [
    {'icon': Icons.dashboard, 'title': 'Dashboard'},
    {'icon': Icons.security, 'title': 'Roles & Permissions'},
    {'icon': Icons.inventory_2, 'title': 'Products'},
    {'icon': Icons.category, 'title': 'Categories'},
    {'icon': Icons.group, 'title': 'Customers'},
    {'icon': Icons.person, 'title': 'Users'},
    {'icon': Icons.rate_review, 'title': 'Product Reviews'},
  ];

  // Bottom navigation pages
  final List<Widget> _bottomNavPages = [
    const Dashboard(), // Home tab
    ProductTablePage(), // Analytics tab
    const OrdersPage(), // Orders tab
    AdminProfilePage(), // Settings tab
  ];

  // Bottom navigation titles
  final List<String> _bottomNavTitles = [
    'Dashboard',
    'Product List',
    'Orders',
    'Profile',
  ];

  // Drawer pages map
  final Map<String, Widget> _drawerPages = {
    'Dashboard': const Dashboard(),
    'Roles & Permissions':
        const RoleListScreen(), // Replace with your actual Roles widget
    'Products': ProductTablePage(), // Assuming ProductTablePage is non-const
    'Categories': const CategoryList(),
    // 'Customers': const CustomersPage(),            // Replace with your actual Customers widget
    'Users': UserListPage(), // Replace with your actual Users widget
    // 'Product Reviews': const ReviewsPage(),        // Replace with your actual Reviews widget
  };

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _performLogout();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() async {
    try {
      // Clear SharedPreferences (all stored data)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear any Firebase Auth session
      // await FirebaseAuth.instance.signOut();

      // Clear any other authentication tokens or user data
      // AuthService.clearToken();
      // UserService.clearUserData();

      // Reset app state
      setState(() {
        selectedDrawerIndex = -1;
        selectedBottomNavIndex = 0;
        _currentPage = const Dashboard();
        isDarkMode = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Navigate to login screen and clear entire navigation stack
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login', // Replace with your login route
          (Route<dynamic> route) => false,
        );
      }

      // Alternative if you don't have named routes:
      // if (mounted) {
      //   Navigator.of(context).pushAndRemoveUntil(
      //     MaterialPageRoute(builder: (context) => LoginScreen()),
      //     (Route<dynamic> route) => false,
      //   );
      // }
    } catch (e) {
      // Handle logout errors
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
      selectedDrawerIndex = -1; // Clear drawer selection
      _currentPage = _bottomNavPages[index];
    });
  }

  void _onDrawerItemTapped(int index) {
    String pageTitle = drawerItems[index]['title'];
    Widget? page = _drawerPages[pageTitle];

    if (page != null) {
      setState(() {
        selectedDrawerIndex = index;
        selectedBottomNavIndex = -1; // Clear bottom nav selection
        _currentPage = page;
      });
    }
    Navigator.pop(context); // Close drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black87 : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor:
            isDarkMode
                ? const Color.fromARGB(221, 255, 255, 255)
                : const Color(0xFF5B8A9A),
        foregroundColor: isDarkMode ? Colors.white : Colors.white,
        elevation: 1,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: _buildDrawer(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _currentPage,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  String _getAppBarTitle() {
    // If drawer item is selected, show its title
    if (selectedDrawerIndex != -1 && selectedDrawerIndex < drawerItems.length) {
      return drawerItems[selectedDrawerIndex]['title'];
    }
    // If bottom nav item is selected, show its title
    if (selectedBottomNavIndex != -1 &&
        selectedBottomNavIndex < _bottomNavTitles.length) {
      return _bottomNavTitles[selectedBottomNavIndex];
    }
    return 'watch_hub_ep';
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: isDarkMode ? Colors.black87 : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.watch, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'watch_hub_ep',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Menu List
            Expanded(
              child: ListView.builder(
                itemCount: drawerItems.length,
                itemBuilder: (context, index) {
                  bool isSelected = selectedDrawerIndex == index;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF5B8A9A).withOpacity(0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.0),
                      border:
                          isSelected
                              ? Border.all(
                                color: const Color(0xFF5B8A9A),
                                width: 1.0,
                              )
                              : null,
                    ),
                    child: ListTile(
                      leading: Icon(
                        drawerItems[index]['icon'],
                        color:
                            isSelected
                                ? const Color(0xFF5B8A9A)
                                : (isDarkMode
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade600),
                      ),
                      title: Text(
                        drawerItems[index]['title'],
                        style: TextStyle(
                          color:
                              isSelected
                                  ? const Color(0xFF5B8A9A)
                                  : (isDarkMode
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      onTap: () => _onDrawerItemTapped(index),
                    ),
                  );
                },
              ),
            ),
            // Logout button
            Container(
              margin: const EdgeInsets.all(16.0),
              child: Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.0),
                  onTap: _showLogoutDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: selectedBottomNavIndex == -1 ? 0 : selectedBottomNavIndex,
      onTap: _onBottomNavTapped,
      selectedItemColor: const Color(0xFF1E3A8A),
      unselectedItemColor: Colors.grey.shade400,
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDarkMode ? Colors.black87 : Colors.white,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
          backgroundColor:
              selectedBottomNavIndex == 0 ? Colors.blue.shade50 : null,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'Product List',
          backgroundColor:
              selectedBottomNavIndex == 1 ? Colors.blue.shade50 : null,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Orders',
          backgroundColor:
              selectedBottomNavIndex == 2 ? Colors.blue.shade50 : null,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
          backgroundColor:
              selectedBottomNavIndex == 3 ? Colors.blue.shade50 : null,
        ),
      ],
    );
  }
}

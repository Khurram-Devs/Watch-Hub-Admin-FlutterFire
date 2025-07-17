import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminLayout extends StatefulWidget {
  final String title;
  final int? drawerIndex; // Highlight in sidebar, optional
  final int? bottomNavIndex; // Selected tab, or null
  final Widget body;

  const AdminLayout({
    super.key,
    required this.title,
    required this.drawerIndex,
    required this.bottomNavIndex,
    required this.body,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  void _onDrawerTap(int index) {
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
    }
  }

  void _onBottomTap(int index) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        backgroundColor: Colors.deepPurple.shade400,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Text(
                'Admin Panel',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            _buildDrawerItem('Products', Icons.watch, 0),
            _buildDrawerItem('Brands', Icons.branding_watermark, 1),
            _buildDrawerItem('Testimonials', Icons.reviews, 2),
            _buildDrawerItem('Contact Messages', Icons.message, 3),
            _buildDrawerItem('Product FAQs', Icons.question_answer, 4),
            _buildDrawerItem('Promo Codes', Icons.discount, 5),
            _buildDrawerItem('Users', Icons.people, 6),
            _buildDrawerItem('Orders', Icons.receipt, 7),
          ],
        ),
      ),
      body: widget.body,
bottomNavigationBar: BottomNavigationBar(
  currentIndex: (widget.bottomNavIndex != null &&
          widget.bottomNavIndex! >= 0 &&
          widget.bottomNavIndex! < 4)
      ? widget.bottomNavIndex!
      : 0,
  onTap: _onBottomTap,
  selectedItemColor: Colors.deepPurple,
  unselectedItemColor: Colors.grey,
  type: BottomNavigationBarType.fixed,
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
    BottomNavigationBarItem(icon: Icon(Icons.watch), label: 'Products'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
  ],
),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, int index) {
    final isSelected = widget.drawerIndex == index;
    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.deepPurple.shade100,
      leading: Icon(icon, color: isSelected ? Colors.deepPurple : null),
      title: Text(title),
      onTap: () => _onDrawerTap(index),
    );
  }
}

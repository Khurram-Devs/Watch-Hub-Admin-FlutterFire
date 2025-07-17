import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'widgets/layout/admin_layout.dart';

// Screens
import 'screens/viewscreens/product_table_screen.dart';
import 'screens/viewscreens/orders_screen.dart';
import 'screens/viewscreens/users_screen.dart';
import 'screens/viewscreens/brands_screen.dart';
import 'screens/viewscreens/testimonials_screen.dart';
import 'screens/viewscreens/contact_messages_screen.dart';
import 'screens/viewscreens/product_faq_screen.dart';
import 'screens/viewscreens/promo_codes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final _router = GoRouter(
      initialLocation: isLoggedIn ? '/orders' : '/orders',
      errorBuilder: (context, state) => const NotFoundPage(),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const AdminLayout(
            title: 'Dashboard',
            drawerIndex: -1,
            bottomNavIndex: 0,
            body: ProductTableScreen(),
          ),
        ),
        GoRoute(
          path: '/orders',
          builder: (_, __) => const AdminLayout(
            title: 'Orders',
            drawerIndex: 7,
            bottomNavIndex: 1,
            body: OrdersScreen(),
          ),
        ),
        GoRoute(
          path: '/products',
          builder: (_, __) => const AdminLayout(
            title: 'Products',
            drawerIndex: 0,
            bottomNavIndex: 2,
            body: ProductTableScreen(),
          ),
        ),
        GoRoute(
          path: '/users',
          builder: (_, __) => const AdminLayout(
            title: 'Users',
            drawerIndex: 6,
            bottomNavIndex: 3,
            body: UsersScreen(),
          ),
        ),
        GoRoute(
          path: '/brands',
          builder: (_, __) => const AdminLayout(
            title: 'Brands',
            drawerIndex: 1,
            bottomNavIndex: null,
            body: BrandsScreen(),
          ),
        ),
        GoRoute(
          path: '/testimonials',
          builder: (_, __) => const AdminLayout(
            title: 'Testimonials',
            drawerIndex: 2,
            bottomNavIndex: null,
            body: TestimonialsScreen(),
          ),
        ),
        GoRoute(
          path: '/contact-messages',
          builder: (_, __) => const AdminLayout(
            title: 'Contact Messages',
            drawerIndex: 3,
            bottomNavIndex: null,
            body: ContactMessagesScreen(),
          ),
        ),
        GoRoute(
          path: '/faq',
          builder: (_, __) => const AdminLayout(
            title: 'Product FAQs',
            drawerIndex: 4,
            bottomNavIndex: null,
            body: ProductFAQScreen(),
          ),
        ),
        GoRoute(
          path: '/codes',
          builder: (_, __) => const AdminLayout(
            title: 'Promo Codes',
            drawerIndex: 5,
            bottomNavIndex: null,
            body: PromoCodesScreen(),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'WatchHub Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '404 - Page Not Found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'The requested page could not be found.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

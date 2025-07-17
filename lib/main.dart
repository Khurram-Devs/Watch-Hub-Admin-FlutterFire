import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_hub_ep/screens/viewscreens/managers_screen.dart';

import 'firebase_options.dart';
import 'widgets/layout/admin_layout.dart';
import 'screens/viewscreens/admin_login_screen.dart';
import 'screens/viewscreens/product_table_screen.dart';
import 'screens/viewscreens/orders_screen.dart';
import 'screens/viewscreens/users_screen.dart';
import 'screens/viewscreens/brands_screen.dart';
import 'screens/viewscreens/testimonials_screen.dart';
import 'screens/viewscreens/contact_messages_screen.dart';
import 'screens/viewscreens/product_faq_screen.dart';
import 'screens/viewscreens/promo_codes_screen.dart';

String? currentAdminRole;
bool get isLoggedIn => currentAdminRole != null;
final ValueNotifier<bool> loginStateNotifier = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final savedRole = prefs.getString('role');
  currentAdminRole = savedRole;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: isLoggedIn ? '/dashboard' : '/login',
      refreshListenable: loginStateNotifier,
      redirect: (context, state) {
        final isLogin = state.matchedLocation == '/login';
        if (!isLoggedIn && !isLogin) return '/login';
        if (isLoggedIn && isLogin) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const AdminLoginScreen()),
        GoRoute(
          path: '/dashboard',
          builder:
              (_, __) => AdminLayout(
                role: currentAdminRole!,
                title: 'Dashboard',
                drawerIndex: -1,
                bottomNavIndex: 0,
                body: const ProductTableScreen(),
              ),
        ),
        GoRoute(
          path: '/orders',
          builder:
              (_, __) => AdminLayout(
                role: currentAdminRole!,
                title: 'Orders',
                drawerIndex: 7,
                bottomNavIndex: 1,
                body: const OrdersScreen(),
              ),
        ),
        GoRoute(
          path: '/products',
          builder:
              (_, __) => AdminLayout(
                role: currentAdminRole!,
                title: 'Products',
                drawerIndex: 0,
                bottomNavIndex: 2,
                body: const ProductTableScreen(),
              ),
        ),
        GoRoute(
          path: '/users',
          builder:
              (_, __) => AdminLayout(
                role: currentAdminRole!,
                title: 'Users',
                drawerIndex: 6,
                bottomNavIndex: 3,
                body: const UsersScreen(),
              ),
        ),
        GoRoute(
          path: '/managers',
          builder:
              (_, __) => AdminLayout(
                role: currentAdminRole!,
                title: 'Managers',
                drawerIndex: null,
                bottomNavIndex: null,
                body: const ManagersScreen(),
              ),
        ),
        GoRoute(
          path: '/brands',
          builder:
              (_, __) => AdminLayout(
                role: currentAdminRole!,
                title: 'Brands',
                drawerIndex: 1,
                bottomNavIndex: null,
                body: const BrandsScreen(),
              ),
        ),
        GoRoute(
          path: '/testimonials',
          builder:
              (_, __) => AdminLayout(
                role: currentAdminRole!,
                title: 'Testimonials',
                drawerIndex: 2,
                bottomNavIndex: null,
                body: const TestimonialsScreen(),
              ),
        ),
        GoRoute(
          path: '/contact-messages',
          builder:
              (_, __) => AdminLayout(
                role: currentAdminRole!,
                title: 'Contact Messages',
                drawerIndex: 3,
                bottomNavIndex: null,
                body: const ContactMessagesScreen(),
              ),
        ),
        GoRoute(
          path: '/faq',
          builder:
              (_, __) => AdminLayout(
                role: currentAdminRole!,
                title: 'Product FAQs',
                drawerIndex: 4,
                bottomNavIndex: null,
                body: const ProductFAQScreen(),
              ),
        ),
        GoRoute(
          path: '/codes',
          builder:
              (_, __) => AdminLayout(
                role: currentAdminRole!,
                title: 'Promo Codes',
                drawerIndex: 5,
                bottomNavIndex: null,
                body: const PromoCodesScreen(),
              ),
        ),
      ],
      errorBuilder: (_, __) => const NotFoundPage(),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'WatchHub Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('404 - Page Not Found', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

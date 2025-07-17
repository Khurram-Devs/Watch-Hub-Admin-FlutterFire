// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_hub_ep/main_layout.dart';
import 'package:watch_hub_ep/screens/viewscreens/brands_screen.dart';

import 'firebase_options.dart';
// import 'screens/login.dart';
// import 'screens/dashboard.dart';
// import 'screens/add_category.dart';
// import 'screens/add_product.dart';
import 'screens/viewscreens/product_table_screen.dart';
// import 'screens/order_page.dart';
// import 'screens/user_page.dart';
// import 'screens/main_layout.dart';

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
      initialLocation: isLoggedIn ? '/main' : '/products',
      errorBuilder: (context, state) => const NotFoundPage(),
      routes: [
        // GoRoute(path: '/login', builder: (_, __) => const Login()),
        GoRoute(path: '/main', builder: (_, __) => const MainLayout()),
        // GoRoute(path: '/add_category', builder: (_, __) => const AddCategoryScreen()),
        // GoRoute(path: '/add_product', builder: (_, __) => const AddProductScreen()),
        GoRoute(path: '/products', builder: (_, __) => const ProductTableScreen()),
        GoRoute(path: '/brands', builder: (_, __) => const BrandsScreen()),
        // GoRoute(path: '/orders', builder: (_, __) => const OrdersPage()),
        // GoRoute(path: '/users', builder: (_, __) => const UserPage()),
        // GoRoute(path: '/dashboard', builder: (_, __) => const Dashboard()),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'WatchHub',
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
            Text('404 - Page Not Found', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('The requested page could not be found.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

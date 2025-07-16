import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_hub_ep/screens/addscreens/add_category.dart';
import 'package:watch_hub_ep/screens/addscreens/add_product.dart';
import 'package:watch_hub_ep/main_layout.dart'; // Import your unified layout
import 'package:watch_hub_ep/firebase_options.dart';
import 'package:watch_hub_ep/authscreen/login.dart';
import 'package:watch_hub_ep/extra/order.dart';
import 'package:watch_hub_ep/screens/viewscreens/product_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WatchHub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Use MainLayout as the main dashboard instead of separate pages
      initialRoute: isLoggedIn ? '/main' : '/products',
      routes: {
        '/main': (context) => const MainLayout(), // Main app with drawer + bottom nav
        '/dashboard': (context) => const MainLayout(), // Redirect to main layout
        '/login': (context) => const Login(),
        
        // Keep these routes for direct navigation or special cases
        '/add_category': (context) => const AddCategoryScreen(),
        '/add_product': (context) => const AddProductScreen(),
        '/order': (context) => const OrdersPage(),
        '/products': (context) =>  ProductTablePage(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routing if needed
        switch (settings.name) {
          case '/user':
            return MaterialPageRoute(builder: (context) => const UserPage());
          default:
            return null;
        }
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => const Scaffold(
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
        ),
      ),
    );
  }
}

// If you have a separate DashboardPage, you can keep it or remove it
// since it's now handled by MainLayout
class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Redirect to MainLayout if someone navigates here directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/main');
    });
    
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// If you need a UserPage class (based on your user.dart import)
class UserPage extends StatelessWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Users Page - Replace with your user list'),
      ),
    );
  }
}
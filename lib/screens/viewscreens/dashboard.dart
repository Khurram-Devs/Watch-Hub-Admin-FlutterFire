import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalOrders = 0, totalUsers = 0;
  int totalManagers = 0, totalCodes = 0, totalBrands = 0;
  int totalMessages = 0, totalTestimonials = 0;
  double totalRevenue = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => loading = true);

    final usersSnap =
        await FirebaseFirestore.instance.collection('usersProfile').get();
    totalUsers = usersSnap.docs.length;

    int ordersCount = 0;
    double revenueSum = 0;

    for (var u in usersSnap.docs) {
      final orders = await u.reference.collection('orders').get();
      for (var o in orders.docs) {
        ordersCount++;
        revenueSum += (o.data()['total'] ?? 0).toDouble();
      }
    }

    totalOrders = ordersCount;
    totalRevenue = revenueSum;

    final futures = await Future.wait([
      FirebaseFirestore.instance.collection('admin').get(),
      FirebaseFirestore.instance.collection('promoCodes').get(),
      FirebaseFirestore.instance
          .collection('categories')
          .where('type', isEqualTo: 1)
          .get(),
      FirebaseFirestore.instance.collection('contactMessages').get(),
      FirebaseFirestore.instance.collection('testimonials').get(),
    ]);

    totalManagers = futures[0].docs.length;
    totalCodes = futures[1].docs.length;
    totalBrands = futures[2].docs.length;
    totalMessages = futures[3].docs.length;
    totalTestimonials = futures[4].docs.length;

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    final metrics = [
      _MetricData(Icons.shopping_cart, 'Total Orders', totalOrders.toString()),
      _MetricData(Icons.people, 'Total Users', totalUsers.toString()),
      _MetricData(
        Icons.attach_money,
        'Revenue',
        '\$${totalRevenue.toStringAsFixed(2)}',
      ),
      _MetricData(Icons.manage_accounts, 'Managers', totalManagers.toString()),
      _MetricData(Icons.percent, 'Promo Codes', totalCodes.toString()),
      _MetricData(Icons.branding_watermark, 'Brands', totalBrands.toString()),
      _MetricData(Icons.message, 'Messages', totalMessages.toString()),
      _MetricData(Icons.reviews, 'Testimonials', totalTestimonials.toString()),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: metrics.map((m) => _MetricCard(data: m)).toList(),
          ),
        ),
      ),
    );
  }
}

class _MetricData {
  final IconData icon;
  final String label;
  final String value;
  _MetricData(this.icon, this.label, this.value);
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;
  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data.icon, size: 40, color: Color(0xFF5B8A9A)),
            const SizedBox(height: 12),
            Text(
              data.value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(data.label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

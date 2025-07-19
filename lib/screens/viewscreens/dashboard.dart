import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:math';

import 'package:watch_hub_ep/utils/string_utils.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum ScreenSize { small, medium, large }

ScreenSize getScreenSize(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 1024) return ScreenSize.large;
  if (width >= 600) return ScreenSize.medium;
  return ScreenSize.small;
}

class _DashboardScreenState extends State<DashboardScreen> {
  int lineChartDays = 6;
  int totalOrders = 0, totalUsers = 0;
  int totalManagers = 0, totalCodes = 0, totalBrands = 0;
  int totalMessages = 0, totalTestimonials = 0;
  double totalRevenue = 0;
  bool loading = true;

  Map<String, int> ordersByDay = {};
  Map<String, double> revenueByDay = {};
  Map<String, int> brandProductCount = {};
  Map<String, int> orderStatusCount = {};

  List<Map<String, dynamic>> recentOrders = [];
  List<Map<String, dynamic>> recentTestimonials = [];
  List<Map<String, dynamic>> recentContactMessages = [];
  List<Map<String, dynamic>> topPromoCodes = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;

      if (screenWidth >= 1024) {
        lineChartDays = 29;
      } else if (screenWidth >= 600) {
        lineChartDays = 14;
      } else {
        lineChartDays = 6;
      }

      _loadMetrics();
    });
  }

  List<PieChartSectionData> get orderStatusSections {
    final List<PieChartSectionData> sections = [];

    orderStatusCount.forEach((status, count) {
      sections.add(
        PieChartSectionData(
          color:
              status == "pending"
                  ? Colors.orange
                  : status == "shipped"
                  ? Colors.blue
                  : status == "delivered"
                  ? Colors.green
                  : status == "cancelled"
                  ? Colors.red
                  : Colors.grey,
          value: count.toDouble(),
          title: '${capitalizeEachWord(status)} ($count)',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
    });

    return sections;
  }

  Future<void> _loadMetrics() async {
    setState(() => loading = true);

    final usersSnap =
        await FirebaseFirestore.instance.collection('usersProfile').get();
    totalUsers = usersSnap.docs.length;

    int ordersCount = 0;
    double revenueSum = 0;
    final today = DateTime.now();
    final dailyOrders = <String, int>{};
    final dailyRevenue = <String, double>{};
    final orderList = <Map<String, dynamic>>[];

    for (var u in usersSnap.docs) {
      final orders =
          await u.reference
              .collection('orders')
              .orderBy('createdAt', descending: true)
              .get();
      for (var o in orders.docs) {
        final data = o.data();
        final total = (data['total'] ?? 0).toDouble();
        final ts = data['createdAt'];
        if (ts != null && ts is Timestamp) {
          final date = ts.toDate();
          final key = "${date.year}-${date.month}-${date.day}";
          if (today.difference(date).inDays <= lineChartDays) {
            dailyOrders[key] = (dailyOrders[key] ?? 0) + 1;
            dailyRevenue[key] = (dailyRevenue[key] ?? 0) + total;
          }
          orderList.add({
            'total': total,
            'createdAt': ts,
            'status': data['status'],
          });
        }
        ordersCount++;
        revenueSum += total;
      }
    }

    orderList.sort((a, b) {
      final aDate = (a['createdAt'] as Timestamp?)?.toDate();
      final bDate = (b['createdAt'] as Timestamp?)?.toDate();
      return (bDate ?? DateTime(0)).compareTo(aDate ?? DateTime(0));
    });
    recentOrders = orderList.take(5).toList();

    ordersByDay = dailyOrders;
    revenueByDay = dailyRevenue;
    totalOrders = ordersCount;
    totalRevenue = revenueSum;

    final futures = await Future.wait([
      FirebaseFirestore.instance.collection('admin').get(),
      FirebaseFirestore.instance
          .collection('promoCodes')
          .orderBy('usedTimes', descending: true)
          .limit(3)
          .get(),
      FirebaseFirestore.instance
          .collection('categories')
          .where('type', isEqualTo: 1)
          .get(),
      FirebaseFirestore.instance
          .collection('contactMessages')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get(),
      FirebaseFirestore.instance
          .collection('testimonials')
          .where('status', isEqualTo: 1)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get(),
    ]);

    totalManagers = futures[0].docs.length;
    totalCodes = futures[1].docs.length;
    totalBrands = futures[2].docs.length;
    totalMessages = futures[3].docs.length;
    totalTestimonials = futures[4].docs.length;

    topPromoCodes = futures[1].docs.map((doc) => doc.data()).toList();
    recentContactMessages = futures[3].docs.map((doc) => doc.data()).toList();
    recentTestimonials = futures[4].docs.map((doc) => doc.data()).toList();

    final productSnap =
        await FirebaseFirestore.instance.collection('products').get();
    final Map<String, int> brandCount = {};
    final Map<String, String> brandNameMap = {};

    for (var p in productSnap.docs) {
      final brandRef = p['brand'];
      if (brandRef != null && brandRef is DocumentReference) {
        if (!brandNameMap.containsKey(brandRef.id)) {
          final brandDoc = await brandRef.get();
          if (brandDoc.exists) {
            brandNameMap[brandRef.id] = brandDoc['name'];
          }
        }
        final brandName = brandNameMap[brandRef.id] ?? 'Unknown';
        brandCount[brandName] = (brandCount[brandName] ?? 0) + 1;
      }
    }

    brandProductCount = brandCount;

    Map<String, int> orderStatusCount = {};

    for (var userDoc in usersSnap.docs) {
      final ordersSnap = await userDoc.reference.collection('orders').get();

      for (var orderDoc in ordersSnap.docs) {
        final status = orderDoc['status']?.toString() ?? 'unknown';
        orderStatusCount[status] = (orderStatusCount[status] ?? 0) + 1;
      }
    }
    setState(() {
      this.orderStatusCount = orderStatusCount;
    });
    final List<PieChartSectionData> orderStatusSections = [];
    final random = Random();
    for (var entry in orderStatusCount.entries) {
      final h = random.nextDouble() * 360;
      final s = 0.6 + random.nextDouble() * 0.4;
      final l = 0.7;
      final color = HSLColor.fromAHSL(1.0, h, s, l).toColor();

      orderStatusSections.add(
        PieChartSectionData(
          color: color,
          value: entry.value.toDouble(),
          title: '${capitalizeEachWord(entry.key)} (${entry.value})',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
    }

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
      _MetricData(
        Icons.manage_accounts,
        'Managers',
        (totalManagers - 1).toString(),
      ),
      _MetricData(Icons.percent, 'Promo Codes', totalCodes.toString()),
      _MetricData(Icons.branding_watermark, 'Brands', totalBrands.toString()),
      _MetricData(Icons.message, 'Messages', totalMessages.toString()),
      _MetricData(Icons.reviews, 'Testimonials', totalTestimonials.toString()),
    ];

    final List<PieChartSectionData> pieSections = [];
    final random = Random();
    for (var entry in brandProductCount.entries) {
      final h = random.nextDouble() * 360;
      final s = 0.6 + random.nextDouble() * 0.4;
      final l = 0.7;
      final color = HSLColor.fromAHSL(1.0, h, s, l).toColor();

      pieSections.add(
        PieChartSectionData(
          color: color,
          value: entry.value.toDouble(),
          title: '${capitalizeEachWord(entry.key)} (${entry.value})',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  double maxWidth = constraints.maxWidth;
                  int cardsPerRow = 4;

                  if (maxWidth < 600) {
                    cardsPerRow = 2;
                  } else if (maxWidth < 1000) {
                    cardsPerRow = 3;
                  }

                  double cardWidth =
                      (maxWidth - (cardsPerRow - 1) * 16) / cardsPerRow;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children:
                        metrics
                            .map(
                              (m) => SizedBox(
                                width: cardWidth,
                                child: _MetricCard(data: m),
                              ),
                            )
                            .toList(),
                  );
                },
              ),

              const SizedBox(height: 32),
              _ChartCard(
                title: "Orders & Revenue (Last ${lineChartDays + 1} Days)",
                height: 300,
                child: _buildLineChart(),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  return isMobile
                      ? Column(
                        children: [
                          _ChartCard(
                            title: "Products per Brand",
                            height: 300,
                            child: _buildPieChart(pieSections),
                          ),
                          const SizedBox(height: 16),
                          _ChartCard(
                            title: "Orders per Status",
                            height: 300,
                            child: _buildPieChart(orderStatusSections),
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          Expanded(
                            child: _ChartCard(
                              title: "Products per Brand",
                              height: 300,
                              child: _buildPieChart(pieSections),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ChartCard(
                              title: "Orders per Status",
                              height: 300,
                              child: _buildPieChart(orderStatusSections),
                            ),
                          ),
                        ],
                      );
                },
              ),

              const SizedBox(height: 24),
              _ChartCard(
                title: "Recent Orders",
                child: _buildFeed(
                  recentOrders,
                  (data) =>
                      "Total: \$${data['total']} - ${capitalize(data['status'])}",
                  timestamp:
                      (data) => (data['createdAt'] as Timestamp?)?.toDate(),
                ),
              ),
              const SizedBox(height: 16),
              _ChartCard(
                title: "Contact Messages",
                child: _buildFeed(
                  recentContactMessages,
                  (data) =>
                      "${capitalize(data['name'])} - ${capitalize(data['message'])}",
                  timestamp:
                      (data) => (data['createdAt'] as Timestamp?)?.toDate(),
                ),
              ),
              const SizedBox(height: 16),
              _ChartCard(
                title: "Top Promo Codes",
                child: _buildFeed(
                  topPromoCodes,
                  (data) =>
                      "${capitalizeEachWord(data['title'])} (${data['usedTimes']} used)",
                ),
              ),
              const SizedBox(height: 16),
              _ChartCard(
                title: "Recent Testimonials",
                child: _buildFeed(
                  recentTestimonials,
                  (data) => capitalizeEachWord(data['testimonial']),
                  timestamp:
                      (data) => (data['createdAt'] as Timestamp?)?.toDate(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeed(
    List<Map<String, dynamic>> list,
    String Function(Map<String, dynamic>) builder, {
    DateTime? Function(Map<String, dynamic>)? timestamp,
  }) {
    list.sort((a, b) {
      final aDate = timestamp?.call(a);
      final bDate = timestamp?.call(b);
      return (bDate ?? DateTime(0)).compareTo(aDate ?? DateTime(0));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          list.map((data) {
            final time = timestamp?.call(data);
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: const Icon(
                  Icons.notifications,
                  color: Color(0xFF5B8A9A),
                ),
                title: Text(
                  builder(data),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing:
                    time != null
                        ? Text(
                          timeago.format(time),
                          style: const TextStyle(color: Colors.grey),
                        )
                        : null,
              ),
            );
          }).toList(),
    );
  }

  String _monthAbbr(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            axisNameSize: 16,
            drawBelowEverything: true,
            axisNameWidget: const SizedBox(),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 2,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index > lineChartDays) return const SizedBox();
                final date = DateTime.now().subtract(
                  Duration(days: lineChartDays - index),
                );
                final formatted =
                    "${date.day.toString().padLeft(2, '0')}-${_monthAbbr(date.month)}";
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(formatted, style: const TextStyle(fontSize: 10)),
                  ],
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: lineChartDays.toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: _getSpotsFromMap(revenueByDay, isRevenue: true),
            isCurved: true,
            color: Colors.green,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final dayIndex = spot.x.toInt();
                final date = DateTime.now().subtract(
                  Duration(days: lineChartDays - dayIndex),
                );

                final key = "${date.year}-${date.month}-${date.day}";
                final orders = ordersByDay[key] ?? 0;
                final revenue = revenueByDay[key] ?? 0.0;

                final formattedDate =
                    "${date.day.toString().padLeft(2, '0')}-${_monthAbbr(date.month)}";

                return LineTooltipItem(
                  "Orders: $orders\nRevenue: \$${revenue.toStringAsFixed(2)}\nDate: $formattedDate",
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(List<PieChartSectionData> sections) {
    return PieChart(
      PieChartData(sectionsSpace: 4, centerSpaceRadius: 40, sections: sections),
    );
  }

  List<FlSpot> _getSpotsFromMap(
    Map<String, dynamic> map, {
    bool isRevenue = false,
  }) {
    final now = DateTime.now();
    List<FlSpot> spots = [];

    for (int i = lineChartDays; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = "${date.year}-${date.month}-${date.day}";
      final val = map[key] ?? 0;

      spots.add(
        FlSpot(
          lineChartDays - i.toDouble(),
          isRevenue ? (val as double) : (val as int).toDouble(),
        ),
      );
    }

    return spots;
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double? height;

  const _ChartCard({required this.title, required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            height != null ? SizedBox(height: height, child: child) : child,
          ],
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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    return SizedBox(
      width: isMobile ? width * 0.44 : 220,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 36, color: const Color(0xFF5B8A9A)),
              const SizedBox(height: 10),
              Text(
                data.value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<Map<String, dynamic>> orders = [];
  bool loading = true;
  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    fetchMyOrders();
  }

  Future<void> fetchMyOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        errorMsg = 'User not logged in.';
        loading = false;
      });
      return;
    }

    try {
      final snapshot =
          await FirebaseDatabase.instance.ref('checkout/${user.uid}').once();

      final data = snapshot.snapshot.value;
      if (data == null) {
        setState(() {
          orders = [];
          loading = false;
        });
        return;
      }

      Map<dynamic, dynamic> userOrders = data as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> tempOrders = [];

      for (var entry in userOrders.entries) {
        Map<String, dynamic> order = Map<String, dynamic>.from(entry.value);
        order['key'] = entry.key;
        order['status'] ??= 'Pending';
        tempOrders.add(order);
      }

      tempOrders.sort(
        (a, b) =>
            b['timestamp'].toString().compareTo(a['timestamp'].toString()),
      );

      setState(() {
        orders = tempOrders;
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = 'Error fetching orders: $e';
        loading = false;
      });
    }
  }

  String formatDate(String isoDate) {
    try {
      DateTime dt = DateTime.parse(isoDate);
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return isoDate;
    }
  }

  double parseRate(dynamic rateRaw) {
    if (rateRaw == null) return 0;
    if (rateRaw is String) {
      return double.tryParse(rateRaw) ?? 0;
    } else if (rateRaw is num) {
      return rateRaw.toDouble();
    } else {
      return 0;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.teal,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : errorMsg.isNotEmpty
              ? Center(child: Text(errorMsg))
              : orders.isEmpty
              ? const Center(child: Text('You have no orders.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final items = order['items'] ?? [];
                  final timestamp = order['timestamp'] ?? '';
                  final status = order['status'] ?? 'Pending';

                  double orderTotal = 0;
                  for (var item in items) {
                    final qty = item['quantity'] ?? 1;
                    final rate = parseRate(item['rate']);
                    orderTotal += qty * rate;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Ordered on: ${formatDate(timestamp)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Status: ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                status,
                                style: TextStyle(
                                  color: getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          ...items.map<Widget>((item) {
                            final name = item['name'] ?? 'N/A';
                            final qty = item['quantity'] ?? 1;
                            final rate = parseRate(item['rate']);
                            final total = qty * rate;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    "x$qty",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text("\$${rate.toStringAsFixed(2)}"),
                                  Text("= \$${total.toStringAsFixed(2)}"),
                                ],
                              ),
                            );
                          }).toList(),
                          const Divider(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Total: \$${orderTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

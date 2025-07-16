import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  Map<String, String> userNames = {}; // Cache userId -> userName
  List<Map<String, dynamic>> orders = [];
  bool loading = true;
  String errorMsg = '';
  final List<String> orderStatuses = [
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    checkUserRole(); // Check role before loading orders
  }

  Future<void> checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        errorMsg = 'No user logged in.';
        loading = false;
      });
      return;
    }

    final snapshot =
        await FirebaseDatabase.instance.ref('users/${user.uid}/role').once();

    final role = snapshot.snapshot.value?.toString() ?? 'user';

    if (role != 'superadmin') {
      setState(() {
        errorMsg = 'Access denied: Only superadmin can view orders.';
        loading = false;
      });
      return;
    }

    // User is superadmin, load orders
    await fetchAllOrders();
  }

  Future<String> fetchUserName(String userId) async {
    if (userNames.containsKey(userId)) {
      return userNames[userId]!;
    }
    final snapshot =
        await FirebaseDatabase.instance.ref('users/$userId/name').once();
    final name = snapshot.snapshot.value?.toString() ?? 'Unknown User';
    userNames[userId] = name;
    return name;
  }

  Future<void> fetchAllOrders() async {
    try {
      DatabaseReference checkoutRef = FirebaseDatabase.instance.ref('checkout');

      final snapshot = await checkoutRef.once();

      final data = snapshot.snapshot.value;
      if (data == null) {
        setState(() {
          orders = [];
          loading = false;
        });
        return;
      }

      Map<dynamic, dynamic> allUsersOrders = data as Map<dynamic, dynamic>;

      List<Map<String, dynamic>> tempOrders = [];

      for (var entry in allUsersOrders.entries) {
        final String userId = entry.key;
        final Map<dynamic, dynamic> userOrders = entry.value;

        for (var orderEntry in userOrders.entries) {
          Map<String, dynamic> order = Map<String, dynamic>.from(
            orderEntry.value,
          );
          order['key'] = orderEntry.key;
          order['userId'] = userId;
          order['status'] ??= 'Pending'; // Ensure status exists
          tempOrders.add(order);
        }
      }

      tempOrders.sort(
        (a, b) =>
            b['timestamp'].toString().compareTo(a['timestamp'].toString()),
      );

      for (var order in tempOrders) {
        final userId = order['userId'] as String;
        await fetchUserName(userId);
      }

      setState(() {
        orders = tempOrders;
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = 'Failed to fetch orders: $e';
        loading = false;
      });
    }
  }

  Future<void> updateOrderStatus(
    String userId,
    String orderKey,
    String newStatus,
  ) async {
    await FirebaseDatabase.instance
        .ref('checkout/$userId/$orderKey/status')
        .set(newStatus);

    // Update local state
    setState(() {
      final index = orders.indexWhere(
        (o) => o['key'] == orderKey && o['userId'] == userId,
      );
      if (index != -1) {
        orders[index]['status'] = newStatus;
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        backgroundColor: Colors.teal,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : errorMsg.isNotEmpty
              ? Center(child: Text(errorMsg))
              : orders.isEmpty
              ? const Center(child: Text('No orders found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('User')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Items')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows:
                      orders.map((order) {
                        final List<dynamic> items = order['items'] ?? [];
                        final userId = order['userId'] ?? '';
                        final userName = userNames[userId] ?? 'Unknown User';
                        final timestamp = order['timestamp'] ?? '';
                        final orderKey = order['key'];
                        final status = order['status'] ?? 'Pending';

                        double orderTotal = 0;
                        final itemNames = items
                            .map((item) {
                              final qty = item['quantity'] ?? 1;
                              final rate = parseRate(item['rate']);
                              orderTotal += qty * rate;
                              return "${item['name'] ?? 'N/A'} (x$qty)";
                            })
                            .join(", ");

                        return DataRow(
                          cells: [
                            DataCell(Text(userName)),
                            DataCell(Text(formatDate(timestamp))),
                            DataCell(Text(itemNames)),
                            DataCell(
                              Text("\$${orderTotal.toStringAsFixed(2)}"),
                            ),
                            DataCell(
                              DropdownButton<String>(
                                value: status,
                                items:
                                    orderStatuses.map((status) {
                                      return DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      );
                                    }).toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null &&
                                      newStatus != status) {
                                    updateOrderStatus(
                                      userId,
                                      orderKey,
                                      newStatus,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
    );
  }
}

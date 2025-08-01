import 'package:flutter/material.dart';
import 'package:watch_hub_ep/models/order_model.dart';
import 'package:watch_hub_ep/services/order_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:watch_hub_ep/services/user_service.dart';
import 'package:watch_hub_ep/utils/string_utils.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<OrderModel> _orders = [];
  List<OrderModel> _filteredOrders = [];
  Map<String, Map<String, String>> _userDetails = {};
  String _searchQuery = '';
  String _sortBy = 'created At';
  String _statusFilter = 'all';
  bool _isLoading = true;

  final List<String> _sortOptions = ['created At', 'total', 'status'];
  final List<String> _statusOptions = [
    'all',
    'pending',
    'shipped',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await OrderService.fetchAllOrders();
    final userIds = orders.map((o) => o.userId).toSet();
    final details = await UserService.fetchUserDetails(userIds);
    setState(() {
      _orders = orders;
      _userDetails = details;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    _filteredOrders =
        _orders.where((o) {
          final query = _searchQuery.toLowerCase();
          final matchSearch =
              o.status.toLowerCase().contains(query) ||
              o.id.toLowerCase().contains(query) ||
              _userDetails[o.userId]?['fullName']?.toLowerCase().contains(
                    query,
                  ) ==
                  true;

          final matchStatus =
              _statusFilter == 'all' || o.status == _statusFilter;

          return matchSearch && matchStatus;
        }).toList();

    _filteredOrders.sort((a, b) {
      switch (_sortBy) {
        case 'total':
          return b.total.compareTo(a.total);
        case 'status':
          return a.status.compareTo(b.status);
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });
  }

  Future<void> _updateStatus(OrderModel order) async {
    final newStatus = await showDialog<String>(
      context: context,
      builder:
          (_) => SimpleDialog(
            title: const Text("Update Status"),
            children:
                ['pending', 'shipped', 'delivered', 'cancelled'].map((status) {
                  return SimpleDialogOption(
                    child: Text(status.toUpperCase()),
                    onPressed: () => Navigator.pop(context, status),
                  );
                }).toList(),
          ),
    );
    if (newStatus != null && newStatus != order.status) {
      await OrderService.updateOrderStatus(order.userId, order.id, newStatus);
      _loadOrders();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSortChips() {
    return Wrap(
      spacing: 8,
      children:
          _sortOptions.map((option) {
            final selected = _sortBy == option;
            return ChoiceChip(
              label: Text(option.toUpperCase()),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _sortBy = option;
                  _applyFilters();
                });
              },
            );
          }).toList(),
    );
  }

  Widget _buildStatusFilterChips() {
    return Wrap(
      spacing: 8,
      children:
          _statusOptions.map((status) {
            final selected = _statusFilter == status;
            return ChoiceChip(
              label: Text(capitalize(status)),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _statusFilter = status;
                  _applyFilters();
                });
              },
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, Map<String, List<OrderModel>>>{};
    for (final order in _filteredOrders) {
      grouped.putIfAbsent(order.userId, () => {});
      grouped[order.userId]!.putIfAbsent(order.status, () => []);
      grouped[order.userId]![order.status]!.add(order);
    }

    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search orders...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                          _applyFilters();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSortChips(),
                    const SizedBox(height: 12),
                    _buildStatusFilterChips(),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children:
                            grouped.entries.map((userEntry) {
                              final userId = userEntry.key;
                              final user = _userDetails[userId];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        user?['avatarUrl'] ?? '',
                                      ),
                                      radius: 22,
                                    ),
                                    title: Text(
                                      user?['fullName'] ?? userId,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ...userEntry.value.entries.map((statusEntry) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                            bottom: 6,
                                          ),
                                          child: Text(
                                            "Status: ${capitalize(statusEntry.key)}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _statusColor(
                                                statusEntry.key,
                                              ),
                                            ),
                                          ),
                                        ),
                                        ...statusEntry.value.map(
                                          (o) => Card(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 3,
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        "Order#: ${o.id}",
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          color: Colors.blue,
                                                        ),
                                                        onPressed:
                                                            () => _updateStatus(
                                                              o,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    "Total: \$${o.total.toStringAsFixed(2)}",
                                                  ),
                                                  Text(
                                                    "Status: ${capitalize(o.status)}",
                                                    style: TextStyle(
                                                      color: _statusColor(
                                                        o.status,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (o.promoCode != null &&
                                                      o.promoCode!.isNotEmpty)
                                                    Text(
                                                      "Promo: ${o.promoCode} (${o.promoTitle})",
                                                    ),
                                                  Text(
                                                    "Items: ${o.items.length}",
                                                  ),
                                                  Text(
                                                    "Created: ${timeago.format(o.createdAt)}",
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

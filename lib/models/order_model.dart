import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final DocumentReference productRef;
  final int quantity;

  OrderItem({required this.productRef, required this.quantity});

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productRef: map['productRef'],
      quantity: map['quantity'],
    );
  }
}

class OrderModel {
  final String id;
  final String userId;
  final DateTime createdAt;
  final double discount;
  final double shipping;
  final double subtotal;
  final double tax;
  final double total;
  final String status;
  final String? promoCode;
  final String? promoTitle;
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.discount,
    required this.shipping,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    this.promoCode,
    this.promoTitle,
    required this.items,
  });

  factory OrderModel.fromDoc(String id, String userId, Map<String, dynamic> data) {
    final itemsList = (data['items'] as List)
        .map((item) => OrderItem.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    return OrderModel(
      id: id,
      userId: userId,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      discount: (data['discount'] ?? 0).toDouble(),
      shipping: (data['shipping'] ?? 0).toDouble(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'],
      promoCode: data['promoCode'],
      promoTitle: data['promoTitle'],
      items: itemsList,
    );
  }
}

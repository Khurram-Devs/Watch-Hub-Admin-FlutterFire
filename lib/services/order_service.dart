import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<List<OrderModel>> fetchAllOrders() async {
    final usersSnapshot = await _firestore.collection('usersProfile').get();
    List<OrderModel> allOrders = [];

    for (var userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      final ordersSnapshot =
          await _firestore
              .collection('usersProfile')
              .doc(userId)
              .collection('orders')
              .get();

      for (var orderDoc in ordersSnapshot.docs) {
        final data = orderDoc.data();
        final order = OrderModel.fromDoc(orderDoc.id, userId, data);
        allOrders.add(order);
      }
    }

    return allOrders;
  }

  static Future<void> updateOrderStatus(
    String userId,
    String orderId,
    String status,
  ) async {
    final orderRef = _firestore
        .collection('usersProfile')
        .doc(userId)
        .collection('orders')
        .doc(orderId);

    await orderRef.update({'status': status});

    final notification = _getNotificationForStatus(status, orderId);
    if (notification != null) {
      await _firestore
          .collection('usersProfile')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': notification['title'],
            'message': notification['message'],
            'type': notification['type'],
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
    }
  }

  static Map<String, String>? _getNotificationForStatus(
    String status,
    String orderId,
  ) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'title': 'Order Pending',
          'message': 'Your order is being processed. Order ID : #$orderId',
          'type': 'order_pending',
        };
      case 'shipped':
        return {
          'title': 'Order Shipped!',
          'message': 'Your order is on the way. Order ID : #$orderId',
          'type': 'order_shipped',
        };
      case 'delivered':
        return {
          'title': 'Order Delivered!',
          'message': 'Your order has been delivered. Order ID : #$orderId',
          'type': 'order_delivered',
        };
      case 'cancelled':
        return {
          'title': 'Order Cancelled',
          'message': 'Your order has been cancelled. Order ID : #$orderId',
          'type': 'order_cancelled',
        };
      default:
        return null;
    }
  }
}

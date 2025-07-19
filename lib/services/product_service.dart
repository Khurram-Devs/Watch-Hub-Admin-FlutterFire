import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<List<ProductModel>> getProducts() async {
    final snapshot = await _firestore.collection('products').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ProductModel.fromMap({...data, 'id': doc.id});
    }).toList();
  }

  static Future<Map<String, dynamic>> getCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    final Map<String, dynamic> result = {};
    for (var doc in snapshot.docs) {
      result[doc.id] = doc.data();
    }
    return result;
  }

  static Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  static Future<void> addOrUpdateProduct(ProductModel product) async {
    final docRef = _firestore
        .collection('products')
        .doc(
          product.id.isNotEmpty
              ? product.id
              : _firestore.collection('products').doc().id,
        );

    final isNew = product.id.isEmpty;

    ProductModel? oldProduct;

    if (!isNew) {
      final oldSnap = await docRef.get();
      if (oldSnap.exists) {
        oldProduct = ProductModel.fromMap({
          ...oldSnap.data()!,
          'id': oldSnap.id,
        });
      }
    }

    final updatedProduct =
        isNew
            ? product.copyWith(id: docRef.id, createdAt: DateTime.now())
            : product;

    await docRef.set(updatedProduct.toMap());

    if (oldProduct != null) {
      final oldStock = oldProduct.inventoryCount;
      final newStock = updatedProduct.inventoryCount;

      final oldPrice = oldProduct.price;
      final newPrice = updatedProduct.price;

      String? type;
      String? title;
      String? message;

      if (oldStock == 0 && newStock > 0) {
        type = 'back_in_stock';
        title = 'Back In Stock!';
        message =
            'The product "${updatedProduct.title}" is now available again.';
      } else if (oldStock > 0 && newStock == 0) {
        type = 'out_of_stock';
        title = 'Out of Stock!';
        message = 'The product "${updatedProduct.title}" is now sold out.';
      } else if (newPrice < oldPrice) {
        type = 'price_drop';
        title = 'Price Dropped!';
        message =
            'The product "${updatedProduct.title}" you wishlisted is now \$${newPrice.toStringAsFixed(2)}.';
      }

      if (type != null) {
        await _notifyUsersWithProductInWishlist(
          updatedProduct.id,
          title!,
          message!,
          type,
        );
      }
    }
  }

  static Future<void> _notifyUsersWithProductInWishlist(
    String productId,
    String title,
    String message,
    String type,
  ) async {
    final usersSnapshot = await _firestore.collection('usersProfile').get();

    for (var userDoc in usersSnapshot.docs) {
      final data = userDoc.data();
      final wishlist = data['wishlist'] ?? [];

      final hasProduct = wishlist.any((ref) {
        if (ref is DocumentReference) {
          return ref.id == productId;
        }
        return false;
      });

      if (hasProduct) {
        await _firestore
            .collection('usersProfile')
            .doc(userDoc.id)
            .collection('notifications')
            .add({
              'title': title,
              'message': message,
              'type': type,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
    }
  }
}

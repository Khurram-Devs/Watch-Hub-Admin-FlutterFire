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
        .doc(product.id.isNotEmpty ? product.id : null);
    final newDoc =
        product.id.isEmpty ? _firestore.collection('products').doc() : docRef;
    final updatedProduct =
        product.id.isEmpty
            ? product.copyWith(id: newDoc.id, createdAt: DateTime.now())
            : product;

    await newDoc.set(updatedProduct.toMap());
  }
}

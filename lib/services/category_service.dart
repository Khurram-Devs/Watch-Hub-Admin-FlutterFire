import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  static final _firestore = FirebaseFirestore.instance;
  static final _categoryCollection = _firestore.collection('categories');

  static Future<List<CategoryModel>> fetchByType(int type) async {
    final querySnapshot =
        await _firestore
            .collection('categories')
            .where('type', isEqualTo: type)
            .get();

    return querySnapshot.docs.map((doc) {
      return CategoryModel.fromMap(doc.data(), doc.id);
    }).toList();
  }

  static Future<Map<String, CategoryModel>> fetchCategories() async {
    final snapshot = await _categoryCollection.get();
    Map<String, CategoryModel> map = {};
    for (var doc in snapshot.docs) {
      map[doc.id] = CategoryModel.fromMap(doc.data(), doc.id);
    }
    return map;
  }

  static Future<void> addCategory(CategoryModel category) async {
    final docRef = _firestore.collection('categories').doc();
    await docRef.set(category.copyWith(id: docRef.id).toMap());
  }

  static Future<void> updateCategory(CategoryModel category) async {
    await _firestore
        .collection('categories')
        .doc(category.id)
        .update(category.toMap());
  }

  static Future<void> deleteCategory(String id) async {
    final docRef = _firestore.collection('categories').doc(id);
    final docSnap = await docRef.get();

    if (!docSnap.exists) return;

    final data = docSnap.data()!;
    final int type = data['type'] ?? 0;

    await docRef.delete();

    final productsSnap = await _firestore.collection('products').get();

    if (type == 1) {
      for (final doc in productsSnap.docs) {
        final productData = doc.data();
        final DocumentReference? brandRef = productData['brand'];
        if (brandRef != null && brandRef.id == id) {
          await doc.reference.delete();
        }
      }
    } else if (type == 2) {
      for (final doc in productsSnap.docs) {
        final productData = doc.data();
        final List<dynamic> categoryRefs = productData['categories'] ?? [];

        final hasCategory = categoryRefs.any(
          (ref) => ref is DocumentReference && ref.id == id,
        );

        if (hasCategory) {
          final updatedCategories =
              categoryRefs
                  .where((ref) => ref is DocumentReference && ref.id != id)
                  .toList();

          await doc.reference.update({'categories': updatedCategories});
        }
      }
    }
  }
}

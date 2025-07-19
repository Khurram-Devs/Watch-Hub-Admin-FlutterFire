import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/testimonial_model.dart';

class TestimonialService {
  static final _collection = FirebaseFirestore.instance.collection(
    'testimonials',
  );

  static Future<List<TestimonialModel>> fetchAll() async {
    final snapshot =
        await _collection.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => TestimonialModel.fromDoc(doc)).toList();
  }

  static Future<void> deleteTestimonial(String id) async {
    await _collection.doc(id).delete();
  }

  static Future<void> toggleStatus(String id, int currentStatus) async {
    await _collection.doc(id).update({'status': currentStatus == 1 ? 0 : 1});
  }
}

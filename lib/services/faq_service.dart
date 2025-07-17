import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watch_hub_ep/models/faq_model.dart';

class FAQService {
  static final _faqCollection = FirebaseFirestore.instance.collection('productFAQ');

  static Future<List<FAQModel>> fetchAll() async {
    final snapshot = await _faqCollection.orderBy('question').get();
    return snapshot.docs.map((doc) => FAQModel.fromDoc(doc)).toList();
  }

  static Future<void> createFAQ(FAQModel faq) async {
    await _faqCollection.add(faq.toMap());
  }

  static Future<void> updateFAQ(String id, FAQModel faq) async {
    await _faqCollection.doc(id).update(faq.toMap());
  }

  static Future<void> deleteFAQ(String id) async {
    await _faqCollection.doc(id).delete();
  }
}

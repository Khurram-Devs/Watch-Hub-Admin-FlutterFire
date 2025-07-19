import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact_message_model.dart';

class ContactMessageService {
  static final _db = FirebaseFirestore.instance;
  static final _collection = _db.collection('contactMessages');

  static Future<List<ContactMessageModel>> fetchAll() async {
    final snapshot =
        await _collection.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => ContactMessageModel.fromDoc(doc))
        .toList();
  }

  static Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_model.dart';

class AdminService {
  static final _firestore = FirebaseFirestore.instance;
  static final _adminCollection = _firestore.collection('admin');
  static Future<AdminModel?> login(String id, String password) async {
    final snapshot =
        await _adminCollection
            .where('id', isEqualTo: id)
            .where('password', isEqualTo: password)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      return AdminModel.fromMap(snapshot.docs.first.data());
    }

    return null;
  }

  static Future<List<AdminModel>> fetchManagers() async {
    final snapshot =
        await _adminCollection.where('role', isNotEqualTo: 'super').get();

    return snapshot.docs.map((doc) => AdminModel.fromMap(doc.data())).toList();
  }

  static Future<String?> getDocIdByAdminId(String id) async {
    final snapshot =
        await _adminCollection.where('id', isEqualTo: id).limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }

    return null;
  }

  static Future<void> createManager(AdminModel manager) async {
    await _adminCollection.add(manager.toMap());
  }

  static Future<void> updateManager(String docId, AdminModel manager) async {
    await _adminCollection.doc(docId).update(manager.toMap());
  }

  static Future<void> deleteManager(String docId) async {
    await _adminCollection.doc(docId).delete();
  }
}

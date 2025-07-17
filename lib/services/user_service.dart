import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  static final _userRef = FirebaseFirestore.instance.collection('usersProfile');

  static Future<List<UserModel>> fetchAll() async {
    final snap = await _userRef.orderBy('createdAt', descending: true).get();
    return snap.docs.map((doc) => UserModel.fromDoc(doc)).toList();
  }

  static Future<Map<String, Map<String, String>>> fetchUserDetails(Set<String> userIds) async {
    final Map<String, Map<String, String>> details = {};
    if (userIds.isEmpty) return details;

    final batches = userIds.toList();
    final futures = <Future<DocumentSnapshot>>[];

    for (final uid in batches) {
      futures.add(_userRef.doc(uid).get());
    }

    final snaps = await Future.wait(futures);
    for (final snap in snaps) {
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        details[snap.id] = {
          'fullName': data['fullName'] ?? '',
          'avatarUrl': data['avatarUrl'] ?? '',
        };
      }
    }

    return details;
  }
}

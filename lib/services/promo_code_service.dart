import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promo_code_model.dart';

class PromoCodeService {
  static final _promoRef = FirebaseFirestore.instance.collection('promoCodes');

  static Future<List<PromoCodeModel>> fetchAll() async {
    final snap = await _promoRef.orderBy('title').get();
    return snap.docs.map((d) => PromoCodeModel.fromDoc(d)).toList();
  }

  static Future<void> create(PromoCodeModel model) async {
    await _promoRef.add(model.toMap());
  }

  static Future<void> update(String id, PromoCodeModel model) async {
    await _promoRef.doc(id).update(model.toMap());
  }

  static Future<void> delete(String id) async {
    await _promoRef.doc(id).delete();
  }
}

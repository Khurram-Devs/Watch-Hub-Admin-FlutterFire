import 'package:cloud_firestore/cloud_firestore.dart';

class PromoCodeModel {
  final String id;
  final String code;
  final String title;
  final int discountPercent;
  final String limit;
  final int usedTimes;

  PromoCodeModel({
    required this.id,
    required this.code,
    required this.title,
    required this.discountPercent,
    required this.limit,
    required this.usedTimes,
  });

  factory PromoCodeModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromoCodeModel(
      id: doc.id,
      code: data['code'] ?? '',
      title: data['title'] ?? '',
      discountPercent: data['discountPercent'] ?? 0,
      limit: data['limit'] ?? '0',
      usedTimes: data['usedTimes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'title': title,
      'discountPercent': discountPercent,
      'limit': limit,
      'usedTimes': usedTimes,
    };
  }
}

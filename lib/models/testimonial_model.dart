import 'package:cloud_firestore/cloud_firestore.dart';

class TestimonialModel {
  final String id;
  final String testimonial;
  final int status;
  final DocumentReference userRef;
  final Timestamp createdAt;

  TestimonialModel({
    required this.id,
    required this.testimonial,
    required this.status,
    required this.userRef,
    required this.createdAt,
  });

  factory TestimonialModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestimonialModel(
      id: doc.id,
      testimonial: data['testimonial'] ?? '',
      status: data['status'] ?? 0,
      userRef: data['userRef'],
      createdAt: data['createdAt'],
    );
  }
}

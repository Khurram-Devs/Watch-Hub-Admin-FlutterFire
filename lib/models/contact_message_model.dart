import 'package:cloud_firestore/cloud_firestore.dart';

class ContactMessageModel {
  final String id;
  final String name;
  final String email;
  final String message;
  final Timestamp createdAt;

  ContactMessageModel({
    required this.id,
    required this.name,
    required this.email,
    required this.message,
    required this.createdAt,
  });

  factory ContactMessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContactMessageModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      message: data['message'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}

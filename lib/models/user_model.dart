import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String fullName;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String avatarUrl;
  final String occupation;
  final Timestamp createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.occupation,
    required this.createdAt,
  });

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      occupation: data['occupation'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}

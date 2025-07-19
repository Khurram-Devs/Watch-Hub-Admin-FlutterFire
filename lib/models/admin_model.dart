import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String id;
  final String password;
  final String role;
  final DateTime createdAt;

  AdminModel({
    required this.id,
    required this.password,
    required this.role,
    required this.createdAt,
  });

  factory AdminModel.fromMap(Map<String, dynamic> data) {
    return AdminModel(
      id: data['id']?.toString() ?? '',
      password: data['password']?.toString() ?? '',
      role: data['role']?.toString().toUpperCase() ?? 'MANAGER',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'password': password,
      'role': role.toUpperCase(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

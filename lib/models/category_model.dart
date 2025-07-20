  import 'package:cloud_firestore/cloud_firestore.dart';

  class CategoryModel {
    final String id;
    final String name;
    final int type;
    final String iconUrl;
    final DateTime createdAt;

    CategoryModel({
      required this.id,
      required this.name,
      required this.type,
      required this.iconUrl,
      required this.createdAt,
      
    });

    CategoryModel copyWith({
      String? id,
      String? name,
      int? type,
      String? iconUrl,
      DateTime? createdAt,
    }) {
      return CategoryModel(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        iconUrl: iconUrl ?? this.iconUrl,
        createdAt: createdAt ?? this.createdAt,
      );
    }

    factory CategoryModel.fromMap(Map<String, dynamic> data, String id) {
      return CategoryModel(
        id: id,
        name: data['name'] ?? '',
        type: data['type'] ?? 1,
        iconUrl: data['iconUrl'] ?? '',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    }

    Map<String, dynamic> toMap() {
      return {
        'name': name,
        'type': type,
        'iconUrl': iconUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };
    }

  }


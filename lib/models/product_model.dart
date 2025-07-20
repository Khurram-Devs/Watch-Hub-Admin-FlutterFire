import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final List<String> images;
  final num price;
  final num discountPercentage;
  final int inventoryCount;
  final num averageRating;
  final int totalRatings;
  final DocumentReference? brand;
  final List<DocumentReference> categories;
  final Map<String, dynamic> specs;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.images,
    required this.price,
    required this.discountPercentage,
    required this.inventoryCount,
    required this.averageRating,
    required this.totalRatings,
    this.brand,
    required this.categories,
    required this.specs,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      price: map['price'] ?? 0,
      discountPercentage: map['discountPercentage'] ?? 0,
      inventoryCount: map['inventoryCount'] ?? 0,
      averageRating: map['averageRating'] ?? 0,
      totalRatings: map['totalRatings'] ?? 0,
      brand: map['brand'] as DocumentReference?,
      categories: List<DocumentReference>.from(map['categories'] ?? []),
      specs: Map<String, dynamic>.from(map['specs'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'images': images,
      'price': price,
      'discountPercentage': discountPercentage,
      'inventoryCount': inventoryCount,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'brand': brand,
      'categories': categories,
      'specs': specs,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ProductModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    List<String>? images,
    num? price,
    num? discountPercentage,
    int? inventoryCount,
    num? averageRating,
    int? totalRatings,
    DocumentReference? brand,
    List<DocumentReference>? categories,
    Map<String, dynamic>? specs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      images: images ?? this.images,
      price: price ?? this.price,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      inventoryCount: inventoryCount ?? this.inventoryCount,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      brand: brand ?? this.brand,
      categories: categories ?? this.categories,
      specs: specs ?? this.specs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

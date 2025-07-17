import 'package:flutter/material.dart';
import 'package:watch_hub_ep/utils/string_utils.dart';
import '../../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final String brandName;
  final String categoryNames;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.brandName,
    required this.categoryNames,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : null;

    return Card(
      color: const Color(0xFFF8FAFC),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                  ),
                )
              : const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                capitalizeEachWord(product.title),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (product.subtitle.isNotEmpty)
                Text(
                  capitalizeEachWord(product.subtitle),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${(product.price * (1 - product.discountPercentage / 100)).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
    const SizedBox(height: 12),

    /// 🔽 ADDED DESCRIPTION HERE
    if (product.description.isNotEmpty)
      Text(
        capitalizeEachWord(product.description),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 14,
          height: 1.4,
        ),
      ),

    const SizedBox(height: 12),
    Row(
      children: [
        Expanded(child: _info('Brand', capitalize(brandName))),
        Expanded(child: _info('Stock', '${product.inventoryCount}')),
      ],
    ),
    const SizedBox(height: 8),
    Row(
      children: [
        Expanded(
          child: _info(
            'Rating',
            '${product.averageRating}★',
          ),
        ),
        Expanded(child: _info('Categories', capitalizeEachWord(categoryNames))),
      ],
    ),
    const SizedBox(height: 12),
    Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit),
          label: const Text('Edit'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete),
          label: const Text('Delete'),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    ),
  ],
),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

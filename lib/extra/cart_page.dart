import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartPage({super.key, required this.cartItems});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Checkout function
  void checkoutCart() async {
    final _userId = FirebaseAuth.instance.currentUser?.uid ?? "guest";

    if (widget.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add products first.')),
      );
      return;
    }

    try {
      DatabaseReference checkoutRef =
          FirebaseDatabase.instance.ref().child('checkout/$_userId');
      String checkoutKey = checkoutRef.push().key ?? '';

      await checkoutRef.child(checkoutKey).set({
        'items': widget.cartItems,
        'timestamp': DateTime.now().toIso8601String(),
      });

      setState(() {
        widget.cartItems.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkout successful!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    }
  }

  void updateQuantity(int index, int delta) {
    setState(() {
      final currentQty = widget.cartItems[index]['quantity'] ?? 1;
      final newQty = currentQty + delta;
      if (newQty > 0) {
        widget.cartItems[index]['quantity'] = newQty;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.cartItems.isEmpty
                ? const Center(child: Text('Your cart is empty.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final product = widget.cartItems[index];
                      return Card(
                        elevation: 6,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(product['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rate: ${product['rate']}'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('Quantity:'),
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () =>
                                        updateQuantity(index, -1),
                                  ),
                                  Text('${product['quantity'] ?? 1}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () =>
                                        updateQuantity(index, 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                widget.cartItems.removeAt(index);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Item removed from cart')),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (widget.cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: checkoutCart,
                icon: const Icon(Icons.check_circle),
                label: const Text('Checkout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

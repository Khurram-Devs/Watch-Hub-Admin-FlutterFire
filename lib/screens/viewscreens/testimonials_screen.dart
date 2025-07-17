import 'package:flutter/material.dart';
import 'package:watch_hub_ep/models/testimonial_model.dart';
import 'package:watch_hub_ep/services/testimonial_service.dart';
import 'package:watch_hub_ep/widgets/layout/app_drawer.dart';
import 'package:watch_hub_ep/widgets/layout/app_bottom_navbar.dart';

class TestimonialsScreen extends StatefulWidget {
  const TestimonialsScreen({super.key});

  @override
  State<TestimonialsScreen> createState() => _TestimonialsScreenState();
}

class _TestimonialsScreenState extends State<TestimonialsScreen> {
  List<TestimonialModel> _testimonials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTestimonials();
  }

  Future<void> _loadTestimonials() async {
    setState(() => _isLoading = true);
    final testimonials = await TestimonialService.fetchAll();
    setState(() {
      _testimonials = testimonials;
      _isLoading = false;
    });
  }

  Future<void> _toggleStatus(TestimonialModel testimonial) async {
    await TestimonialService.toggleStatus(testimonial.id, testimonial.status);
    _loadTestimonials();
  }

  Future<void> _deleteTestimonial(TestimonialModel testimonial) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Testimonial"),
        content: Text("Are you sure you want to delete this testimonial?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirm == true) {
      await TestimonialService.deleteTestimonial(testimonial.id);
      _loadTestimonials();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _testimonials.isEmpty
              ? const Center(child: Text("No testimonials found."))
              : ListView.builder(
                  itemCount: _testimonials.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (_, i) {
                    final t = _testimonials[i];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(t.testimonial),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("Status: ${t.status == 1 ? "Visible" : "Hidden"}"),
                            Text("Created: ${t.createdAt.toDate().toLocal()}"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(t.status == 1 ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.blue),
                              onPressed: () => _toggleStatus(t),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTestimonial(t),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

    );
  }
}

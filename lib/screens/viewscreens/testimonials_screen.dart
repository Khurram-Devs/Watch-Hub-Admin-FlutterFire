import 'package:flutter/material.dart';
import 'package:watch_hub_ep/models/testimonial_model.dart';
import 'package:watch_hub_ep/services/testimonial_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:watch_hub_ep/utils/string_utils.dart';

class TestimonialsScreen extends StatefulWidget {
  const TestimonialsScreen({super.key});

  @override
  State<TestimonialsScreen> createState() => _TestimonialsScreenState();
}

class _TestimonialsScreenState extends State<TestimonialsScreen> {
  List<TestimonialModel> _testimonials = [];
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _userProfiles = {};

  @override
  void initState() {
    super.initState();
    _loadTestimonials();
  }

  Future<void> _loadTestimonials() async {
    setState(() => _isLoading = true);
    final testimonials = await TestimonialService.fetchAll();

    final userDataFutures = testimonials.map((testimonial) async {
      final userSnap = await testimonial.userRef.get();
      final userData = userSnap.data() as Map<String, dynamic>?;
      if (userData != null) {
        _userProfiles[testimonial.id] = {
          'fullName': userData['fullName'] ?? '',
          'email': userData['email'] ?? '',
          'avatarUrl': userData['avatarUrl'] ?? '',
        };
      }
    });

    await Future.wait(userDataFutures);

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
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Testimonial"),
            content: const Text(
              "Are you sure you want to delete this testimonial?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _testimonials.isEmpty
              ? const Center(child: Text("No testimonials found."))
              : ListView.builder(
                itemCount: _testimonials.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (_, i) {
                  final t = _testimonials[i];
                  final user = _userProfiles[t.id];
                  final avatarUrl = user?['avatarUrl'] ?? '';
                  final name = user?['fullName'] ?? 'Unknown';
                  final email = user?['email'] ?? '';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage:
                                    avatarUrl.isNotEmpty
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                radius: 24,
                                child:
                                    avatarUrl.isEmpty
                                        ? const Icon(Icons.person)
                                        : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      capitalizeEachWord(name),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  t.status == 1
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _toggleStatus(t),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteTestimonial(t),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            capitalize(t.testimonial),
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: "Status: ",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    TextSpan(
                                      text:
                                          t.status == 1 ? "Visible" : "Hidden",
                                      style: TextStyle(
                                        color:
                                            t.status == 1
                                                ? Colors.green
                                                : Colors.redAccent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                timeago.format(t.createdAt.toDate()),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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

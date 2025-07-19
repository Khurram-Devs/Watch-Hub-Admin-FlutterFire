import 'package:flutter/material.dart';
import 'package:watch_hub_ep/models/faq_model.dart';
import 'package:watch_hub_ep/services/faq_service.dart';
import 'package:watch_hub_ep/utils/string_utils.dart';

class ProductFAQScreen extends StatefulWidget {
  const ProductFAQScreen({super.key});

  @override
  State<ProductFAQScreen> createState() => _ProductFAQScreenState();
}

class _ProductFAQScreenState extends State<ProductFAQScreen> {
  List<FAQModel> _faqs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  Future<void> _loadFAQs() async {
    setState(() => _isLoading = true);
    _faqs = await FAQService.fetchAll();
    setState(() => _isLoading = false);
  }

  Future<void> _showFAQDialog({FAQModel? faqToEdit}) async {
    final questionController = TextEditingController(
      text: faqToEdit?.question ?? '',
    );
    final answerController = TextEditingController(
      text: faqToEdit?.answer ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(faqToEdit != null ? 'Edit FAQ' : 'Add FAQ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(labelText: 'Question'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: answerController,
                  decoration: const InputDecoration(labelText: 'Answer'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final question = questionController.text.trim();
                  final answer = answerController.text.trim();
                  if (question.isEmpty || answer.isEmpty) return;

                  if (faqToEdit != null) {
                    await FAQService.updateFAQ(
                      faqToEdit.id,
                      FAQModel(
                        id: faqToEdit.id,
                        question: question,
                        answer: answer,
                      ),
                    );
                  } else {
                    await FAQService.createFAQ(
                      FAQModel(id: '', question: question, answer: answer),
                    );
                  }

                  Navigator.pop(context, true);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result == true) _loadFAQs();
  }

  Future<void> _deleteFAQ(FAQModel faq) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete FAQ"),
            content: Text('Delete "${faq.question}"?'),
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
      await FAQService.deleteFAQ(faq.id);
      _loadFAQs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _faqs.isEmpty
              ? const Center(child: Text("No FAQs found."))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _faqs.length,
                itemBuilder: (_, i) {
                  final faq = _faqs[i];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(capitalize(faq.question)),
                      subtitle: Text(capitalize(faq.answer)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showFAQDialog(faqToEdit: faq),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteFAQ(faq),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFAQDialog(),
        backgroundColor: const Color(0xFF5B8A9A),
        child: const Icon(Icons.add),
      ),
    );
  }
}

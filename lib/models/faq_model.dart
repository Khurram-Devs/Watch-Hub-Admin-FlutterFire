import 'package:cloud_firestore/cloud_firestore.dart';

class FAQModel {
  final String id;
  final String question;
  final String answer;

  FAQModel({required this.id, required this.question, required this.answer});

  factory FAQModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FAQModel(
      id: doc.id,
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'question': question, 'answer': answer};
  }
}

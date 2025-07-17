import 'package:flutter/material.dart';
import 'package:watch_hub_ep/models/promo_code_model.dart';
import 'package:watch_hub_ep/services/promo_code_service.dart';

class AddPromoCodeScreen extends StatefulWidget {
  final PromoCodeModel? promoToEdit;
  const AddPromoCodeScreen({super.key, this.promoToEdit});

  @override
  State<AddPromoCodeScreen> createState() => _AddPromoCodeScreenState();
}

class _AddPromoCodeScreenState extends State<AddPromoCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _percentController = TextEditingController();
  final _limitController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.promoToEdit != null) {
      _titleController.text = widget.promoToEdit!.title;
      _codeController.text = widget.promoToEdit!.code;
      _percentController.text = widget.promoToEdit!.discountPercent.toString();
      _limitController.text = widget.promoToEdit!.limit;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final model = PromoCodeModel(
      id: widget.promoToEdit?.id ?? '',
      title: _titleController.text.trim(),
      code: _codeController.text.trim(),
      discountPercent: int.tryParse(_percentController.text.trim()) ?? 0,
      limit: _limitController.text.trim(),
      usedTimes: widget.promoToEdit?.usedTimes ?? 0,
    );

    if (widget.promoToEdit == null) {
      await PromoCodeService.create(model);
    } else {
      await PromoCodeService.update(model.id, model);
    }

    setState(() => _isSubmitting = false);
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _percentController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.promoToEdit == null ? "Add Promo Code" : "Edit Promo Code"),
        backgroundColor: const Color(0xFF5B8A9A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: "Code"),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _percentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Discount %"),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _limitController,
                decoration: const InputDecoration(labelText: "Limit"),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? "Saving..." : "Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

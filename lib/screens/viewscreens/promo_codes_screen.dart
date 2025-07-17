import 'package:flutter/material.dart';
import 'package:watch_hub_ep/models/promo_code_model.dart';
import 'package:watch_hub_ep/services/promo_code_service.dart';
import 'package:watch_hub_ep/utils/string_utils.dart';
import 'package:watch_hub_ep/widgets/layout/app_bottom_navbar.dart';
import 'package:watch_hub_ep/widgets/layout/app_drawer.dart';
import '../addscreens/add_promo_code_screen.dart';

class PromoCodesScreen extends StatefulWidget {
  const PromoCodesScreen({super.key});

  @override
  State<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends State<PromoCodesScreen> {
  List<PromoCodeModel> _codes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    setState(() => _isLoading = true);
    _codes = await PromoCodeService.fetchAll();
    setState(() => _isLoading = false);
  }

  Future<void> _delete(PromoCodeModel model) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Promo Code"),
        content: Text("Are you sure you want to delete \"${model.title}\"?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirm == true) {
      await PromoCodeService.delete(model.id);
      _loadCodes();
    }
  }

  void _edit(PromoCodeModel model) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPromoCodeScreen(promoToEdit: model)),
    );
    if (updated == true) _loadCodes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _codes.isEmpty
              ? const Center(child: Text("No promo codes found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _codes.length,
                  itemBuilder: (_, i) {
                    final p = _codes[i];
                    return Card(
                      child: ListTile(
                        title: Text(capitalizeEachWord(p.title)),
                        subtitle: Text("Code: ${p.code} • ${p.discountPercent}% off • Limit: ${p.limit} • Used: ${p.usedTimes}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _edit(p)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(p)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPromoCodeScreen()),
          );
          if (created == true) _loadCodes();
        },
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF5B8A9A),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SpecsEditor extends StatefulWidget {
  final Map<String, dynamic> initialSpecs;
  final void Function(Map<String, dynamic>) onSpecsChanged;

  const SpecsEditor({super.key, required this.initialSpecs, required this.onSpecsChanged});

  @override
  State<SpecsEditor> createState() => _SpecsEditorState();
}

class _SpecsEditorState extends State<SpecsEditor> {
  final List<TextEditingController> _keys = [];
  final List<TextEditingController> _values = [];

  @override
  void initState() {
    super.initState();
    widget.initialSpecs.forEach((k, v) {
      _keys.add(TextEditingController(text: k));
      _values.add(TextEditingController(text: v.toString()));
    });
  }

  void _addSpecField() {
    setState(() {
      _keys.add(TextEditingController());
      _values.add(TextEditingController());
    });
  }

  void _updateSpecs() {
    Map<String, dynamic> specs = {};
    for (int i = 0; i < _keys.length; i++) {
      final key = _keys[i].text.trim();
      final value = _values[i].text.trim();
      if (key.isNotEmpty) {
        specs[key] = value;
      }
    }
    widget.onSpecsChanged(specs);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Specifications", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _keys.length,
          itemBuilder: (context, index) => Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: TextField(
                    controller: _keys[index],
                    decoration: const InputDecoration(labelText: 'Key', border: OutlineInputBorder()),
                    onChanged: (_) => _updateSpecs(),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: TextField(
                    controller: _values[index],
                    decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
                    onChanged: (_) => _updateSpecs(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  setState(() {
                    _keys.removeAt(index);
                    _values.removeAt(index);
                    _updateSpecs();
                  });
                },
              )
            ],
          ),
        ),
        TextButton.icon(
          onPressed: _addSpecField,
          icon: const Icon(Icons.add),
          label: const Text("Add Spec"),
        )
      ],
    );
  }
}
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../providers/app_provider.dart";

class AddableDropdown extends StatelessWidget {
  final String type; // e.g. "expense_category", "payment_method", "shift_role", etc.
  final String labelText;
  final String? value;
  final ValueChanged<String?> onChanged;
  final IconData? prefixIcon;
  final String addOptionLabel;

  const AddableDropdown({
    super.key,
    required this.type,
    required this.labelText,
    required this.value,
    required this.onChanged,
    this.prefixIcon,
    this.addOptionLabel = "Add Custom Option",
  });

  static const String _addOptionKey = "__ADD_NEW_OPTION__";

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final options = provider.getDropdownOptions(type);
    final cs = Theme.of(context).colorScheme;

    // Ensure value is either in options or null
    final currentValue = (value != null && options.contains(value))
        ? value
        : (options.isNotEmpty ? options.first : null);

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
      isExpanded: true,
      items: [
        ...options.map((opt) => DropdownMenuItem(
              value: opt,
              child: Text(opt, overflow: TextOverflow.ellipsis),
            )),
        DropdownMenuItem(
          value: _addOptionKey,
          child: Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                "+ $addOptionLabel",
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
      onChanged: (selected) {
        if (selected == _addOptionKey) {
          _showAddOptionDialog(context, provider);
        } else if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }

  void _showAddOptionDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add to $labelText"),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: "e.g. New category or method",
            labelText: "$labelText Name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await provider.addDropdownOption(type, newName);
                onChanged(newName);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Add & Select"),
          ),
        ],
      ),
    );
  }
}

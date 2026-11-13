import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../providers/app_provider.dart";

class AddableDropdown extends StatelessWidget {
  final String
      type; // e.g. "expense_category", "payment_method", "shift_role", etc.
  final String labelText;
  final String? value;
  final ValueChanged<String?> onChanged;
  final IconData? prefixIcon;
  final String addOptionLabel;
  final bool allowColor;

  const AddableDropdown({
    super.key,
    required this.type,
    required this.labelText,
    required this.value,
    required this.onChanged,
    this.prefixIcon,
    this.addOptionLabel = "Add Custom Option",
    this.allowColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final options = provider.getDropdownOptions(type);
    final cs = Theme.of(context).colorScheme;

    // Ensure value is either in options or null
    final currentValue = (value != null && options.contains(value))
        ? value
        : (options.isNotEmpty ? options.first : null);

    return InkWell(
      onTap: () => _showOptionsSheet(context, provider, options, currentValue),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon:
              Icon(Icons.keyboard_arrow_down_rounded, color: cs.primary),
        ),
        child: Text(
          currentValue ?? "Select an option",
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: currentValue == null ? Theme.of(context).hintColor : null,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context, AppProvider provider,
      List<String> options, String? currentValue) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(labelText,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...options.map(
                      (option) => ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        selected: option == currentValue,
                        selectedTileColor: cs.primary.withValues(alpha: 0.12),
                        leading: Icon(
                          option == currentValue
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: option == currentValue ? cs.primary : null,
                        ),
                        title: Text(option),
                        onTap: () {
                          onChanged(option);
                          Navigator.pop(sheetContext);
                        },
                      ),
                    ),
                    const Divider(height: 20),
                    ListTile(
                      leading: Icon(Icons.add_circle_outline_rounded,
                          color: cs.primary),
                      title: Text("+ $addOptionLabel",
                          style: TextStyle(
                              color: cs.primary, fontWeight: FontWeight.bold)),
                      onTap: () => _showAddOptionDialog(context, provider),
                    ),
                    ListTile(
                      leading: Icon(Icons.tune_rounded, color: cs.primary),
                      title: Text("Manage options",
                          style: TextStyle(
                              color: cs.primary, fontWeight: FontWeight.bold)),
                      onTap: () => _showManageOptionsDialog(context, provider),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManageOptionsDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Manage $labelText"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: provider.getAllDropdownOptions(type).map((option) {
              final hidden = provider.isDropdownOptionHidden(type, option);
              return ListTile(
                dense: true,
                title: Text(option),
                trailing: Switch(
                  value: !hidden,
                  onChanged: (visible) =>
                      provider.setDropdownOptionHidden(type, option, !visible),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  void _showAddOptionDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    int? selectedColor;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add to $labelText"),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: "e.g. New category or method",
                  labelText: "$labelText Name",
                ),
              ),
              if (allowColor) ...[
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Category color"),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final color in _categoryColors)
                      InkWell(
                        onTap: () =>
                            setState(() => selectedColor = color.toARGB32()),
                        borderRadius: BorderRadius.circular(20),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: color,
                          child: selectedColor == color.toARGB32()
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ],
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
                await provider.addDropdownOption(type, newName,
                    colorValue: selectedColor);
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

  static const _categoryColors = [
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFF6B7280),
  ];
}

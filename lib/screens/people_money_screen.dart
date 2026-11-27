import "dart:async";

import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import "../models/models.dart";
import "../providers/app_provider.dart";

class PeopleMoneyScreen extends StatefulWidget {
  const PeopleMoneyScreen({super.key});

  @override
  State<PeopleMoneyScreen> createState() => _PeopleMoneyScreenState();
}

class _PeopleMoneyScreenState extends State<PeopleMoneyScreen> {
  static const _relationships = ["Family", "Sister", "Friend", "Other"];
  static const _allMonths = "all";
  final _currency =
      NumberFormat.currency(locale: "en_IN", symbol: "৳", decimalDigits: 2);
  String _selectedMonth = _allMonths;
  bool _showHiddenEntries = false;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<AppProvider>().fetchPeopleMoneyEntries());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final entries = provider.peopleMoneyEntries;
    final monthOptions = entries
        .map((entry) => DateFormat("yyyy-MM").format(entry.date))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final selectedMonth =
        monthOptions.contains(_selectedMonth) || _selectedMonth == _allMonths
            ? _selectedMonth
            : _allMonths;
    final filteredEntries = selectedMonth == _allMonths
        ? entries
        : entries
            .where((entry) =>
                DateFormat("yyyy-MM").format(entry.date) == selectedMonth)
            .toList();
    final historyEntries = filteredEntries
        .where((entry) => entry.isHidden == _showHiddenEntries)
        .toList();
    final given = filteredEntries
        .where((entry) => entry.direction == "given")
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final taken = filteredEntries
        .where((entry) => entry.direction == "taken")
        .fold<double>(0, (sum, entry) => sum + entry.amount);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Money with People",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Track money you give to or take from people in Bangladeshi Taka.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMonth,
                      decoration: const InputDecoration(
                        labelText: "Month",
                        prefixIcon: Icon(Icons.calendar_month_rounded),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: _allMonths,
                          child: Text("All months"),
                        ),
                        for (final month in monthOptions)
                          DropdownMenuItem(
                            value: month,
                            child: Text(
                              DateFormat("MMMM yyyy")
                                  .format(DateTime.parse("$month-01")),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedMonth = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _TotalCard(
                            label: "Given",
                            amount: _currency.format(given),
                            icon: Icons.call_made_rounded,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TotalCard(
                            label: "Taken",
                            amount: _currency.format(taken),
                            icon: Icons.call_received_rounded,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Card(
                      margin: EdgeInsets.zero,
                      child: ExpansionTile(
                        leading: const Icon(Icons.pie_chart_outline_rounded),
                        title: const Text(
                          "Totals by relationship",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          for (final relationship in _relationships)
                            ListTile(
                              dense: true,
                              title: Text(relationship),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Given: ${_currency.format(_relationshipTotal(filteredEntries, relationship, "given"))}",
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "Taken: ${_currency.format(_relationshipTotal(filteredEntries, relationship, "taken"))}",
                                    style: const TextStyle(
                                      color: Color(0xFF6366F1),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "History",
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(
                            () => _showHiddenEntries = !_showHiddenEntries,
                          ),
                          icon: Icon(
                            _showHiddenEntries
                                ? Icons.list_alt_rounded
                                : Icons.visibility_off_outlined,
                          ),
                          label: Text(
                            _showHiddenEntries
                                ? "Show active"
                                : "Hidden (${entries.where((entry) => entry.isHidden).length})",
                          ),
                        ),
                        IconButton(
                          tooltip: "Refresh",
                          onPressed: provider.isPeopleMoneyLoading
                              ? null
                              : () => unawaited(
                                    provider.fetchPeopleMoneyEntries(),
                                  ),
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildHistory(context, provider, historyEntries),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_showHiddenEntries) {
            setState(() => _showHiddenEntries = false);
          }
          _showEntrySheet(context, provider);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text("Add Entry"),
      ),
    );
  }

  double _relationshipTotal(
    List<PeopleMoneyEntry> entries,
    String relationship,
    String direction,
  ) =>
      entries
          .where((entry) =>
              entry.relationship == relationship &&
              entry.direction == direction)
          .fold<double>(0, (sum, entry) => sum + entry.amount);

  Widget _buildHistory(
    BuildContext context,
    AppProvider provider,
    List<PeopleMoneyEntry> entries,
  ) {
    if (provider.isPeopleMoneyLoading && provider.peopleMoneyEntries.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.peopleMoneyError != null &&
        provider.peopleMoneyEntries.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 40),
                const SizedBox(height: 12),
                const Text("Could not load money history."),
                const SizedBox(height: 8),
                Text(
                  provider.peopleMoneyError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      unawaited(provider.fetchPeopleMoneyEntries()),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Try again"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.peopleMoneyEntries.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_alt_outlined,
                    size: 56, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  _showHiddenEntries
                      ? "No hidden entries yet"
                      : "No entries yet",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _showHiddenEntries
                      ? "Entries you hide will appear here."
                      : "Add money you have given to or taken from someone.",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (entries.isEmpty) {
      final hasEntriesInCurrentView = provider.peopleMoneyEntries
          .any((entry) => entry.isHidden == _showHiddenEntries);
      final emptyMessage = hasEntriesInCurrentView
          ? "No entries for this month."
          : _showHiddenEntries
              ? "No hidden entries yet."
              : "No visible entries.";
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(emptyMessage),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index.isOdd) return const SizedBox(height: 8);
            return _buildEntryCard(context, entries[index ~/ 2]);
          },
          childCount: entries.length * 2 - 1,
        ),
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, PeopleMoneyEntry entry) {
    final isGiven = entry.direction == "given";
    final color = isGiven ? const Color(0xFF10B981) : const Color(0xFF6366F1);
    final person = entry.personName.isEmpty
        ? entry.relationship
        : "${entry.personName} · ${entry.relationship}";

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => _showEntrySheet(
          context,
          context.read<AppProvider>(),
          initialEntry: entry,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            isGiven ? Icons.call_made_rounded : Icons.call_received_rounded,
            color: color,
          ),
        ),
        title: Text(
          "${isGiven ? "Given to" : "Taken from"} $person",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          "${DateFormat("dd MMM yyyy").format(entry.date)}"
          "${entry.notes.isEmpty ? "" : " · ${entry.notes}"}",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currency.format(entry.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: "Entry options",
              onSelected: (value) {
                if (value == "hide" || value == "unhide") {
                  _setEntryHidden(context, entry, value == "hide");
                } else if (value == "delete") {
                  _confirmDeleteEntry(context, entry);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: entry.isHidden ? "unhide" : "hide",
                  child: Row(
                    children: [
                      Icon(
                        entry.isHidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.isHidden ? "Unhide" : "Hide"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "delete",
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Delete"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setEntryHidden(
    BuildContext context,
    PeopleMoneyEntry entry,
    bool isHidden,
  ) async {
    try {
      await context
          .read<AppProvider>()
          .setPeopleMoneyEntryHidden(entry, isHidden);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                "Could not ${isHidden ? "hide" : "unhide"} entry: $error",
              ),
            ),
          );
      }
    }
  }

  Future<void> _confirmDeleteEntry(
    BuildContext context,
    PeopleMoneyEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Entry"),
        content: Text("Delete the entry for ${entry.personName}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<AppProvider>().deletePeopleMoneyEntry(entry.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text("Could not delete entry: $error")),
          );
      }
    }
  }

  Future<void> _showEntrySheet(BuildContext context, AppProvider provider,
      {PeopleMoneyEntry? initialEntry}) async {
    final nameController =
        TextEditingController(text: initialEntry?.personName ?? "");
    final amountController =
        TextEditingController(text: initialEntry?.amount.toString() ?? "");
    final notesController =
        TextEditingController(text: initialEntry?.notes ?? "");
    final formKey = GlobalKey<FormState>();
    var selectedDate = initialEntry?.date ?? DateTime.now();
    var direction = initialEntry?.direction ?? "given";
    var relationship = initialEntry?.relationship ?? "Family";
    final relationships = _relationships.contains(relationship)
        ? _relationships
        : [..._relationships, relationship];
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    initialEntry == null
                        ? "Add Money Entry"
                        : "Edit Money Entry",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: direction,
                    decoration: const InputDecoration(
                      labelText: "Transaction",
                      prefixIcon: Icon(Icons.swap_horiz_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "given",
                        child: Text("I gave money"),
                      ),
                      DropdownMenuItem(
                        value: "taken",
                        child: Text("I took money"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => direction = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: relationship,
                    decoration: const InputDecoration(
                      labelText: "Relationship",
                      prefixIcon: Icon(Icons.people_outline_rounded),
                    ),
                    items: relationships
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => relationship = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Person's name *",
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? "Enter the person's name"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Amount (৳) *",
                      prefixIcon: Icon(Icons.currency_exchange_rounded),
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? "");
                      if (amount == null || !amount.isFinite || amount <= 0) {
                        return "Enter an amount greater than zero";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setSheetState(() => selectedDate = pickedDate);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Transaction date",
                        prefixIcon: Icon(Icons.calendar_month_rounded),
                        suffixIcon: Icon(Icons.edit_calendar_rounded),
                      ),
                      child:
                          Text(DateFormat("dd MMM yyyy").format(selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: "Note (optional)",
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => saving = true);
                              final updatedEntry = PeopleMoneyEntry(
                                id: initialEntry?.id ?? "",
                                personName: nameController.text.trim(),
                                relationship: relationship,
                                direction: direction,
                                amount: double.parse(amountController.text),
                                date: selectedDate,
                                notes: notesController.text.trim(),
                                isHidden: initialEntry?.isHidden ?? false,
                              );
                              try {
                                if (initialEntry == null) {
                                  await provider
                                      .addPeopleMoneyEntry(updatedEntry);
                                } else {
                                  await provider
                                      .updatePeopleMoneyEntry(updatedEntry);
                                }
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              } catch (error) {
                                if (sheetContext.mounted) {
                                  setSheetState(() => saving = false);
                                  ScaffoldMessenger.of(sheetContext)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "Could not save entry: $error"),
                                      ),
                                    );
                                }
                              }
                            },
                      child: Text(
                        saving
                            ? "Saving..."
                            : initialEntry == null
                                ? "Save Entry"
                                : "Update Entry",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    nameController.dispose();
    amountController.dispose();
    notesController.dispose();
  }
}

class _TotalCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _TotalCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

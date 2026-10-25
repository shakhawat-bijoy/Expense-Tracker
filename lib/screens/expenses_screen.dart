import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import "../models/models.dart";
import "../providers/app_provider.dart";
import "../widgets/addable_dropdown.dart";
import "../widgets/month_navigation_bar.dart";

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final expenses = provider.filteredExpenses;
    final currency = NumberFormat.currency(locale: "de_DE", symbol: "€");
    final dateFormat = DateFormat("dd MMM yyyy");
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final categoryOptions = provider.getDropdownOptions("expense_category");

    return Scaffold(
      body: Column(
        children: [
          // ─── Reusable Month Navigation Bar ────────────────────────────
          const MonthNavigationBar(),

          // ─── Search & Filter Bar ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              children: [
                // Search Box
                TextField(
                  onChanged: (val) => provider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: "Search items, categories, or notes...",
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: provider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => provider.setSearchQuery(""),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                // Dynamic Category Filter Chips + Date Filter
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: "All",
                        selected: provider.selectedCategory == "All",
                        onTap: () => provider.setCategory("All"),
                      ),
                      ...categoryOptions.map((cat) => _FilterChip(
                            label: cat,
                            selected: provider.selectedCategory == cat,
                            onTap: () => provider.setCategory(cat),
                          )),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: Icon(
                          Icons.date_range_rounded,
                          size: 16,
                          color: provider.filterStartDate != null
                              ? cs.primary
                              : null,
                        ),
                        label: Text(
                          provider.filterStartDate != null
                              ? "${DateFormat("dd/MM").format(provider.filterStartDate!)} - ${DateFormat("dd/MM").format(provider.filterEndDate ?? DateTime.now())}"
                              : "Date Range",
                          style: TextStyle(
                            fontSize: 12,
                            color: provider.filterStartDate != null
                                ? cs.primary
                                : null,
                          ),
                        ),
                        onPressed: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDateRange: provider.filterStartDate != null
                                ? DateTimeRange(
                                    start: provider.filterStartDate!,
                                    end: provider.filterEndDate ?? DateTime.now(),
                                  )
                                : null,
                          );
                          if (range != null) {
                            provider.setDateRange(range.start, range.end);
                          }
                        },
                      ),
                      if (provider.filterStartDate != null ||
                          provider.selectedCategory != "All" ||
                          provider.searchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ActionChip(
                            avatar: const Icon(Icons.clear_all_rounded, size: 16),
                            label: const Text("Clear Filters",
                                style: TextStyle(fontSize: 12)),
                            onPressed: () => provider.clearFilters(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Expenses List ────────────────────────────────────────────
          Expanded(
            child: expenses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No expenses in ${provider.formattedSelectedMonth}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap the + button to record a new expense. Everything is updatable.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded),
                            label: const Text("Add First Expense"),
                            onPressed: () => _showAddExpenseModal(context),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: provider.fetchAllData,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        final catColor = _categoryColor(expense.category);

                        return Dismissible(
                          key: Key(expense.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Delete Expense"),
                                content: Text("Delete '${expense.item}'?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text("Delete",
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) =>
                              provider.removeExpense(expense.id),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: catColor.withValues(alpha: 0.12),
                                child: Icon(
                                  _categoryIcon(expense.category),
                                  color: catColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                expense.item,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        expense.category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: catColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "• ${expense.paymentMethod}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "• ${dateFormat.format(expense.date)}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (expense.notes.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      expense.notes,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.grey.shade500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    currency.format(expense.price),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_outlined,
                                      size: 16, color: Colors.grey),
                                ],
                              ),
                              onTap: () =>
                                  _showAddExpenseModal(context, expense: expense),
                            ),
                          ),
                        ).animate().fadeIn(duration: 250.ms, delay: (index * 30).ms);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseModal(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Add Expense"),
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context, {Expense? expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ExpenseFormSheet(expense: expense),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case "Groceries":
        return const Color(0xFF10B981);
      case "Drinks":
        return const Color(0xFFF59E0B);
      case "Transport":
        return const Color(0xFF3B82F6);
      case "Restaurant":
        return const Color(0xFFEF4444);
      case "Health":
        return const Color(0xFFEC4899);
      case "Utility":
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case "Groceries":
        return Icons.shopping_basket_rounded;
      case "Drinks":
        return Icons.local_cafe_rounded;
      case "Transport":
        return Icons.directions_bus_rounded;
      case "Restaurant":
        return Icons.restaurant_rounded;
      case "Health":
        return Icons.medical_services_rounded;
      case "Utility":
        return Icons.bolt_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: cs.primary.withValues(alpha: 0.15),
        checkmarkColor: cs.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ─── Add / Edit Expense Sheet ──────────────────────────────────────────────

class _ExpenseFormSheet extends StatefulWidget {
  final Expense? expense;
  const _ExpenseFormSheet({this.expense});

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  final _itemCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _category = "Groceries";
  String _paymentMethod = "Pocket (Cash)";
  DateTime _selectedDate = DateTime.now();
  bool _isEditing = false;
  bool _deductFromAccount = true;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _isEditing = true;
      _itemCtrl.text = widget.expense!.item;
      _priceCtrl.text = widget.expense!.price.toString();
      _notesCtrl.text = widget.expense!.notes;
      _category = widget.expense!.category;
      _paymentMethod = widget.expense!.paymentMethod;
      _selectedDate = widget.expense!.date;
      _deductFromAccount = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? "Edit Expense" : "New Expense",
                  style:
                      const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    onPressed: () async {
                      final provider = context.read<AppProvider>();
                      await provider.removeExpense(widget.expense!.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _itemCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: "Item Name *",
                hintText: "e.g. Rice 2Kg, Bus Ticket",
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
            ),
            const SizedBox(height: 14),
            AddableDropdown(
              type: "expense_category",
              labelText: "Category",
              value: _category,
              prefixIcon: Icons.category_outlined,
              addOptionLabel: "Add Category",
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 14),
            AddableDropdown(
              type: "payment_method",
              labelText: "Payment Method",
              value: _paymentMethod,
              prefixIcon: Icons.payment_rounded,
              addOptionLabel: "Add Payment Method",
              onChanged: (val) {
                if (val != null) setState(() => _paymentMethod = val);
              },
            ),
            const SizedBox(height: 14),
            if (!_isEditing)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Deduct from Account Balance",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  _paymentMethod.toLowerCase().contains("bank")
                      ? "Deducts from Bank Account"
                      : "Deducts from Pocket Cash",
                  style: const TextStyle(fontSize: 11),
                ),
                value: _deductFromAccount,
                onChanged: (val) => setState(() => _deductFromAccount = val),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Price (€) *",
                prefixIcon: Icon(Icons.euro_rounded),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Date",
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(DateFormat("dd MMMM yyyy").format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Notes (Optional)",
                hintText: "Receipt details, store, etc.",
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded),
              label: Text(_isEditing ? "Update Expense" : "Save Expense"),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final item = _itemCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.replaceAll(",", ".")) ?? 0.0;

    if (item.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an item name")),
      );
      return;
    }
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid price")),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final expense = Expense(
      id: widget.expense?.id ?? "",
      item: item,
      category: _category,
      paymentMethod: _paymentMethod,
      price: price,
      date: _selectedDate,
      notes: _notesCtrl.text.trim(),
      month: provider.selectedMonth,
    );

    if (_isEditing) {
      provider.updateExpense(expense);
    } else {
      provider.addExpense(expense, deductFromAccount: _deductFromAccount);
    }
    Navigator.pop(context);
  }
}

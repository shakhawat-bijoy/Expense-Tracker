import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import "../models/models.dart";
import "../providers/app_provider.dart";
import "../widgets/addable_dropdown.dart";
import "../widgets/month_navigation_bar.dart";

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  String _filter = "All"; // "All", "Pending", "Settled"

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDarkMode;
    final debts = provider.debts;

    final filteredDebts = debts.where((d) {
      if (_filter == "Pending") return !d.isSettled;
      if (_filter == "Settled") return d.isSettled;
      return true;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          const MonthNavigationBar(),

          // Payoff Summary Hero Card
          _buildPayoffSummaryCard(context, provider),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip("All", debts.length),
                const SizedBox(width: 8),
                _buildFilterChip("Pending", debts.where((d) => !d.isSettled).length),
                const SizedBox(width: 8),
                _buildFilterChip("Settled", debts.where((d) => d.isSettled).length),
              ],
            ),
          ),

          // Debts List or Empty State
          Expanded(
            child: filteredDebts.isEmpty
                ? _buildEmptyState(context, provider)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredDebts.length,
                    itemBuilder: (context, index) {
                      final debt = filteredDebts[index];
                      return _buildDebtCard(context, debt, provider, isDark, index);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditDebtModal(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Add Debt"),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _filter == label;
    return ChoiceChip(
      label: Text("$label ($count)"),
      selected: isSelected,
      onSelected: (val) => setState(() => _filter = label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildPayoffSummaryCard(BuildContext context, AppProvider provider) {
    final isDark = provider.isDarkMode;
    final total = provider.totalDebtOwed;
    final paid = provider.totalDebtPaid;
    final remaining = provider.remainingDebtOwed;
    final progress = provider.debtPayoffProgress;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF311042)]
              : [const Color(0xFF4338CA), const Color(0xFF6B21A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.credit_card_off_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Debt Payoff Tracker",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${progress.toStringAsFixed(1)}% Paid",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPayoffMetric("Total Debt", "€${total.toStringAsFixed(2)}", Colors.white70),
              _buildPayoffMetric("Paid Off", "€${paid.toStringAsFixed(2)}", const Color(0xFF34D399)),
              _buildPayoffMetric("Remaining", "€${remaining.toStringAsFixed(2)}", const Color(0xFFF87171)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildPayoffMetric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDebtCard(
    BuildContext context,
    DebtItem debt,
    AppProvider provider,
    bool isDark,
    int index,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isSettled = debt.isSettled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSettled
              ? Colors.green.withValues(alpha: 0.3)
              : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
        ),
      ),
      child: InkWell(
        onTap: () => _showAddOrEditDebtModal(context, debt: debt),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (debt.personName.isNotEmpty)
                          Text(
                            "To: ${debt.personName} • ${debt.category}",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSettled
                          ? Colors.green.withValues(alpha: 0.15)
                          : (debt.paidAmount > 0
                              ? Colors.amber.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isSettled ? "Settled" : (debt.paidAmount > 0 ? "Partial" : "Pending"),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSettled
                            ? Colors.green
                            : (debt.paidAmount > 0 ? Colors.amber.shade700 : Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Remaining: €${debt.remainingAmount.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSettled ? Colors.grey : Colors.redAccent,
                        ),
                      ),
                      Text(
                        "Total: €${debt.amount.toStringAsFixed(2)} (Paid: €${debt.paidAmount.toStringAsFixed(2)})",
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                  if (!isSettled)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showMakePaymentModal(context, debt),
                      icon: const Icon(Icons.payments_rounded, size: 16),
                      label: const Text("Make Payment"),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (debt.paidPercent / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSettled ? Colors.green : cs.primary,
                  ),
                ),
              ),
              if (debt.dueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      "Due Date: ${DateFormat('dd MMM yyyy').format(debt.dueDate!)}",
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms);
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_satisfied_alt_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "No Debts to Pay Off",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "You are debt-free or haven't added any debts yet. Tap the 'Add Debt' button to track loans or balances to pay off.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOrEditDebtModal(BuildContext context, {DebtItem? debt}) {
    final provider = context.read<AppProvider>();
    final isEditing = debt != null;

    final titleCtrl = TextEditingController(text: debt?.title ?? "");
    final personCtrl = TextEditingController(text: debt?.personName ?? "");
    final amountCtrl = TextEditingController(text: debt != null ? debt.amount.toString() : "");
    final notesCtrl = TextEditingController(text: debt?.notes ?? "");
    DateTime? dueDate = debt?.dueDate;
    String category = debt?.category ?? "Personal Loan";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: provider.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? "Edit Debt" : "Add Debt to Pay Off",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            onPressed: () async {
                              await provider.deleteDebt(debt.id);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: "Debt Title / Reason *",
                        hintText: "e.g. Car Loan, Credit Card, Loan from Mark",
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: personCtrl,
                      decoration: const InputDecoration(
                        labelText: "Creditor / Bank / Person Name",
                        hintText: "e.g. Chase Bank, John Doe",
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Total Amount Owed (€) *",
                        prefixIcon: Icon(Icons.euro_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AddableDropdown(
                      type: "debt_category",
                      labelText: "Debt Category",
                      value: category,
                      prefixIcon: Icons.category_outlined,
                      addOptionLabel: "Add Debt Category",
                      onChanged: (val) {
                        if (val != null) setModalState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setModalState(() => dueDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dueDate != null
                                  ? "Due: ${DateFormat('dd MMM yyyy').format(dueDate!)}"
                                  : "Set Due Date (Optional)",
                              style: TextStyle(
                                color: dueDate != null ? null : Colors.grey.shade600,
                              ),
                            ),
                            const Icon(Icons.calendar_today_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: "Notes (Optional)",
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                          if (title.isEmpty || amount <= 0) return;

                          if (isEditing) {
                            final updated = debt.copyWith(
                              title: title,
                              personName: personCtrl.text.trim(),
                              amount: amount,
                              category: category,
                              dueDate: dueDate,
                              notes: notesCtrl.text.trim(),
                            );
                            await provider.updateDebt(updated);
                          } else {
                            final newDebt = DebtItem(
                              id: "",
                              title: title,
                              personName: personCtrl.text.trim(),
                              amount: amount,
                              category: category,
                              dueDate: dueDate,
                              notes: notesCtrl.text.trim(),
                              month: provider.selectedMonth,
                            );
                            await provider.addDebt(newDebt);
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Text(isEditing ? "Update Debt" : "Save Debt"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMakePaymentModal(BuildContext context, DebtItem debt) {
    final provider = context.read<AppProvider>();
    final amountCtrl = TextEditingController();
    String deductFrom = "Pocket"; // "Pocket", "Bank Account", "None"

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: provider.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Make Payment on ${debt.title}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Remaining Balance: €${debt.remainingAmount.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Payment Amount (€) *",
                      hintText: "e.g. 50.00",
                      prefixIcon: Icon(Icons.euro_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Deduct Payment From Account:",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text("Pocket (€${provider.pocketBalance.toStringAsFixed(0)})"),
                        selected: deductFrom == "Pocket",
                        onSelected: (val) => setModalState(() => deductFrom = "Pocket"),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text("Bank (€${provider.bankBalance.toStringAsFixed(0)})"),
                        selected: deductFrom == "Bank Account",
                        onSelected: (val) => setModalState(() => deductFrom = "Bank Account"),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Don't Deduct"),
                        selected: deductFrom == "None",
                        onSelected: (val) => setModalState(() => deductFrom = "None"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final payAmt = double.tryParse(amountCtrl.text) ?? 0.0;
                        if (payAmt <= 0) return;

                        String? deductTarget;
                        if (deductFrom == "Pocket") deductTarget = "pocket";
                        if (deductFrom == "Bank Account") deductTarget = "bank";

                        await provider.payDebt(
                          id: debt.id,
                          amount: payAmt,
                          deductFrom: deductTarget,
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text("Confirm Payment"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

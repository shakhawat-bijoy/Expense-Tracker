import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import "../models/models.dart";
import "../providers/app_provider.dart";
import "../widgets/addable_dropdown.dart";
import "../widgets/month_navigation_bar.dart";
import "debts_screen.dart";

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final summary = provider.summary;
    final currency = NumberFormat.currency(locale: "de_DE", symbol: "€");
    final isDark = provider.isDarkMode;

    return RefreshIndicator(
      onRefresh: provider.fetchAllData,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ─── Month Navigation Bar ─────────────────────────────────────
          const MonthNavigationBar(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Hero Net Balance Card ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF312E81), const Color(0xFF4338CA)]
                          : [const Color(0xFF4338CA), const Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 18,
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
                          const Text(
                            "Month Net Flow",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              provider.formattedSelectedMonth,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currency.format(summary.netBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              icon: Icons.arrow_upward_rounded,
                              iconColor: const Color(0xFF34D399),
                              label: "Earned",
                              value: currency.format(summary.netEarnings),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 38,
                            color: Colors.white24,
                          ),
                          Expanded(
                            child: _MiniStat(
                              icon: Icons.arrow_downward_rounded,
                              iconColor: const Color(0xFFFBBF24),
                              label: "Spent",
                              value: currency.format(summary.totalExpenses),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 450.ms)
                    .slideY(begin: 0.05, end: 0),

                const SizedBox(height: 14),

                // ─── Pocket & Bank Account Balance Card ─────────────────
                _AccountsBalanceCard(
                  pocket: provider.pocketBalance,
                  bank: provider.bankBalance,
                  total: provider.totalLiquidFunds,
                  currency: currency,
                  isDark: isDark,
                  onEdit: () => _showAdjustAccountsModal(context, provider),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.05, end: 0),

                const SizedBox(height: 14),

                // ─── Monthly Budget Card ────────────────────────────────
                _MonthlyBudgetCard(
                  summary: summary,
                  currency: currency,
                  isDark: isDark,
                  onEditBudget: () => _showSetBudgetModal(context, provider),
                )
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.05, end: 0),

                const SizedBox(height: 14),

                // ─── Debt Payoff Card ───────────────────────────────────
                _DebtPayoffCard(
                  totalDebt: provider.totalDebtOwed,
                  paidDebt: provider.totalDebtPaid,
                  remainingDebt: provider.remainingDebtOwed,
                  progressPercent: provider.debtPayoffProgress,
                  currency: currency,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DebtsScreen()),
                    );
                  },
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05, end: 0),

                const SizedBox(height: 14),

                // ─── Status Overview Cards ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatusCard(
                        title: "Pending Shifts",
                        amount: currency.format(summary.pendingEarnings),
                        icon: Icons.hourglass_top_rounded,
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatusCard(
                        title: "Monthly Bills",
                        amount: currency.format(summary.totalFixedBills),
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 20),

                // ─── Quick Actions Bar ──────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text("Add Expense"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        onPressed: () => _showAddExpenseModal(context),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.work_outline_rounded, size: 18),
                        label: const Text("Log Shift"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        onPressed: () => _showAddShiftModal(context),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.account_balance_wallet_outlined,
                            size: 18),
                        label: const Text("Balances"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        onPressed: () =>
                            _showAdjustAccountsModal(context, provider),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.credit_card_off_outlined,
                            size: 18),
                        label: const Text("Debts"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const DebtsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── Empty State or Analytics ───────────────────────────
                if (summary.totalTransactions == 0 &&
                    summary.totalFixedBills == 0)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 54,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No data for ${provider.formattedSelectedMonth}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Input your expenses, shift earnings, or debts. All values are editable at any time.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms)
                else ...[
                  // ─── Daily Spending Trend ──────────────────────────────
                  if (summary.dailySpending.isNotEmpty) ...[
                    const _SectionHeader(title: "Spending Trend (This Month)"),
                    const SizedBox(height: 12),
                    _DailySpendingChart(
                      dailySpending: summary.dailySpending,
                      isDark: isDark,
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 24),
                  ],

                  // ─── Category Breakdown ───────────────────────────────
                  if (summary.categoryBreakdown.isNotEmpty) ...[
                    const _SectionHeader(title: "Category Allocation"),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children:
                            summary.categoryBreakdown.entries.map((entry) {
                          final percent = summary.totalExpenses > 0
                              ? entry.value / summary.totalExpenses
                              : 0.0;
                          return _CategoryRow(
                            category: entry.key,
                            amount: currency.format(entry.value),
                            percent: percent,
                            color: _categoryColor(entry.key),
                            icon: _categoryIcon(entry.key),
                            isDark: isDark,
                          );
                        }).toList(),
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 24),
                  ],

                  // ─── Recent Month Transactions ────────────────────────
                  const _SectionHeader(title: "Recent Entries (Tap to Edit)"),
                  const SizedBox(height: 12),
                  if (provider.expenses.isEmpty && provider.shifts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "No entries recorded for this month.",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    )
                  else ...[
                    ...provider.expenses.take(5).map((e) => _ExpenseTile(
                          expense: e,
                          currency: currency,
                          isDark: isDark,
                          onTap: () => _showEditExpenseModal(context, e),
                        )),
                    ...provider.shifts.take(5).map((s) => _ShiftTile(
                          shift: s,
                          currency: currency,
                          isDark: isDark,
                          onTap: () => _showEditShiftModal(context, s),
                        )),
                  ],
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Modals & Editors ───────────────────────────────────────────────────

  void _showSetBudgetModal(BuildContext context, AppProvider provider) {
    final ctrl = TextEditingController(
      text: provider.budget.amount > 0 ? provider.budget.amount.toString() : "",
    );
    final notesCtrl = TextEditingController(text: provider.budget.notes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Set Budget (${provider.formattedSelectedMonth})"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Monthly Budget (€) *",
                hintText: "e.g. 1200",
                prefixIcon: Icon(Icons.euro_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: "Notes (Optional)",
                hintText: "e.g. Living expenses & bills limit",
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(ctrl.text.replaceAll(",", "."));
              if (parsed != null && parsed >= 0) {
                provider.saveBudget(parsed, notes: notesCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save Budget"),
          ),
        ],
      ),
    );
  }

  void _showAdjustAccountsModal(BuildContext context, AppProvider provider) {
    final pocketCtrl = TextEditingController(
      text: provider.pocketBalance > 0
          ? provider.pocketBalance.toString()
          : (provider.pocketBalance == 0 ? "0" : ""),
    );
    final bankCtrl = TextEditingController(
      text: provider.bankBalance > 0
          ? provider.bankBalance.toString()
          : (provider.bankBalance == 0 ? "0" : ""),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          provider.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Edit Liquid Balances",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Update your current pocket cash and bank account balances anytime.",
              style: TextStyle(
                fontSize: 12,
                color:
                    provider.isDarkMode ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: pocketCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Pocket / Cash Balance (€)",
                prefixIcon: Icon(Icons.wallet_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: bankCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Bank Account Balance (€)",
                prefixIcon: Icon(Icons.account_balance_rounded),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final p =
                    double.tryParse(pocketCtrl.text.replaceAll(",", ".")) ??
                        0.0;
                final b =
                    double.tryParse(bankCtrl.text.replaceAll(",", ".")) ?? 0.0;
                await provider.saveAccounts(pocket: p, bank: b);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Update Balances"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context) {
    _showExpenseEditor(context);
  }

  void _showEditExpenseModal(BuildContext context, Expense expense) {
    _showExpenseEditor(context, expense: expense);
  }

  void _showExpenseEditor(BuildContext context, {Expense? expense}) {
    final provider = context.read<AppProvider>();
    final isEditing = expense != null;
    final itemCtrl = TextEditingController(text: isEditing ? expense.item : "");
    final priceCtrl =
        TextEditingController(text: isEditing ? expense.price.toString() : "");
    final notesCtrl =
        TextEditingController(text: isEditing ? expense.notes : "");
    String category = isEditing ? expense.category : "Groceries";
    String paymentMethod = isEditing ? expense.paymentMethod : "Pocket (Cash)";
    DateTime selectedDate = isEditing ? expense.date : DateTime.now();
    bool deductFromAccount = !isEditing;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          provider.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? "Edit Expense" : "Add Expense",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (isEditing)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.red),
                        onPressed: () async {
                          await provider.removeExpense(expense.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: itemCtrl,
                  decoration: const InputDecoration(
                    labelText: "Item Name *",
                    hintText: "e.g. Groceries, Transport ticket",
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Price (€) *",
                    hintText: "e.g. 15.50",
                    prefixIcon: Icon(Icons.euro_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                AddableDropdown(
                  type: "expense_category",
                  labelText: "Category",
                  value: category,
                  prefixIcon: Icons.category_outlined,
                  addOptionLabel: "Add Category",
                  onChanged: (val) {
                    if (val != null) setModalState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                AddableDropdown(
                  type: "payment_method",
                  labelText: "Payment Method",
                  value: paymentMethod,
                  prefixIcon: Icons.payment_rounded,
                  addOptionLabel: "Add Payment Method",
                  onChanged: (val) {
                    if (val != null) setModalState(() => paymentMethod = val);
                  },
                ),
                const SizedBox(height: 12),
                if (!isEditing)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Deduct from Account Balance",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      paymentMethod.toLowerCase().contains("bank")
                          ? "Deducts from Bank Account"
                          : "Deducts from Pocket Cash",
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: deductFromAccount,
                    onChanged: (val) =>
                        setModalState(() => deductFromAccount = val),
                  ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Date: ${DateFormat('dd MMMM yyyy').format(selectedDate)}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
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
                    hintText: "Receipt details, store, etc.",
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final item = itemCtrl.text.trim();
                    final price = double.tryParse(
                            priceCtrl.text.replaceAll(",", ".").trim()) ??
                        0.0;
                    if (item.isEmpty || price <= 0) return;

                    if (isEditing) {
                      final updated = expense.copyWith(
                        item: item,
                        price: price,
                        category: category,
                        paymentMethod: paymentMethod,
                        date: selectedDate,
                        notes: notesCtrl.text.trim(),
                      );
                      await provider.updateExpense(updated);
                    } else {
                      final created = Expense(
                        id: "",
                        item: item,
                        price: price,
                        category: category,
                        paymentMethod: paymentMethod,
                        date: selectedDate,
                        notes: notesCtrl.text.trim(),
                        month: provider.selectedMonth,
                      );
                      await provider.addExpense(created,
                          deductFromAccount: deductFromAccount);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(isEditing ? "Update Expense" : "Save Expense"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddShiftModal(BuildContext context) {
    _showShiftEditor(context);
  }

  void _showEditShiftModal(BuildContext context, EarningShift shift) {
    _showShiftEditor(context, shift: shift);
  }

  void _showShiftEditor(BuildContext context, {EarningShift? shift}) {
    final provider = context.read<AppProvider>();
    final isEditing = shift != null;

    final grossCtrl = TextEditingController(
        text: isEditing ? shift.grossAmount.toString() : "");
    final hoursCtrl =
        TextEditingController(text: isEditing ? shift.hours.toString() : "4.0");
    final timelineCtrl = TextEditingController(
        text: isEditing ? shift.timeline : "07:00 - 11:00");
    final rentCtrl = TextEditingController(
        text: isEditing ? shift.rentDeduction.toString() : "8.33");
    final taxCtrl = TextEditingController(
        text: isEditing ? shift.taxPercent.toString() : "8.0");
    final batchCtrl =
        TextEditingController(text: isEditing ? shift.payoutBatch : "General");

    String category = isEditing ? shift.category : "Delivery";
    String status = isEditing ? shift.paymentStatus : "Pending";
    String depositTo = isEditing ? shift.depositTo : "Bank Account";
    DateTime selectedDate = isEditing ? shift.date : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          provider.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? "Edit Work Shift" : "Log Work Shift",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (isEditing)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.red),
                        onPressed: () async {
                          await provider.removeShift(shift.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                AddableDropdown(
                  type: "shift_role",
                  labelText: "Role / Category",
                  value: category,
                  prefixIcon: Icons.badge_outlined,
                  addOptionLabel: "Add Shift Role",
                  onChanged: (val) {
                    if (val != null) setModalState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: grossCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: "Gross Earned (€) *",
                          prefixIcon: Icon(Icons.euro_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: hoursCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: "Hours Worked *",
                          prefixIcon: Icon(Icons.access_time_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timelineCtrl,
                  decoration: const InputDecoration(
                    labelText: "Timeline",
                    hintText: "e.g. 08:00 - 14:00",
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                // Deductions (fully editable)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rentCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: "Rent Deduction (€)",
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: taxCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: "Tax Deduct (%)",
                          prefixIcon: Icon(Icons.percent_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(
                          labelText: "Payout Status",
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        items: ["Pending", "Received"]
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setModalState(() => status = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: depositTo,
                        decoration: const InputDecoration(
                          labelText: "Deposit Into",
                          prefixIcon: Icon(Icons.account_balance_outlined),
                        ),
                        items: ["Bank Account", "Pocket"]
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setModalState(() => depositTo = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Date: ${DateFormat('dd MMMM yyyy').format(selectedDate)}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final gross = double.tryParse(
                        grossCtrl.text.replaceAll(",", ".").trim());
                    final hours = double.tryParse(
                        hoursCtrl.text.replaceAll(",", ".").trim());
                    if (gross == null || hours == null) return;

                    final rent = double.tryParse(
                            rentCtrl.text.replaceAll(",", ".").trim()) ??
                        0.0;
                    final tax = double.tryParse(
                            taxCtrl.text.replaceAll(",", ".").trim()) ??
                        0.0;
                    final base = (gross - rent).clamp(0.0, double.infinity);
                    final net = base * (1.0 - (tax / 100.0));

                    if (isEditing) {
                      final updated = shift.copyWith(
                        category: category,
                        grossAmount: gross,
                        hours: hours,
                        timeline: timelineCtrl.text.trim(),
                        rentDeduction: rent,
                        taxPercent: tax,
                        netAmount: double.parse(net.toStringAsFixed(2)),
                        paymentStatus: status,
                        payoutBatch: batchCtrl.text.trim(),
                        depositTo: depositTo,
                        date: selectedDate,
                      );
                      await provider.updateShift(updated);
                    } else {
                      final created = EarningShift(
                        id: "",
                        category: category,
                        grossAmount: gross,
                        hours: hours,
                        timeline: timelineCtrl.text.trim(),
                        rentDeduction: rent,
                        taxPercent: tax,
                        netAmount: double.parse(net.toStringAsFixed(2)),
                        paymentStatus: status,
                        payoutBatch: batchCtrl.text.trim(),
                        depositTo: depositTo,
                        date: selectedDate,
                        month: provider.selectedMonth,
                      );
                      await provider.addShift(created);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(isEditing ? "Update Shift" : "Save Shift"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case "Groceries":
        return const Color(0xFF10B981);
      case "Drinks":
        return const Color(0xFF06B6D4);
      case "Transport":
        return const Color(0xFF3B82F6);
      case "Restaurant":
        return const Color(0xFFF59E0B);
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

// ─── Accounts & Balances Card (Pocket & Bank) ───────────────────────────────

class _AccountsBalanceCard extends StatelessWidget {
  final double pocket;
  final double bank;
  final double total;
  final NumberFormat currency;
  final bool isDark;
  final VoidCallback onEdit;

  const _AccountsBalanceCard({
    required this.pocket,
    required this.bank,
    required this.total,
    required this.currency,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Liquid Balances",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded,
                          size: 14, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        "Edit Balances",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wallet_rounded,
                              size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text(
                            "In Pocket (Cash)",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currency.format(pocket),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_rounded,
                              size: 14, color: Color(0xFF6366F1)),
                          const SizedBox(width: 6),
                          Text(
                            "Bank Account",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currency.format(bank),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Available Liquid Funds:",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              Text(
                currency.format(total),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Monthly Budget Card ───────────────────────────────────────────────────

class _MonthlyBudgetCard extends StatelessWidget {
  final DashboardSummary summary;
  final NumberFormat currency;
  final bool isDark;
  final VoidCallback onEditBudget;

  const _MonthlyBudgetCard({
    required this.summary,
    required this.currency,
    required this.isDark,
    required this.onEditBudget,
  });

  @override
  Widget build(BuildContext context) {
    final hasBudget = summary.monthlyBudget > 0;
    final budget = summary.monthlyBudget;
    final spent = summary.totalExpenses;
    final remaining = summary.remainingBudget;
    final percent = hasBudget ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = hasBudget && spent > budget;

    Color progressColor = const Color(0xFF10B981);
    if (percent > 0.85) {
      progressColor = const Color(0xFFEF4444);
    } else if (percent > 0.65) {
      progressColor = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverBudget
              ? const Color(0xFFEF4444).withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          width: isOverBudget ? 1.5 : 1,
        ),
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
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.savings_rounded,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Monthly Budget",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onEditBudget,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        hasBudget ? Icons.edit_rounded : Icons.add_rounded,
                        size: 15,
                        color: const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasBudget ? "Edit Limit" : "Set Budget",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasBudget)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "No monthly spending limit set",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                TextButton(
                  onPressed: onEditBudget,
                  child: const Text("Set Limit"),
                ),
              ],
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Spent of ${currency.format(budget)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.format(spent),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget
                            ? const Color(0xFFEF4444)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOverBudget ? "Over Budget" : "Remaining",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOverBudget
                            ? const Color(0xFFEF4444)
                            : (isDark ? Colors.white54 : Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.format(remaining.abs()),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Debt Payoff Card ───────────────────────────────────────────────────────

class _DebtPayoffCard extends StatelessWidget {
  final double totalDebt;
  final double paidDebt;
  final double remainingDebt;
  final double progressPercent;
  final NumberFormat currency;
  final bool isDark;
  final VoidCallback onTap;

  const _DebtPayoffCard({
    required this.totalDebt,
    required this.paidDebt,
    required this.remainingDebt,
    required this.progressPercent,
    required this.currency,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
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
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.credit_card_off_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Debt Payoff Tracker",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_forward_rounded,
                          size: 14, color: Color(0xFFEF4444)),
                      SizedBox(width: 4),
                      Text(
                        "Manage",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Remaining to Pay Off",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currency.format(remainingDebt),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Paid: ${currency.format(paidDebt)} / ${currency.format(totalDebt)}",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${progressPercent.toStringAsFixed(1)}% Paid",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (progressPercent / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Daily Spending Chart ───────────────────────────────────────────────────

class _DailySpendingChart extends StatelessWidget {
  final Map<String, double> dailySpending;
  final bool isDark;

  const _DailySpendingChart({
    required this.dailySpending,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final entries = dailySpending.entries.toList();
    final maxVal = entries.fold(0.0, (acc, e) => e.value > acc ? e.value : acc);

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal > 0 ? maxVal * 1.25 : 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  "${entries[groupIndex].key}\n€${rod.toY.toStringAsFixed(2)}",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < entries.length) {
                    final key = entries[idx].key;
                    final day = key.split("/").first;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((entry) {
            final idx = entry.key;
            final val = entry.value.value;
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: val,
                  color: const Color(0xFF6366F1),
                  width: 10,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Transaction Tiles ──────────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final NumberFormat currency;
  final bool isDark;
  final VoidCallback onTap;

  const _ExpenseTile({
    required this.expense,
    required this.currency,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
          child: const Icon(Icons.arrow_downward_rounded,
              color: Color(0xFFEF4444), size: 18),
        ),
        title: Text(
          expense.item,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          "${expense.category} • ${expense.paymentMethod} • ${DateFormat('dd MMM').format(expense.date)}",
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currency.format(expense.price),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _ShiftTile extends StatelessWidget {
  final EarningShift shift;
  final NumberFormat currency;
  final bool isDark;
  final VoidCallback onTap;

  const _ShiftTile({
    required this.shift,
    required this.currency,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isReceived = shift.paymentStatus == "Received";

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
          child: const Icon(Icons.arrow_upward_rounded,
              color: Color(0xFF10B981), size: 18),
        ),
        title: Text(
          "${shift.category} Shift (${shift.hours}h)",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          "${shift.timeline} • ${DateFormat('dd MMM').format(shift.date)}",
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.format(shift.netAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF10B981),
                  ),
                ),
                Text(
                  shift.paymentStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isReceived
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ─── Small UI Widgets ───────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white24,
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatusCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final String amount;
  final double percent;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.percent,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      amount,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor:
                        isDark ? Colors.white10 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "${(percent * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

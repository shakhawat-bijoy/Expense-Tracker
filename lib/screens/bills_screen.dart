import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import "../models/models.dart";
import "../providers/app_provider.dart";
import "../widgets/month_navigation_bar.dart";

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  String _filterStatus = "All";
  String _searchQuery = "";

  IconData _getBillIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains("rent") ||
        lower.contains("house") ||
        lower.contains("flat") ||
        lower.contains("apartment")) {
      return Icons.home_rounded;
    } else if (lower.contains("wifi") ||
        lower.contains("internet") ||
        lower.contains("broadband")) {
      return Icons.wifi_rounded;
    } else if (lower.contains("electric") ||
        lower.contains("power") ||
        lower.contains("strom") ||
        lower.contains("energy")) {
      return Icons.bolt_rounded;
    } else if (lower.contains("water") || lower.contains("wasser")) {
      return Icons.water_drop_rounded;
    } else if (lower.contains("phone") ||
        lower.contains("mobile") ||
        lower.contains("telekom") ||
        lower.contains("vodafone")) {
      return Icons.phone_android_rounded;
    } else if (lower.contains("gym") ||
        lower.contains("fitness") ||
        lower.contains("sport")) {
      return Icons.fitness_center_rounded;
    } else if (lower.contains("car") ||
        lower.contains("auto") ||
        lower.contains("insurance") ||
        lower.contains("versic")) {
      return Icons.directions_car_rounded;
    } else if (lower.contains("netflix") ||
        lower.contains("spotify") ||
        lower.contains("sub") ||
        lower.contains("disney") ||
        lower.contains("prime") ||
        lower.contains("apple")) {
      return Icons.subscriptions_rounded;
    } else if (lower.contains("loan") ||
        lower.contains("kredit") ||
        lower.contains("bank")) {
      return Icons.account_balance_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  Color _getBillColor(String name, bool isDark) {
    final lower = name.toLowerCase();
    if (lower.contains("rent") || lower.contains("house")) {
      return const Color(0xFF6366F1);
    } else if (lower.contains("wifi") || lower.contains("internet")) {
      return const Color(0xFF06B6D4);
    } else if (lower.contains("electric") || lower.contains("power")) {
      return const Color(0xFFF59E0B);
    } else if (lower.contains("water")) {
      return const Color(0xFF3B82F6);
    } else if (lower.contains("phone") || lower.contains("mobile")) {
      return const Color(0xFF8B5CF6);
    } else if (lower.contains("gym") || lower.contains("fitness")) {
      return const Color(0xFF10B981);
    } else if (lower.contains("car") || lower.contains("insurance")) {
      return const Color(0xFFEC4899);
    } else if (lower.contains("netflix") ||
        lower.contains("spotify") ||
        lower.contains("sub")) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF8B5CF6);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final bills = provider.fixedBills;
    final currency = NumberFormat.currency(locale: "de_DE", symbol: "€");
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtered bills
    final filteredBills = bills.where((bill) {
      if (_filterStatus == "Paid" && bill.status != "Paid") return false;
      if (_filterStatus == "Pending" && bill.status != "Pending") return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = bill.name.toLowerCase().contains(q);
        final matchesMonth = bill.month.toLowerCase().contains(q);
        if (!matchesName && !matchesMonth) return false;
      }
      return true;
    }).toList();

    // Stats calculations
    final totalAmount = bills.fold(0.0, (acc, b) => acc + b.amount);
    final paidBills = bills.where((b) => b.status == "Paid").toList();
    final pendingBills = bills.where((b) => b.status != "Paid").toList();
    final paidAmount = paidBills.fold(0.0, (acc, b) => acc + b.amount);
    final pendingAmount = pendingBills.fold(0.0, (acc, b) => acc + b.amount);
    final progress =
        totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: provider.fetchAllData,
        child: CustomScrollView(
          slivers: [
            // ─── Month Navigation Header ──────────────────────────────────
            const SliverToBoxAdapter(
              child: MonthNavigationBar(),
            ),

            // ─── Overview Hero Card ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                          : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.25),
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
                            "Fixed Monthly Bills",
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
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${paidBills.length}/${bills.length} Paid",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currency.format(totalAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF34D399),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatMiniCard(
                              label: "Paid",
                              amount: currency.format(paidAmount),
                              count: "${paidBills.length} bills",
                              color: const Color(0xFF34D399),
                              icon: Icons.check_circle_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatMiniCard(
                              label: "Pending",
                              amount: currency.format(pendingAmount),
                              count: "${pendingBills.length} bills",
                              color: const Color(0xFFFBBF24),
                              icon: Icons.hourglass_top_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.08, end: 0),
              ),
            ),

            // ─── Search and Filter Chips ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search bills or month...",
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () =>
                                    setState(() => _searchQuery = ""),
                              )
                            : null,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _FilterChip(
                          label: "All (${bills.length})",
                          selected: _filterStatus == "All",
                          onTap: () => setState(() => _filterStatus = "All"),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: "Pending (${pendingBills.length})",
                          selected: _filterStatus == "Pending",
                          badgeColor: const Color(0xFFFBBF24),
                          onTap: () =>
                              setState(() => _filterStatus = "Pending"),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: "Paid (${paidBills.length})",
                          selected: _filterStatus == "Paid",
                          badgeColor: const Color(0xFF34D399),
                          onTap: () => setState(() => _filterStatus = "Paid"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Bills List / Empty State ─────────────────────────────────
            if (filteredBills.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 72,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          bills.isEmpty
                              ? "No fixed bills recorded yet"
                              : "No bills match your filter",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bills.isEmpty
                              ? "Keep track of rent, electricity, subscriptions, and recurring costs."
                              : "Try changing the search term or switching the status filter.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (bills.isEmpty) ...[
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded),
                            label: const Text("Add Your First Bill"),
                            onPressed: () =>
                                _showAddBillModal(context, provider),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final bill = filteredBills[index];
                      final isPaid = bill.status == "Paid";
                      final icon = _getBillIcon(bill.name);
                      final iconColor = _getBillColor(bill.name, isDark);

                      return Dismissible(
                        key: ValueKey(bill.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.white, size: 26),
                        ),
                        confirmDismiss: (direction) async {
                          return await _confirmDelete(context, bill.name);
                        },
                        onDismissed: (direction) {
                          provider.removeFixedBill(bill.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${bill.name} deleted"),
                              action: SnackBarAction(
                                label: "OK",
                                onPressed: () {},
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () =>
                                provider.toggleFixedBillStatus(bill.id),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  // Category/Name Icon
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: iconColor.withValues(
                                          alpha: isDark ? 0.2 : 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child:
                                        Icon(icon, color: iconColor, size: 24),
                                  ),
                                  const SizedBox(width: 14),

                                  // Name and Month
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bill.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            decoration: isPaid
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: isPaid
                                                ? (isDark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600)
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              bill.month.isNotEmpty
                                                  ? bill.month
                                                  : "Monthly",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Amount and Status Toggle
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        currency.format(bill.amount),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isPaid
                                              ? const Color(0xFF10B981)
                                              : (isDark
                                                  ? Colors.white
                                                  : Colors.black87),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () => provider
                                            .toggleFixedBillStatus(bill.id),
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isPaid
                                                ? const Color(0xFF10B981)
                                                    .withValues(alpha: 0.15)
                                                : const Color(0xFFF59E0B)
                                                    .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isPaid
                                                  ? const Color(0xFF10B981)
                                                      .withValues(alpha: 0.4)
                                                  : const Color(0xFFF59E0B)
                                                      .withValues(alpha: 0.4),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isPaid
                                                    ? Icons.check_circle_rounded
                                                    : Icons
                                                        .radio_button_unchecked_rounded,
                                                size: 13,
                                                color: isPaid
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFFF59E0B),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isPaid ? "Paid" : "Pending",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isPaid
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFFF59E0B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Delete Action Menu
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert_rounded,
                                      size: 18,
                                      color: Colors.grey.shade500,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onSelected: (val) async {
                                      if (val == "toggle") {
                                        provider.toggleFixedBillStatus(bill.id);
                                      } else if (val == "edit") {
                                        _showAddBillModal(context, provider,
                                            bill: bill);
                                      } else if (val == "delete") {
                                        final confirmed = await _confirmDelete(
                                            context, bill.name);
                                        if (confirmed == true) {
                                          provider.removeFixedBill(bill.id);
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: "edit",
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text("Edit Bill"),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: "toggle",
                                        child: Row(
                                          children: [
                                            Icon(
                                              isPaid
                                                  ? Icons.undo_rounded
                                                  : Icons
                                                      .check_circle_outline_rounded,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(isPaid
                                                ? "Mark as Pending"
                                                : "Mark as Paid"),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: "delete",
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Delete",
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 250.ms, delay: (index * 40).ms);
                    },
                    childCount: filteredBills.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text("Add Bill"),
        onPressed: () => _showAddBillModal(context, provider),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String billName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Bill"),
        content: Text("Are you sure you want to delete '$billName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showAddBillModal(BuildContext context, AppProvider provider,
      {FixedBill? bill}) {
    final isEditing = bill != null;
    final nameCtrl = TextEditingController(text: isEditing ? bill.name : "");
    final amountCtrl = TextEditingController(
      text: isEditing ? bill.amount.toString() : "",
    );
    final monthCtrl = TextEditingController(
      text: isEditing ? bill.month : provider.selectedMonth,
    );
    String status = isEditing ? bill.status : "Pending";
    final formKey = GlobalKey<FormState>();

    final commonPresets = [
      "Apartment Rent",
      "Electricity Bill",
      "High-speed Internet",
      "Mobile Plan",
      "Health Insurance",
      "Gym Membership",
      "Netflix Subscription",
      "Spotify Family",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? "Edit Fixed Bill" : "Add Fixed Bill",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Suggestions
                  Text(
                    "Quick Suggestions",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: commonPresets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final preset = commonPresets[i];
                        return ActionChip(
                          label: Text(preset,
                              style: const TextStyle(fontSize: 12)),
                          onPressed: () {
                            setModalState(() {
                              nameCtrl.text = preset;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name Field
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Bill Name *",
                      hintText: "e.g., Studio Rent, Wifi",
                      prefixIcon: Icon(Icons.receipt_long_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "Bill name is required"
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Amount Field
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Amount (€) *",
                      hintText: "0.00",
                      prefixIcon: Icon(Icons.euro_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Amount is required";
                      }
                      final parsed = double.tryParse(v.replaceAll(",", "."));
                      if (parsed == null || parsed <= 0) {
                        return "Enter a valid positive number";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Month Field
                  TextFormField(
                    controller: monthCtrl,
                    decoration: const InputDecoration(
                      labelText: "Billing Month / Period",
                      hintText: "e.g., October 2026",
                      prefixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Status Selector
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: "Payment Status",
                      prefixIcon: Icon(Icons.assignment_turned_in_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Pending",
                        child: Row(
                          children: [
                            Icon(Icons.hourglass_top_rounded,
                                size: 16, color: Color(0xFFF59E0B)),
                            SizedBox(width: 8),
                            Text("Pending"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: "Paid",
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 16, color: Color(0xFF10B981)),
                            SizedBox(width: 8),
                            Text("Paid"),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => status = val);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                        isEditing ? "Update Bill" : "Save Bill",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          final parsedAmount = double.parse(
                              amountCtrl.text.replaceAll(",", ".").trim());
                          Navigator.pop(ctx);
                          if (isEditing) {
                            final updated = bill.copyWith(
                              name: nameCtrl.text.trim(),
                              amount: parsedAmount,
                              month: monthCtrl.text.trim(),
                              status: status,
                            );
                            await provider.updateFixedBill(updated);
                          } else {
                            final newBill = FixedBill(
                              id: "",
                              name: nameCtrl.text.trim(),
                              amount: parsedAmount,
                              month: monthCtrl.text.trim(),
                              status: status,
                            );
                            await provider.addFixedBill(newBill);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String label;
  final String amount;
  final String count;
  final Color color;
  final IconData icon;

  const _StatMiniCard({
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      count,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary
              : (isDark ? const Color(0xFF1E1E38) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? cs.primary
                : (isDark ? const Color(0xFF2E2E52) : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

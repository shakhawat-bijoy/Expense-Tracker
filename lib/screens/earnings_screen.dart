import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import "../models/models.dart";
import "../providers/app_provider.dart";
import "../widgets/addable_dropdown.dart";
import "../widgets/month_navigation_bar.dart";

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final shifts = provider.shifts;
    final currency = NumberFormat.currency(locale: "de_DE", symbol: "€");
    final dateFormat = DateFormat("dd MMM yyyy");
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Summary stats
    final totalNet = shifts.fold(0.0, (acc, s) => acc + s.netAmount);
    final totalHours = shifts.fold(0.0, (acc, s) => acc + s.hours);

    return Scaffold(
      body: Column(
        children: [
          // ─── Month Navigation Bar ─────────────────────────────────────
          const MonthNavigationBar(),

          // ─── Earnings Overview Hero ───────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A5F), const Color(0xFF0D47A1)]
                    : [const Color(0xFF0D47A1), const Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _EarningStat(
                  label: "Total Shifts",
                  value: "${shifts.length}",
                  icon: Icons.work_rounded,
                ),
                Container(height: 36, width: 1, color: Colors.white24),
                _EarningStat(
                  label: "Total Hours",
                  value: "${totalHours.toStringAsFixed(1)}h",
                  icon: Icons.timer_rounded,
                ),
                Container(height: 36, width: 1, color: Colors.white24),
                _EarningStat(
                  label: "Net Earned",
                  value: currency.format(totalNet),
                  icon: Icons.payments_rounded,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms),

          // ─── Shifts List or Empty State ───────────────────────────────
          Expanded(
            child: shifts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_history_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No shifts in ${provider.formattedSelectedMonth}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Log your shifts and job earnings. Tap any shift to edit rates, hours, deductions, or payout status.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded),
                            label: const Text("Log First Shift"),
                            onPressed: () => _showAddShiftSheet(context),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: provider.fetchAllData,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: shifts.length,
                      itemBuilder: (context, index) {
                        final shift = shifts[index];
                        final isReceived = shift.paymentStatus == "Received";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _showAddShiftSheet(context, shift: shift),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor:
                                                const Color(0xFF1976D2)
                                                    .withValues(alpha: 0.12),
                                            child: const Icon(
                                              Icons.work_outline_rounded,
                                              color: Color(0xFF1976D2),
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                shift.category,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                dateFormat.format(shift.date),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // Status badge with tap to toggle
                                      InkWell(
                                        onTap: () => provider
                                            .toggleShiftStatus(shift.id),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isReceived
                                                ? const Color(0xFF10B981)
                                                    .withValues(alpha: 0.12)
                                                : const Color(0xFFF59E0B)
                                                    .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isReceived
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFF59E0B),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isReceived
                                                    ? Icons.check_circle_rounded
                                                    : Icons.hourglass_top_rounded,
                                                size: 14,
                                                color: isReceived
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFFF59E0B),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                shift.paymentStatus,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isReceived
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
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _ShiftDetail(
                                        label: "Timeline",
                                        value: shift.timeline,
                                      ),
                                      _ShiftDetail(
                                        label: "Hours",
                                        value: "${shift.hours}h",
                                      ),
                                      _ShiftDetail(
                                        label: "Gross",
                                        value:
                                            currency.format(shift.grossAmount),
                                      ),
                                      _ShiftDetail(
                                        label: "Net",
                                        value:
                                            currency.format(shift.netAmount),
                                        isBold: true,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
        onPressed: () => _showAddShiftSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Log Shift"),
      ),
    );
  }

  void _showAddShiftSheet(BuildContext context, {EarningShift? shift}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddShiftSheet(shift: shift),
    );
  }
}

class _EarningStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _EarningStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }
}

class _ShiftDetail extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _ShiftDetail({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ],
    );
  }
}

// ─── Add / Edit Shift Sheet ─────────────────────────────────────────────────

class _AddShiftSheet extends StatefulWidget {
  final EarningShift? shift;
  const _AddShiftSheet({this.shift});

  @override
  State<_AddShiftSheet> createState() => _AddShiftSheetState();
}

class _AddShiftSheetState extends State<_AddShiftSheet> {
  late String _category;
  late final TextEditingController _timelineCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _grossCtrl;
  late final TextEditingController _rentCtrl;
  late final TextEditingController _taxCtrl;
  late final TextEditingController _batchCtrl;
  late DateTime _selectedDate;
  late String _paymentStatus;
  late String _depositTo;

  bool get isEditing => widget.shift != null;

  @override
  void initState() {
    super.initState();
    final s = widget.shift;
    _category = s?.category ?? "Delivery";
    _timelineCtrl =
        TextEditingController(text: s?.timeline ?? "10:00 - 18:00");
    _hoursCtrl = TextEditingController(text: s?.hours.toString() ?? "8.0");
    _grossCtrl =
        TextEditingController(text: s != null ? s.grossAmount.toString() : "");
    _rentCtrl = TextEditingController(
        text: s != null ? s.rentDeduction.toString() : "8.33");
    _taxCtrl =
        TextEditingController(text: s != null ? s.taxPercent.toString() : "8.0");
    _batchCtrl =
        TextEditingController(text: s?.payoutBatch ?? "General");
    _paymentStatus = s?.paymentStatus ?? "Pending";
    _depositTo = s?.depositTo ?? "Bank Account";
    _selectedDate = s?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _timelineCtrl.dispose();
    _hoursCtrl.dispose();
    _grossCtrl.dispose();
    _rentCtrl.dispose();
    _taxCtrl.dispose();
    _batchCtrl.dispose();
    super.dispose();
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
                Text(isEditing ? "Edit Shift" : "Log Shift",
                    style:
                        const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    onPressed: () async {
                      final provider = context.read<AppProvider>();
                      await provider.removeShift(widget.shift!.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            AddableDropdown(
              type: "shift_role",
              labelText: "Role / Job Category",
              value: _category,
              prefixIcon: Icons.badge_outlined,
              addOptionLabel: "Add Shift Role",
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
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
                child: Text(
                  DateFormat("dd MMMM yyyy").format(_selectedDate),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _timelineCtrl,
              decoration: const InputDecoration(
                labelText: "Timeline",
                hintText: "e.g. 10:00 - 18:00",
                prefixIcon: Icon(Icons.schedule_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hoursCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Hours Worked *",
                      prefixIcon: Icon(Icons.timer_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _grossCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Gross Earned (€) *",
                      hintText: "0.00",
                      prefixIcon: Icon(Icons.payments_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Deductions (fully editable)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rentCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Rent Deduct (€)",
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _taxCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Tax Deduct (%)",
                      prefixIcon: Icon(Icons.percent_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _paymentStatus,
                    decoration: const InputDecoration(
                      labelText: "Payment Status",
                      prefixIcon: Icon(Icons.assignment_turned_in_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Pending", child: Text("Pending")),
                      DropdownMenuItem(value: "Received", child: Text("Received")),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _paymentStatus = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _depositTo,
                    decoration: const InputDecoration(
                      labelText: "Deposit Into",
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: "Bank Account", child: Text("Bank Account")),
                      DropdownMenuItem(value: "Pocket", child: Text("Pocket")),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _depositTo = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final gross = double.tryParse(
                        _grossCtrl.text.replaceAll(",", ".").trim()) ??
                    0.0;
                final hours = double.tryParse(
                        _hoursCtrl.text.replaceAll(",", ".").trim()) ??
                    0.0;
                final rent = double.tryParse(
                        _rentCtrl.text.replaceAll(",", ".").trim()) ??
                    0.0;
                final tax = double.tryParse(
                        _taxCtrl.text.replaceAll(",", ".").trim()) ??
                    0.0;

                final base = (gross - rent).clamp(0.0, double.infinity);
                final net = base * (1 - (tax / 100));

                final provider = context.read<AppProvider>();

                if (isEditing) {
                  final updated = widget.shift!.copyWith(
                    category: _category,
                    date: _selectedDate,
                    timeline: _timelineCtrl.text.trim(),
                    hours: hours,
                    grossAmount: gross,
                    rentDeduction: rent,
                    taxPercent: tax,
                    netAmount: double.parse(net.toStringAsFixed(2)),
                    paymentStatus: _paymentStatus,
                    depositTo: _depositTo,
                  );
                  provider.updateShift(updated);
                } else {
                  final newShift = EarningShift(
                    id: "",
                    date: _selectedDate,
                    category: _category,
                    timeline: _timelineCtrl.text.trim(),
                    hours: hours,
                    grossAmount: gross,
                    rentDeduction: rent,
                    taxPercent: tax,
                    netAmount: double.parse(net.toStringAsFixed(2)),
                    paymentStatus: _paymentStatus,
                    payoutBatch: _batchCtrl.text.trim(),
                    depositTo: _depositTo,
                    month: provider.selectedMonth,
                  );
                  provider.addShift(newShift);
                }

                Navigator.pop(context);
              },
              child: Text(isEditing ? "Update Shift" : "Save Shift"),
            ),
          ],
        ),
      ),
    );
  }
}

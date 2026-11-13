import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import "../models/models.dart";
import "../providers/app_provider.dart";
import "../widgets/addable_dropdown.dart";
import "../widgets/month_navigation_bar.dart";

TimeOfDay _timeFromMinutes(int? minutes, TimeOfDay fallback) {
  if (minutes == null) return fallback;
  return TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60);
}

TimeOfDay _parseTimelineTime(String timeline, TimeOfDay fallback, bool end) {
  final parts = timeline.split("-");
  if (parts.length != 2) return fallback;
  final value = parts[end ? 1 : 0].trim();
  final match =
      RegExp(r"^(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?$").firstMatch(value);
  if (match == null) return fallback;
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final meridiem = match.group(3)?.toLowerCase();
  if (meridiem != null) {
    if (meridiem == "pm" && hour != 12) hour += 12;
    if (meridiem == "am" && hour == 12) hour = 0;
  }
  return hour >= 0 && hour < 24 && minute < 60
      ? TimeOfDay(hour: hour, minute: minute)
      : fallback;
}

int _timeMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

String _format12Hour(BuildContext context, TimeOfDay time) =>
    MaterialLocalizations.of(context)
        .formatTimeOfDay(time, alwaysUse24HourFormat: false);

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final shifts = List<EarningShift>.from(provider.shifts)
      ..sort((a, b) => b.date.compareTo(a.date));
    final currency = NumberFormat.currency(locale: "de_DE", symbol: "€");
    final dateFormat = DateFormat("dd MMM yyyy");
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Summary stats
    final totalNet = shifts.fold(0.0, (acc, s) => acc + s.netAmount);
    final totalMinutes =
        shifts.fold(0, (acc, s) => acc + (s.hours * 60).round() + s.minutes);

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
                  value: "${totalMinutes ~/ 60}h ${totalMinutes % 60}m",
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
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
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
                            onTap: () =>
                                _showAddShiftSheet(context, shift: shift),
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
                                        borderRadius: BorderRadius.circular(20),
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
                                                    : Icons
                                                        .hourglass_top_rounded,
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
                                  Wrap(
                                    spacing: 18,
                                    runSpacing: 10,
                                    children: [
                                      _ShiftDetail(
                                        label: "Timeline",
                                        value: shift.timeline,
                                      ),
                                      _ShiftDetail(
                                        label: "Hours",
                                        value: shift.minutes > 0
                                            ? "${shift.hours}h ${shift.minutes}m"
                                            : "${shift.hours}h",
                                      ),
                                      _ShiftDetail(
                                        label: "Break",
                                        value: "${shift.breakMinutes}m",
                                      ),
                                      _ShiftDetail(
                                        label: "Gross",
                                        value:
                                            currency.format(shift.grossAmount),
                                      ),
                                      _ShiftDetail(
                                        label: "Net",
                                        value: currency.format(shift.netAmount),
                                        isBold: true,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 250.ms, delay: (index * 30).ms);
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
  late final TextEditingController _breakCtrl;
  late final TextEditingController _grossCtrl;
  late final TextEditingController _rentCtrl;
  late final TextEditingController _taxCtrl;
  late final TextEditingController _batchCtrl;
  late DateTime _selectedDate;
  late String _paymentStatus;
  late String _depositTo;
  late TimeOfDay _startTime;
  late TimeOfDay _finishTime;

  bool get isEditing => widget.shift != null;

  @override
  void initState() {
    super.initState();
    final s = widget.shift;
    _category = s?.category ?? "Delivery";
    const defaultStart = TimeOfDay(hour: 10, minute: 0);
    const defaultFinish = TimeOfDay(hour: 18, minute: 0);
    _startTime = _timeFromMinutes(
      s?.startMinutes,
      s == null
          ? defaultStart
          : _parseTimelineTime(s.timeline, defaultStart, false),
    );
    _finishTime = _timeFromMinutes(
      s?.finishMinutes,
      s == null
          ? defaultFinish
          : _parseTimelineTime(s.timeline, defaultFinish, true),
    );
    _breakCtrl = TextEditingController(text: s?.breakMinutes.toString() ?? "0");
    _grossCtrl =
        TextEditingController(text: s != null ? s.grossAmount.toString() : "");
    _rentCtrl = TextEditingController(
        text: s != null ? s.rentDeduction.toString() : "0");
    _taxCtrl =
        TextEditingController(text: s != null ? s.taxPercent.toString() : "0");
    _batchCtrl = TextEditingController(text: s?.payoutBatch ?? "General");
    _paymentStatus = s?.paymentStatus ?? "Pending";
    _depositTo = s?.depositTo ?? "Bank Account";
    _selectedDate = s?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _breakCtrl.dispose();
    _grossCtrl.dispose();
    _rentCtrl.dispose();
    _taxCtrl.dispose();
    _batchCtrl.dispose();
    super.dispose();
  }

  int get _breakMinutes => int.tryParse(_breakCtrl.text.trim()) ?? 0;

  int get _shiftDurationMinutes {
    var duration = _timeMinutes(_finishTime) - _timeMinutes(_startTime);
    if (duration <= 0) duration += 24 * 60;
    return duration;
  }

  int get _workedMinutes =>
      (_shiftDurationMinutes - _breakMinutes).clamp(0, 24 * 60);

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _finishTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _startTime = picked;
        } else {
          _finishTime = picked;
        }
      });
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
                Text(isEditing ? "Edit Shift" : "Log Shift",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
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
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(true),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Starting time",
                        prefixIcon: Icon(Icons.login_rounded),
                      ),
                      child: Text(_format12Hour(context, _startTime)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(false),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Finish time",
                        prefixIcon: Icon(Icons.logout_rounded),
                      ),
                      child: Text(_format12Hour(context, _finishTime)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Hours Worked",
                      prefixIcon: Icon(Icons.timer_rounded),
                    ),
                    child: Text(
                      "${_workedMinutes ~/ 60}h ${_workedMinutes % 60}m",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _breakCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Break (minutes)",
                      prefixIcon: Icon(Icons.free_breakfast_rounded),
                    ),
                    onChanged: (_) => setState(() {}),
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
                      DropdownMenuItem(
                          value: "Pending", child: Text("Pending")),
                      DropdownMenuItem(
                          value: "Received", child: Text("Received")),
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
                final hours = (_workedMinutes ~/ 60).toDouble();
                final minutes = _workedMinutes % 60;
                if (_breakMinutes < 0 ||
                    _breakMinutes > _shiftDurationMinutes) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text("Break cannot exceed the shift duration")),
                  );
                  return;
                }
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
                    timeline:
                        "${_format12Hour(context, _startTime)} - ${_format12Hour(context, _finishTime)}",
                    hours: hours,
                    minutes: minutes,
                    startMinutes: _timeMinutes(_startTime),
                    finishMinutes: _timeMinutes(_finishTime),
                    breakMinutes: _breakMinutes,
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
                    timeline:
                        "${_format12Hour(context, _startTime)} - ${_format12Hour(context, _finishTime)}",
                    hours: hours,
                    minutes: minutes,
                    startMinutes: _timeMinutes(_startTime),
                    finishMinutes: _timeMinutes(_finishTime),
                    breakMinutes: _breakMinutes,
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

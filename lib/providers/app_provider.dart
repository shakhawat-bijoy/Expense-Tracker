import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";
import "../models/models.dart";
import "../services/mongodb_service_old.dart";

class AppProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  List<EarningShift> _shifts = [];
  List<FixedBill> _fixedBills = [];
  List<DebtItem> _debts = [];
  MonthlyBudget _budget = MonthlyBudget(month: "", amount: 0.0);
  AccountBalance _accounts = AccountBalance.initial();
  DashboardSummary _summary = DashboardSummary.initial();

  bool _isLoading = false;
  ThemeMode _themeMode = ThemeMode.light;
  String _searchQuery = "";
  String _selectedCategory = "All";
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  // Month-by-month tracking (e.g. "2026-10")
  late String _selectedMonth;

  // Custom Dropdown Options Cache
  final Map<String, List<String>> _dropdownOptions = {
    "expense_category": [
      "Groceries",
      "Drinks",
      "Transport",
      "Restaurant",
      "Health",
      "Utility",
      "Shopping",
      "Entertainment",
      "Other"
    ],
    "shift_role": [
      "Delivery",
      "Interior",
      "Warehouse",
      "Freelance",
      "Consulting",
      "Other"
    ],
    "payment_method": [
      "Pocket (Cash)",
      "Bank Account",
      "Credit Card",
      "Debit Card"
    ],
    "bill_category": [
      "Rent",
      "Utilities",
      "Internet",
      "Subscriptions",
      "Insurance",
      "Other"
    ],
    "debt_category": [
      "Personal Loan",
      "Credit Card",
      "Bank Loan",
      "Family / Friend",
      "Car Loan",
      "Mortgage",
      "Other"
    ],
  };

  AppProvider() {
    final now = DateTime.now();
    _selectedMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  // ─── Getters ────────────────────────────────────────────────────────────
  List<Expense> get expenses => _expenses;
  List<EarningShift> get shifts => _shifts;
  List<FixedBill> get fixedBills => _fixedBills;
  List<DebtItem> get debts => _debts;
  MonthlyBudget get budget => _budget;
  AccountBalance get accounts => _accounts;
  DashboardSummary get summary => _summary;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String get selectedMonth => _selectedMonth;

  double get pocketBalance => _accounts.pocket;
  double get bankBalance => _accounts.bank;
  double get totalLiquidFunds => _accounts.total;

  double get totalDebtOwed => _debts.fold(0.0, (acc, d) => acc + d.amount);
  double get totalDebtPaid => _debts.fold(0.0, (acc, d) => acc + d.paidAmount);
  double get remainingDebtOwed =>
      (totalDebtOwed - totalDebtPaid).clamp(0.0, double.infinity);
  double get debtPayoffProgress => totalDebtOwed > 0
      ? ((totalDebtPaid / totalDebtOwed) * 100).clamp(0.0, 100.0)
      : 100.0;

  String get formattedSelectedMonth {
    try {
      final parts = _selectedMonth.split("-");
      if (parts.length == 2) {
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        return DateFormat("MMMM yyyy").format(date);
      }
    } catch (_) {}
    return _selectedMonth;
  }

  String get previousMonthName {
    try {
      final parts = _selectedMonth.split("-");
      int year = int.parse(parts[0]);
      int month = int.parse(parts[1]) - 1;
      if (month < 1) {
        month = 12;
        year -= 1;
      }
      return DateFormat("MMM yyyy").format(DateTime(year, month));
    } catch (_) {
      return "Prev";
    }
  }

  String get nextMonthName {
    try {
      final parts = _selectedMonth.split("-");
      int year = int.parse(parts[0]);
      int month = int.parse(parts[1]) + 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
      return DateFormat("MMM yyyy").format(DateTime(year, month));
    } catch (_) {
      return "Next";
    }
  }

  List<Expense> get filteredExpenses {
    var filtered = List<Expense>.from(_expenses);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.item.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q) ||
            e.paymentMethod.toLowerCase().contains(q) ||
            e.notes.toLowerCase().contains(q);
      }).toList();
    }

    if (_selectedCategory != "All") {
      filtered =
          filtered.where((e) => e.category == _selectedCategory).toList();
    }

    if (_filterStartDate != null) {
      filtered = filtered
          .where((e) => e.date
              .isAfter(_filterStartDate!.subtract(const Duration(days: 1))))
          .toList();
    }

    if (_filterEndDate != null) {
      filtered = filtered
          .where((e) =>
              e.date.isBefore(_filterEndDate!.add(const Duration(days: 1))))
          .toList();
    }

    return filtered;
  }

  // ─── Dropdown Options Management ─────────────────────────────────────────
  List<String> getDropdownOptions(String type) {
    return _dropdownOptions[type] ?? [];
  }

  Future<void> addDropdownOption(String type, String newOption) async {
    final clean = newOption.trim();
    if (clean.isEmpty) return;

    if (!_dropdownOptions.containsKey(type)) {
      _dropdownOptions[type] = [];
    }
    if (!_dropdownOptions[type]!
        .any((o) => o.toLowerCase() == clean.toLowerCase())) {
      _dropdownOptions[type]!.add(clean);
      notifyListeners();
      await MongoService.addCustomOption(type, clean);
    }
  }

  Future<void> loadCustomOptions() async {
    for (final type in _dropdownOptions.keys) {
      final serverOpts = await MongoService.getCustomOptions(type);
      for (final opt in serverOpts) {
        if (!_dropdownOptions[type]!
            .any((o) => o.toLowerCase() == opt.toLowerCase())) {
          _dropdownOptions[type]!.add(opt);
        }
      }
    }
    notifyListeners();
  }

  // ─── Month Navigation ───────────────────────────────────────────────────
  void setSelectedMonth(String month) {
    if (_selectedMonth != month) {
      _selectedMonth = month;
      fetchAllData();
    }
  }

  void previousMonth() {
    try {
      final parts = _selectedMonth.split("-");
      int year = int.parse(parts[0]);
      int month = int.parse(parts[1]) - 1;
      if (month < 1) {
        month = 12;
        year -= 1;
      }
      _selectedMonth = "$year-${month.toString().padLeft(2, '0')}";
      fetchAllData();
    } catch (_) {}
  }

  void nextMonth() {
    try {
      final parts = _selectedMonth.split("-");
      int year = int.parse(parts[0]);
      int month = int.parse(parts[1]) + 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
      _selectedMonth = "$year-${month.toString().padLeft(2, '0')}";
      fetchAllData();
    } catch (_) {}
  }

  void resetToCurrentMonth() {
    final now = DateTime.now();
    final cur = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    if (_selectedMonth != cur) {
      _selectedMonth = cur;
      fetchAllData();
    }
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    final cur = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    return _selectedMonth == cur;
  }

  // ─── Theme ──────────────────────────────────────────────────────────────
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool("isDarkMode") ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isDarkMode", _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  // ─── Filters ────────────────────────────────────────────────────────────
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _filterStartDate = start;
    _filterEndDate = end;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = "";
    _selectedCategory = "All";
    _filterStartDate = null;
    _filterEndDate = null;
    notifyListeners();
  }

  // ─── Data Fetching (Month-by-Month) ─────────────────────────────────────
  Future<void> fetchAllData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        MongoService.getExpenses(month: _selectedMonth),
        MongoService.getShifts(month: _selectedMonth),
        MongoService.getFixedBills(month: _selectedMonth),
        MongoService.getBudget(month: _selectedMonth),
        MongoService.getSummary(month: _selectedMonth),
        MongoService.getAccounts(),
        MongoService.getDebts(month: _selectedMonth),
      ]);

      _expenses = results[0] as List<Expense>;
      _shifts = results[1] as List<EarningShift>;
      _fixedBills = results[2] as List<FixedBill>;
      _budget = results[3] as MonthlyBudget;
      _summary = results[4] as DashboardSummary;
      _accounts = results[5] as AccountBalance;
      _debts = results[6] as List<DebtItem>;

      await loadCustomOptions();
    } catch (e) {
      debugPrint("Data fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Accounts Management (Pocket & Bank Account) ────────────────────────
  Future<void> saveAccounts({
    required double pocket,
    required double bank,
    String notes = "",
  }) async {
    await MongoService.updateAccounts(pocket: pocket, bank: bank, notes: notes);
    await fetchAllData();
  }

  Future<void> adjustAccount({
    required String accountType, // "pocket" or "bank"
    required double amount,
    String operation = "add", // "add" or "deduct"
  }) async {
    await MongoService.adjustAccount(
      accountType: accountType,
      amount: amount,
      operation: operation,
    );
    await fetchAllData();
  }

  // ─── Debts Management ────────────────────────────────────────────────────
  Future<void> addDebt(DebtItem debt) async {
    await MongoService.insertDebt(debt);
    await fetchAllData();
  }

  Future<void> updateDebt(DebtItem debt) async {
    await MongoService.updateDebt(debt);
    await fetchAllData();
  }

  Future<void> payDebt({
    required String id,
    required double amount,
    String? deductFrom, // "pocket" or "bank"
  }) async {
    await MongoService.payDebt(
      id: id,
      paymentAmount: amount,
      deductFrom: deductFrom,
    );
    await fetchAllData();
  }

  Future<void> deleteDebt(String id) async {
    await MongoService.deleteDebt(id);
    await fetchAllData();
  }

  // ─── Expenses (CRUD) ────────────────────────────────────────────────────
  Future<void> addExpense(Expense expense,
      {bool deductFromAccount = false}) async {
    await MongoService.insertExpense(expense,
        deductFromAccount: deductFromAccount);
    await fetchAllData();
  }

  Future<void> updateExpense(Expense expense) async {
    await MongoService.updateExpense(expense);
    await fetchAllData();
  }

  Future<void> removeExpense(String id) async {
    await MongoService.deleteExpense(id);
    await fetchAllData();
  }

  // ─── Shifts / Earnings (CRUD) ───────────────────────────────────────────
  Future<void> addShift(EarningShift shift) async {
    await MongoService.insertShift(shift);
    await fetchAllData();
  }

  Future<void> updateShift(EarningShift shift) async {
    await MongoService.updateShift(shift);
    await fetchAllData();
  }

  Future<void> removeShift(String id) async {
    await MongoService.deleteShift(id);
    await fetchAllData();
  }

  Future<void> toggleShiftStatus(String id) async {
    await MongoService.toggleShiftStatus(id);
    await fetchAllData();
  }

  // ─── Fixed Bills (CRUD) ─────────────────────────────────────────────────
  Future<void> addFixedBill(FixedBill bill) async {
    await MongoService.insertFixedBill(bill);
    await fetchAllData();
  }

  Future<void> updateFixedBill(FixedBill bill) async {
    await MongoService.updateFixedBill(bill);
    await fetchAllData();
  }

  Future<void> toggleFixedBillStatus(String id) async {
    await MongoService.toggleFixedBillStatus(id);
    await fetchAllData();
  }

  Future<void> removeFixedBill(String id) async {
    await MongoService.deleteFixedBill(id);
    await fetchAllData();
  }

  // ─── Monthly Budget (CRUD) ──────────────────────────────────────────────
  Future<void> saveBudget(double amount, {String notes = ""}) async {
    final b = MonthlyBudget(
      month: _selectedMonth,
      amount: amount,
      notes: notes,
    );
    await MongoService.setBudget(b);
    await fetchAllData();
  }

  // ─── Computed Stats ─────────────────────────────────────────────────────
  double get todayExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (acc, e) => acc + e.price);
  }

  double get thisWeekExpenses {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _expenses
        .where(
            (e) => e.date.isAfter(weekStart.subtract(const Duration(days: 1))))
        .fold(0.0, (acc, e) => acc + e.price);
  }

  double get thisMonthExpenses {
    return _expenses.fold(0.0, (acc, e) => acc + e.price);
  }
}

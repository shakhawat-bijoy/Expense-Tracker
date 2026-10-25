import "package:flutter/foundation.dart";
import "package:path/path.dart";
import "package:sqflite/sqflite.dart";
import "../models/models.dart";

class DatabaseService {
  static Database? _database;
  static const String _dbName = "expense_tracker.db";
  static const int _dbVersion = 2;

  // Singleton pattern
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        item TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        month TEXT NOT NULL
      )
    ''');

    // Create shifts table (matching EarningShift model)
    await db.execute('''
      CREATE TABLE shifts (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        month TEXT NOT NULL,
        category TEXT NOT NULL,
        timeline TEXT NOT NULL,
        hours REAL NOT NULL,
        grossAmount REAL NOT NULL,
        rentDeduction REAL NOT NULL DEFAULT 8.33,
        taxPercent REAL NOT NULL DEFAULT 8.0,
        netAmount REAL NOT NULL,
        paymentStatus TEXT NOT NULL DEFAULT 'Pending',
        payoutBatch TEXT NOT NULL DEFAULT 'General',
        depositTo TEXT NOT NULL DEFAULT 'Bank Account'
      )
    ''');

    // Create fixed_bills table (matching FixedBill model)
    await db.execute('''
      CREATE TABLE fixed_bills (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL DEFAULT 'Utilities',
        month TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Pending'
      )
    ''');

    // Create debts table (matching DebtItem model)
    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        personName TEXT,
        amount REAL NOT NULL,
        paidAmount REAL NOT NULL DEFAULT 0,
        dueDate TEXT,
        category TEXT NOT NULL DEFAULT 'Personal',
        status TEXT NOT NULL DEFAULT 'Pending',
        notes TEXT,
        month TEXT NOT NULL
      )
    ''');

    // Create budget table
    await db.execute('''
      CREATE TABLE budget (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT UNIQUE NOT NULL,
        amount REAL NOT NULL,
        notes TEXT
      )
    ''');

    // Create accounts table (single row for pocket and bank balance)
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        pocket REAL NOT NULL DEFAULT 0,
        bank REAL NOT NULL DEFAULT 0,
        notes TEXT
      )
    ''');

    // Insert default account row
    await db.insert('accounts', {'id': 1, 'pocket': 0, 'bank': 0});

    // Create custom_options table
    await db.execute('''
      CREATE TABLE custom_options (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        UNIQUE(type, name)
      )
    ''');

    // Insert default options
    await _insertDefaultOptions(db);

    debugPrint("✅ Database created successfully");
  }

  Future<void> _insertDefaultOptions(Database db) async {
    final defaultOptions = {
      'expense_category': [
        'Groceries',
        'Drinks',
        'Transport',
        'Restaurant',
        'Health',
        'Utility'
      ],
      'payment_method': [
        'Pocket (Cash)',
        'Bank Account',
        'Credit Card',
        'Debit Card'
      ],
      'shift_role': ['Delivery', 'Warehouse', 'Retail', 'Office', 'Freelance'],
      'bill_category': [
        'Rent',
        'Electricity',
        'Water',
        'Internet',
        'Phone',
        'Insurance'
      ],
      'debt_category': [
        'Personal Loan',
        'Credit Card',
        'Family',
        'Friend',
        'Business'
      ],
    };

    for (final entry in defaultOptions.entries) {
      for (final name in entry.value) {
        await db.insert(
          'custom_options',
          {'type': entry.key, 'name': name},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // The schema is compatible with version 1; version 2 aligns persisted
      // rows with the current model fields.
    }
  }

  // ─── Expenses ─────────────────────────────────────────────────────────────

  Future<List<Expense>> getExpenses({String? month}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (month != null && month.isNotEmpty) {
      maps = await db.query(
        'expenses',
        where: 'month = ?',
        whereArgs: [month],
        orderBy: 'date DESC',
      );
    } else {
      maps = await db.query('expenses', orderBy: 'date DESC');
    }

    return maps.map((map) => Expense.fromJson(map)).toList();
  }

  Future<void> insertExpense(Expense expense,
      {bool deductFromAccount = false}) async {
    final db = await database;
    await db.insert('expenses', {'id': expense.id, ...expense.toJson()},
        conflictAlgorithm: ConflictAlgorithm.replace);

    if (deductFromAccount) {
      final accountType = expense.paymentMethod.toLowerCase().contains('bank')
          ? 'bank'
          : 'pocket';
      await adjustAccount(
          accountType: accountType, amount: expense.price, operation: 'deduct');
    }
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses',
      expense.toJson(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Shifts ───────────────────────────────────────────────────────────────

  Future<List<EarningShift>> getShifts({String? month}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (month != null && month.isNotEmpty) {
      maps = await db.query(
        'shifts',
        where: 'month = ?',
        whereArgs: [month],
        orderBy: 'date DESC',
      );
    } else {
      maps = await db.query('shifts', orderBy: 'date DESC');
    }

    return maps.map((map) => EarningShift.fromJson(map)).toList();
  }

  Future<void> insertShift(EarningShift shift) async {
    final db = await database;
    await db.insert('shifts', {'id': shift.id, ...shift.toJson()},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateShift(EarningShift shift) async {
    final db = await database;
    await db.update(
      'shifts',
      shift.toJson(),
      where: 'id = ?',
      whereArgs: [shift.id],
    );
  }

  Future<void> deleteShift(String id) async {
    final db = await database;
    await db.delete('shifts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleShiftStatus(String id) async {
    final db = await database;
    final shifts = await db.query('shifts', where: 'id = ?', whereArgs: [id]);
    if (shifts.isNotEmpty) {
      final shift = EarningShift.fromJson(shifts.first);
      final newStatus =
          shift.paymentStatus == 'Pending' ? 'Paid' : 'Pending';
      await db.update(
        'shifts',
        {'paymentStatus': newStatus},
        where: 'id = ?',
        whereArgs: [id],
      );

      // If marking as paid, add to account
      if (newStatus == 'Paid') {
        await adjustAccount(
            accountType: 'bank', amount: shift.netAmount, operation: 'add');
      }
    }
  }

  // ─── Fixed Bills ──────────────────────────────────────────────────────────

  Future<List<FixedBill>> getFixedBills({String? month}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (month != null && month.isNotEmpty) {
      maps = await db.query(
        'fixed_bills',
        where: 'month = ?',
        whereArgs: [month],
        orderBy: 'month ASC',
      );
    } else {
      maps = await db.query('fixed_bills', orderBy: 'month ASC');
    }

    return maps.map((map) => FixedBill.fromJson(map)).toList();
  }

  Future<void> insertFixedBill(FixedBill bill) async {
    final db = await database;
    await db.insert('fixed_bills', {'id': bill.id, ...bill.toJson()},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateFixedBill(FixedBill bill) async {
    final db = await database;
    await db.update(
      'fixed_bills',
      bill.toJson(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );
  }

  Future<void> toggleFixedBillStatus(String id) async {
    final db = await database;
    final bills =
        await db.query('fixed_bills', where: 'id = ?', whereArgs: [id]);
    if (bills.isNotEmpty) {
      final isPaid = bills.first['status'] == 'Paid';
      await db.update(
        'fixed_bills',
        {'status': isPaid ? 'Pending' : 'Paid'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> deleteFixedBill(String id) async {
    final db = await database;
    await db.delete('fixed_bills', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Debts ────────────────────────────────────────────────────────────────

  Future<List<DebtItem>> getDebts({String? month}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (month != null && month.isNotEmpty) {
      maps = await db.query(
        'debts',
        where: 'month = ?',
        whereArgs: [month],
        orderBy: 'dueDate ASC',
      );
    } else {
      maps = await db.query('debts', orderBy: 'dueDate ASC');
    }

    return maps.map((map) => DebtItem.fromJson(map)).toList();
  }

  Future<void> insertDebt(DebtItem debt) async {
    final db = await database;
    await db.insert('debts', {'id': debt.id, ...debt.toJson()},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateDebt(DebtItem debt) async {
    final db = await database;
    await db.update(
      'debts',
      debt.toJson(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<void> payDebt({
    required String id,
    required double paymentAmount,
    String? deductFrom,
  }) async {
    final db = await database;
    final debts = await db.query('debts', where: 'id = ?', whereArgs: [id]);
    if (debts.isNotEmpty) {
      final debt = DebtItem.fromJson(debts.first);
      final newPaid = debt.paidAmount + paymentAmount;
      await db.update(
        'debts',
        {'paidAmount': newPaid},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (deductFrom != null) {
        await adjustAccount(
            accountType: deductFrom,
            amount: paymentAmount,
            operation: 'deduct');
      }
    }
  }

  Future<void> deleteDebt(String id) async {
    final db = await database;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Budget ───────────────────────────────────────────────────────────────

  Future<MonthlyBudget> getBudget({String? month}) async {
    final db = await database;
    if (month == null || month.isEmpty) {
      return MonthlyBudget(month: "", amount: 0.0);
    }

    final maps = await db.query(
      'budget',
      where: 'month = ?',
      whereArgs: [month],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return MonthlyBudget.fromJson(maps.first);
    }

    return MonthlyBudget(month: month, amount: 0.0);
  }

  Future<void> setBudget(MonthlyBudget budget) async {
    final db = await database;
    await db.insert(
      'budget',
      budget.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Accounts (Pocket & Bank) ─────────────────────────────────────────────

  Future<AccountBalance> getAccounts() async {
    final db = await database;
    final maps = await db.query('accounts', where: 'id = 1', limit: 1);

    if (maps.isNotEmpty) {
      return AccountBalance.fromJson(maps.first);
    }

    return AccountBalance.initial();
  }

  Future<void> updateAccounts({
    required double pocket,
    required double bank,
    String notes = "",
  }) async {
    final db = await database;
    await db.update(
      'accounts',
      {'pocket': pocket, 'bank': bank, 'notes': notes},
      where: 'id = 1',
    );
  }

  Future<void> adjustAccount({
    required String accountType,
    required double amount,
    String operation = "add",
  }) async {
    final db = await database;
    final accounts = await getAccounts();

    final delta = operation == "deduct" ? -amount.abs() : amount.abs();

    if (accountType == "pocket") {
      final newPocket = (accounts.pocket + delta).clamp(0.0, double.infinity);
      await db.update('accounts', {'pocket': newPocket}, where: 'id = 1');
    } else if (accountType == "bank") {
      final newBank = (accounts.bank + delta).clamp(0.0, double.infinity);
      await db.update('accounts', {'bank': newBank}, where: 'id = 1');
    }
  }

  // ─── Custom Options ───────────────────────────────────────────────────────

  Future<List<String>> getCustomOptions(String type) async {
    final db = await database;
    final maps = await db.query(
      'custom_options',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );

    return maps.map((map) => map['name'] as String).toList();
  }

  Future<void> addCustomOption(String type, String name) async {
    final db = await database;
    await db.insert(
      'custom_options',
      {'type': type, 'name': name},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // ─── Dashboard Summary ────────────────────────────────────────────────────

  Future<DashboardSummary> getSummary({String? month}) async {
    final expenses = await getExpenses(month: month);
    final shifts = await getShifts(month: month);
    final bills = await getFixedBills(month: month);
    final debts = await getDebts(month: month);
    final accounts = await getAccounts();

    // Calculate totals
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.price);
    final paidEarnings = shifts
        .where((s) => s.paymentStatus == 'Paid')
        .fold<double>(0, (sum, s) => sum + s.netAmount);
    final pendingEarnings = shifts
        .where((s) => s.paymentStatus == 'Pending')
        .fold<double>(0, (sum, s) => sum + s.netAmount);
    final totalFixedBills = bills.fold<double>(0, (sum, b) => sum + b.amount);

    // Calculate debt info
    final totalDebt = debts.fold<double>(0, (sum, d) => sum + d.amount);
    final paidDebt = debts.fold<double>(0, (sum, d) => sum + d.paidAmount);
    final remainingDebt = totalDebt - paidDebt;
    final debtPayoffPercent =
        totalDebt > 0 ? (paidDebt / totalDebt * 100) : 0.0;

    // Category breakdown
    final categoryBreakdown = <String, double>{};
    for (final expense in expenses) {
      categoryBreakdown[expense.category] =
          (categoryBreakdown[expense.category] ?? 0) + expense.price;
    }

    // Daily spending for chart
    final dailySpending = <String, double>{};
    for (final expense in expenses) {
      final day = expense.date.day.toString().padLeft(2, '0');
      dailySpending[day] = (dailySpending[day] ?? 0) + expense.price;
    }

    return DashboardSummary(
      totalExpenses: totalExpenses,
      grossEarnings: shifts.fold<double>(0, (sum, s) => sum + s.grossAmount),
      netEarnings: paidEarnings,
      pendingEarnings: pendingEarnings,
      receivedEarnings: paidEarnings,
      totalFixedBills: totalFixedBills,
      netBalance: paidEarnings - totalExpenses - totalFixedBills,
      totalTransactions: expenses.length + shifts.length,
      categoryBreakdown: categoryBreakdown,
      dailySpending: dailySpending,
      pocketBalance: accounts.pocket,
      bankBalance: accounts.bank,
      totalLiquidFunds: accounts.pocket + accounts.bank,
      totalDebt: totalDebt,
      paidDebt: paidDebt,
      remainingDebt: remainingDebt,
      debtPayoffPercent: debtPayoffPercent,
    );
  }

  // ─── Utility Methods ──────────────────────────────────────────────────────

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('shifts');
    await db.delete('fixed_bills');
    await db.delete('debts');
    await db.delete('budget');
    await db.update('accounts', {'pocket': 0, 'bank': 0, 'notes': ''},
        where: 'id = 1');
    debugPrint("✅ All data cleared");
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

import "dart:convert";
import "dart:math" as math;

import "package:flutter/foundation.dart";
import "package:path/path.dart";
import "package:sqflite/sqflite.dart";
import "../models/models.dart";

class DatabaseService {
  static Database? _database;
  static String? _databasePathOverride;
  static const String _dbName = "expense_tracker.db";
  static const int _dbVersion = 7;

  @visibleForTesting
  static void setDatabasePathForTesting(String? path) {
    _databasePathOverride = path;
  }

  static String createRecordId(String prefix) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final random = math.Random().nextInt(1 << 31);
    return "$prefix-$stamp-$random";
  }

  static String ensureRecordId(String? rawId, String prefix) {
    final trimmed = (rawId ?? "").trim();
    if (trimmed.isNotEmpty) return trimmed;
    return createRecordId(prefix);
  }

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
    final path = _databasePathOverride ?? join(dbPath, _dbName);

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
        month TEXT NOT NULL,
        accountDeductedFrom TEXT
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
        minutes INTEGER NOT NULL DEFAULT 0,
        startMinutes INTEGER,
        finishMinutes INTEGER,
        breakMinutes INTEGER NOT NULL DEFAULT 0,
        grossAmount REAL NOT NULL,
        rentDeduction REAL NOT NULL DEFAULT 0,
        taxPercent REAL NOT NULL DEFAULT 0,
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
        month TEXT NOT NULL,
        direction TEXT NOT NULL DEFAULT 'owed'
      )
    ''');

    // Create budget table
    await db.execute('''
      CREATE TABLE budget (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT UNIQUE NOT NULL,
        amount REAL NOT NULL,
        socialInsurance REAL NOT NULL DEFAULT 0,
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
        colorValue INTEGER,
        UNIQUE(type, name)
      )
    ''');

    await _createOfflineSyncTables(db);

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

  Future<void> _ensureShiftColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(shifts)');
    final existing = columns.map((row) => row['name'].toString()).toSet();

    final missingColumns = {
      'minutes': 'INTEGER NOT NULL DEFAULT 0',
      'startMinutes': 'INTEGER',
      'finishMinutes': 'INTEGER',
      'breakMinutes': 'INTEGER NOT NULL DEFAULT 0',
    };

    for (final entry in missingColumns.entries) {
      if (!existing.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE shifts ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // The schema is compatible with version 1; version 2 aligns persisted
      // rows with the current model fields.
    }

    if (oldVersion < 4) {
      await _ensureShiftColumns(db);
      await _ensureBudgetSocialInsuranceColumn(db);
    }

    if (oldVersion < 5) {
      await _ensureCustomOptionColorColumn(db);
      await _createOfflineSyncTables(db);
    }

    if (oldVersion < 6) {
      await _ensureExpenseAccountColumn(db);
      await _ensureDebtDirectionColumn(db);
    }

    if (oldVersion < 7) {
      await _ensurePeopleMoneyHiddenColumn(db);
    }
  }

  Future<void> _ensureExpenseAccountColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(expenses)');
    final names = columns.map((row) => row['name'].toString()).toSet();
    if (!names.contains('accountDeductedFrom')) {
      await db
          .execute('ALTER TABLE expenses ADD COLUMN accountDeductedFrom TEXT');
    }
  }

  Future<void> _ensurePeopleMoneyHiddenColumn(Database db) async {
    final columns =
        await db.rawQuery('PRAGMA table_info(people_money_entries)');
    final names = columns.map((row) => row['name'].toString()).toSet();
    if (!names.contains('hidden')) {
      await db.execute(
        'ALTER TABLE people_money_entries '
        'ADD COLUMN hidden INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  Future<void> _ensureDebtDirectionColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(debts)');
    final names = columns.map((row) => row['name'].toString()).toSet();
    if (!names.contains('direction')) {
      await db.execute(
        "ALTER TABLE debts ADD COLUMN direction TEXT NOT NULL DEFAULT 'owed'",
      );
    }
  }

  Future<void> _createOfflineSyncTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS people_money_entries (
        id TEXT PRIMARY KEY,
        personName TEXT NOT NULL,
        relationship TEXT NOT NULL,
        direction TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        hidden INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity TEXT NOT NULL,
        recordId TEXT NOT NULL,
        remoteId TEXT,
        operation TEXT NOT NULL,
        payload TEXT,
        UNIQUE(entity, recordId)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_id_map (
        entity TEXT NOT NULL,
        localId TEXT NOT NULL,
        remoteId TEXT NOT NULL,
        PRIMARY KEY(entity, localId),
        UNIQUE(entity, remoteId)
      )
    ''');
  }

  Future<void> _ensureCustomOptionColorColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(custom_options)');
    final names = columns.map((row) => row['name'].toString()).toSet();
    if (!names.contains('colorValue')) {
      await db
          .execute('ALTER TABLE custom_options ADD COLUMN colorValue INTEGER');
    }
  }

  Future<void> _queueSync(
    DatabaseExecutor db, {
    required String entity,
    required String recordId,
    required String operation,
    Map<String, dynamic>? payload,
  }) async {
    final mappings = await db.query(
      'sync_id_map',
      columns: ['remoteId'],
      where: 'entity = ? AND localId = ?',
      whereArgs: [entity, recordId],
      limit: 1,
    );
    final pending = await db.query(
      'sync_queue',
      columns: ['remoteId'],
      where: 'entity = ? AND recordId = ?',
      whereArgs: [entity, recordId],
      limit: 1,
    );
    final remoteId = mappings.isNotEmpty
        ? mappings.first['remoteId']?.toString()
        : pending.isNotEmpty
            ? pending.first['remoteId']?.toString()
            : null;
    await db.insert(
      'sync_queue',
      {
        'entity': entity,
        'recordId': recordId,
        'remoteId': remoteId,
        'operation': operation,
        'payload': payload == null ? null : jsonEncode(payload),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _adjustAccountInTransaction(
    DatabaseExecutor db, {
    required String accountType,
    required double amount,
    required String operation,
  }) async {
    if (accountType != 'pocket' && accountType != 'bank') return;
    final accounts = await db.query('accounts', where: 'id = 1', limit: 1);
    final balance = accounts.isEmpty
        ? AccountBalance.initial()
        : AccountBalance.fromJson(accounts.first);
    final delta = operation == 'deduct' ? -amount.abs() : amount.abs();
    final updated = accountType == 'pocket'
        ? balance.copyWith(
            pocket: (balance.pocket + delta).clamp(0.0, double.infinity))
        : balance.copyWith(
            bank: (balance.bank + delta).clamp(0.0, double.infinity));
    final payload = updated.toJson();
    await db.update('accounts', payload, where: 'id = 1');
    await _queueSync(db,
        entity: 'accounts',
        recordId: '1',
        operation: 'upsert',
        payload: payload);
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
        orderBy: 'datetime(date) DESC',
      );
    } else {
      maps = await db.query('expenses', orderBy: 'datetime(date) DESC');
    }

    return maps.map((map) => Expense.fromJson(map)).toList();
  }

  Future<void> insertExpense(Expense expense,
      {bool deductFromAccount = false}) async {
    final db = await database;
    final recordId = ensureRecordId(expense.id, 'expense');
    final paymentMethod = expense.paymentMethod.toLowerCase();
    final deductedFrom = deductFromAccount
        ? paymentMethod.contains('bank') || paymentMethod.contains('debit')
            ? 'bank'
            : 'pocket'
        : expense.accountDeductedFrom;
    final stored = expense.copyWith(
      id: recordId,
      accountDeductedFrom: deductedFrom,
    );
    await db.transaction((txn) async {
      await txn.insert('expenses', {'id': recordId, ...stored.toJson()},
          conflictAlgorithm: ConflictAlgorithm.replace);
      await _queueSync(txn,
          entity: 'expenses',
          recordId: recordId,
          operation: 'upsert',
          payload: stored.toJson());
      if (deductFromAccount && deductedFrom != null) {
        await _adjustAccountInTransaction(
          txn,
          accountType: deductedFrom,
          amount: expense.price,
          operation: 'deduct',
        );
      }
    });
  }

  Future<void> updateExpense(Expense expense,
      {bool updateAccountBalance = true}) async {
    final db = await database;
    await db.transaction((txn) async {
      final existingRows = await txn.query(
        'expenses',
        where: 'id = ?',
        whereArgs: [expense.id],
        limit: 1,
      );
      final existing =
          existingRows.isEmpty ? null : Expense.fromJson(existingRows.first);
      final updated = expense.copyWith(
        accountDeductedFrom:
            expense.accountDeductedFrom ?? existing?.accountDeductedFrom,
      );
      await txn.update(
        'expenses',
        updated.toJson(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
      await _queueSync(txn,
          entity: 'expenses',
          recordId: updated.id,
          operation: 'upsert',
          payload: updated.toJson());
      if (updateAccountBalance) {
        final previousAccount = existing?.accountDeductedFrom;
        if (existing != null &&
            (previousAccount == 'pocket' || previousAccount == 'bank')) {
          await _adjustAccountInTransaction(
            txn,
            accountType: previousAccount!,
            amount: existing.price,
            operation: 'add',
          );
        }
        final nextAccount = updated.accountDeductedFrom;
        if (nextAccount == 'pocket' || nextAccount == 'bank') {
          await _adjustAccountInTransaction(
            txn,
            accountType: nextAccount!,
            amount: updated.price,
            operation: 'deduct',
          );
        }
      }
    });
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await _queueSync(txn,
          entity: 'expenses', recordId: id, operation: 'delete');
      await txn.delete('expenses', where: 'id = ?', whereArgs: [id]);
    });
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
        orderBy: 'datetime(date) DESC',
      );
    } else {
      maps = await db.query('shifts', orderBy: 'datetime(date) DESC');
    }

    return maps.map((map) => EarningShift.fromJson(map)).toList();
  }

  Future<void> insertShift(EarningShift shift) async {
    final db = await database;
    final recordId = ensureRecordId(shift.id, 'shift');
    final stored = shift.copyWith(id: recordId);
    await db.transaction((txn) async {
      await txn.insert('shifts', {'id': recordId, ...stored.toJson()},
          conflictAlgorithm: ConflictAlgorithm.replace);
      await _queueSync(txn,
          entity: 'shifts',
          recordId: recordId,
          operation: 'upsert',
          payload: stored.toJson());
    });
  }

  Future<void> updateShift(EarningShift shift) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'shifts',
        shift.toJson(),
        where: 'id = ?',
        whereArgs: [shift.id],
      );
      await _queueSync(txn,
          entity: 'shifts',
          recordId: shift.id,
          operation: 'upsert',
          payload: shift.toJson());
    });
  }

  Future<void> deleteShift(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await _queueSync(txn,
          entity: 'shifts', recordId: id, operation: 'delete');
      await txn.delete('shifts', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> toggleShiftStatus(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      final shifts =
          await txn.query('shifts', where: 'id = ?', whereArgs: [id], limit: 1);
      if (shifts.isEmpty) return;
      final shift = EarningShift.fromJson(shifts.first);
      final newStatus =
          shift.paymentStatus == 'Pending' ? 'Received' : 'Pending';
      await txn.update(
        'shifts',
        {'paymentStatus': newStatus},
        where: 'id = ?',
        whereArgs: [id],
      );
      final updatedShift = shift.copyWith(paymentStatus: newStatus);
      await _queueSync(txn,
          entity: 'shifts',
          recordId: id,
          operation: 'upsert',
          payload: updatedShift.toJson());

      if (newStatus == 'Received') {
        await _adjustAccountInTransaction(txn,
            accountType: shift.depositTo == 'Pocket' ? 'pocket' : 'bank',
            amount: shift.netAmount,
            operation: 'add');
      }
    });
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
    final recordId = ensureRecordId(bill.id, 'bill');
    final stored = bill.copyWith(id: recordId);
    await db.transaction((txn) async {
      await txn.insert('fixed_bills', {'id': recordId, ...stored.toJson()},
          conflictAlgorithm: ConflictAlgorithm.replace);
      await _queueSync(txn,
          entity: 'fixed-bills',
          recordId: recordId,
          operation: 'upsert',
          payload: stored.toJson());
    });
  }

  Future<void> updateFixedBill(FixedBill bill) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'fixed_bills',
        bill.toJson(),
        where: 'id = ?',
        whereArgs: [bill.id],
      );
      await _queueSync(txn,
          entity: 'fixed-bills',
          recordId: bill.id,
          operation: 'upsert',
          payload: bill.toJson());
    });
  }

  Future<void> toggleFixedBillStatus(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      final bills = await txn.query('fixed_bills',
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (bills.isEmpty) return;
      final isPaid = bills.first['status'] == 'Paid';
      final updated = FixedBill.fromJson(bills.first).copyWith(
        status: isPaid ? 'Pending' : 'Paid',
      );
      await txn.update(
        'fixed_bills',
        {'status': updated.status},
        where: 'id = ?',
        whereArgs: [id],
      );
      await _queueSync(txn,
          entity: 'fixed-bills',
          recordId: id,
          operation: 'upsert',
          payload: updated.toJson());
    });
  }

  Future<void> deleteFixedBill(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await _queueSync(txn,
          entity: 'fixed-bills', recordId: id, operation: 'delete');
      await txn.delete('fixed_bills', where: 'id = ?', whereArgs: [id]);
    });
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
    final recordId = ensureRecordId(debt.id, 'debt');
    final stored = debt.copyWith(id: recordId);
    await db.transaction((txn) async {
      await txn.insert('debts', {'id': recordId, ...stored.toJson()},
          conflictAlgorithm: ConflictAlgorithm.replace);
      await _queueSync(txn,
          entity: 'debts',
          recordId: recordId,
          operation: 'upsert',
          payload: stored.toJson());
    });
  }

  Future<void> updateDebt(DebtItem debt) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'debts',
        debt.toJson(),
        where: 'id = ?',
        whereArgs: [debt.id],
      );
      await _queueSync(txn,
          entity: 'debts',
          recordId: debt.id,
          operation: 'upsert',
          payload: debt.toJson());
    });
  }

  Future<void> payDebt({
    required String id,
    required double paymentAmount,
    String? deductFrom,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final debts =
          await txn.query('debts', where: 'id = ?', whereArgs: [id], limit: 1);
      if (debts.isEmpty) return;
      final debt = DebtItem.fromJson(debts.first);
      final newPaid = debt.paidAmount + paymentAmount;
      final status = newPaid >= debt.amount
          ? 'Settled'
          : newPaid > 0
              ? 'Partial'
              : 'Pending';
      final updatedDebt = debt.copyWith(paidAmount: newPaid, status: status);
      await txn.update(
        'debts',
        {'paidAmount': newPaid, 'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
      await _queueSync(txn,
          entity: 'debts',
          recordId: id,
          operation: 'upsert',
          payload: updatedDebt.toJson());

      if (deductFrom != null) {
        await _adjustAccountInTransaction(txn,
            accountType: deductFrom,
            amount: paymentAmount,
            operation: debt.direction == 'owed_to_me' ? 'add' : 'deduct');
      }
    });
  }

  Future<void> deleteDebt(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await _queueSync(txn, entity: 'debts', recordId: id, operation: 'delete');
      await txn.delete('debts', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ─── Budget ───────────────────────────────────────────────────────────────

  Future<void> _ensureBudgetSocialInsuranceColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(budget)');
    final names = columns.map((row) => row['name'].toString()).toSet();
    if (!names.contains('socialInsurance')) {
      await db.execute(
        'ALTER TABLE budget ADD COLUMN socialInsurance REAL NOT NULL DEFAULT 0',
      );
    }
  }

  Future<MonthlyBudget> getBudget({String? month}) async {
    final db = await database;
    await _ensureBudgetSocialInsuranceColumn(db);
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
    await _ensureBudgetSocialInsuranceColumn(db);
    await db.transaction((txn) async {
      await txn.insert(
        'budget',
        budget.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _queueSync(txn,
          entity: 'budgets',
          recordId: budget.month,
          operation: 'upsert',
          payload: budget.toJson());
    });
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
    final payload = {'pocket': pocket, 'bank': bank, 'notes': notes};
    await db.transaction((txn) async {
      await txn.update('accounts', payload, where: 'id = 1');
      await _queueSync(txn,
          entity: 'accounts',
          recordId: '1',
          operation: 'upsert',
          payload: payload);
    });
  }

  Future<void> adjustAccount({
    required String accountType,
    required double amount,
    String operation = "add",
  }) async {
    final db = await database;
    await db.transaction((txn) => _adjustAccountInTransaction(
          txn,
          accountType: accountType,
          amount: amount,
          operation: operation,
        ));
  }

  // ─── Custom Options ───────────────────────────────────────────────────────

  Future<List<CustomOption>> getCustomOptions(String type) async {
    final db = await database;
    final maps = await db.query(
      'custom_options',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );

    return maps
        .map((map) => CustomOption.fromJson({
              ...map,
              'id': map['id'].toString(),
            }))
        .toList();
  }

  Future<void> addCustomOption(String type, String name,
      {int? colorValue}) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'custom_options',
        {'type': type, 'name': name, 'colorValue': colorValue},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      final recordId = '$type::${name.toLowerCase()}';
      await _queueSync(txn,
          entity: 'custom-options',
          recordId: recordId,
          operation: 'upsert',
          payload: {
            'type': type,
            'name': name,
            if (colorValue != null) 'colorValue': colorValue,
          });
    });
  }

  Future<List<PeopleMoneyEntry>> getPeopleMoneyEntries() async {
    final db = await database;
    final maps = await db.query(
      'people_money_entries',
      orderBy: 'datetime(date) DESC',
    );
    return maps.map((map) => PeopleMoneyEntry.fromJson(map)).toList();
  }

  Future<void> insertPeopleMoneyEntry(PeopleMoneyEntry entry) async {
    final db = await database;
    final recordId = ensureRecordId(entry.id, 'people-money');
    final stored = PeopleMoneyEntry(
      id: recordId,
      personName: entry.personName,
      relationship: entry.relationship,
      direction: entry.direction,
      amount: entry.amount,
      date: entry.date,
      notes: entry.notes,
      isHidden: entry.isHidden,
    );
    await db.transaction((txn) async {
      await txn.insert(
        'people_money_entries',
        {'id': recordId, ..._peopleMoneyEntryToDatabase(stored)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _queueSync(txn,
          entity: 'people-money',
          recordId: recordId,
          operation: 'upsert',
          payload: stored.toJson());
    });
  }

  Future<void> updatePeopleMoneyEntry(PeopleMoneyEntry entry) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'people_money_entries',
        _peopleMoneyEntryToDatabase(entry),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
      await _queueSync(txn,
          entity: 'people-money',
          recordId: entry.id,
          operation: 'upsert',
          payload: entry.toJson());
    });
  }

  Future<void> deletePeopleMoneyEntry(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await _queueSync(txn,
          entity: 'people-money', recordId: id, operation: 'delete');
      await txn.delete(
        'people_money_entries',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Map<String, dynamic> _peopleMoneyEntryToDatabase(PeopleMoneyEntry entry) => {
        ...entry.toJson(),
        'hidden': entry.isHidden ? 1 : 0,
      };

  Future<List<Map<String, dynamic>>> pendingSyncOperations() async {
    final db = await database;
    final rows = await db.query('sync_queue', orderBy: 'id ASC');
    return rows.map((row) {
      final payload = row['payload'] as String?;
      return {
        'queueId': row['id'],
        'entity': row['entity'],
        'recordId': row['recordId'],
        'remoteId': row['remoteId'],
        'operation': row['operation'],
        'payload': payload == null
            ? null
            : jsonDecode(payload) as Map<String, dynamic>,
      };
    }).toList();
  }

  Future<int> pendingSyncCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS count FROM sync_queue');
    return (result.first['count'] as num).toInt();
  }

  Future<void> acknowledgeSyncOperation({
    required int queueId,
    required String entity,
    required String recordId,
    required String operation,
    String? remoteId,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('sync_queue', where: 'id = ?', whereArgs: [queueId]);
      if (operation == 'delete') {
        await txn.delete(
          'sync_id_map',
          where: 'entity = ? AND localId = ?',
          whereArgs: [entity, recordId],
        );
      } else if (remoteId != null && remoteId.isNotEmpty) {
        await txn.insert(
          'sync_id_map',
          {'entity': entity, 'localId': recordId, 'remoteId': remoteId},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> applyRemoteSnapshot(Map<String, dynamic> snapshot) async {
    final db = await database;
    await db.transaction((txn) async {
      await _mergeRemoteRecords(txn, 'expenses', 'expenses',
          snapshot['expenses'] as List? ?? const []);
      await _mergeRemoteRecords(
          txn, 'shifts', 'shifts', snapshot['shifts'] as List? ?? const []);
      await _mergeRemoteRecords(txn, 'fixed-bills', 'fixed_bills',
          snapshot['fixedBills'] as List? ?? const []);
      await _mergeRemoteRecords(
          txn, 'debts', 'debts', snapshot['debts'] as List? ?? const []);
      await _mergeRemoteRecords(txn, 'people-money', 'people_money_entries',
          snapshot['peopleMoney'] as List? ?? const []);

      final budgets = snapshot['budgets'] as List? ?? const [];
      for (final item in budgets) {
        final record = Map<String, dynamic>.from(item as Map);
        final month = record['month']?.toString();
        if (month == null || month.isEmpty) continue;
        if (await _hasPending(txn, 'budgets', month)) continue;
        await txn.insert(
          'budget',
          MonthlyBudget.fromJson(record).toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final account = snapshot['accounts'];
      if (account is Map) {
        final record = Map<String, dynamic>.from(account);
        if (!await _hasPending(txn, 'accounts', '1')) {
          await txn.update(
            'accounts',
            AccountBalance.fromJson(record).toJson(),
            where: 'id = 1',
          );
        }
      }

      final options = snapshot['customOptions'] as List? ?? const [];
      for (final item in options) {
        final record = Map<String, dynamic>.from(item as Map);
        final type = record['type']?.toString() ?? '';
        final name = record['name']?.toString() ?? '';
        if (type.isEmpty || name.isEmpty) continue;
        final key = '$type::${name.toLowerCase()}';
        if (await _hasPending(txn, 'custom-options', key)) continue;
        await txn.insert(
          'custom_options',
          {
            'type': type,
            'name': name,
            'colorValue': record['colorValue'],
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  Future<bool> _hasPending(
      DatabaseExecutor db, String entity, String recordId) async {
    final rows = await db.query(
      'sync_queue',
      columns: ['id'],
      where: 'entity = ? AND recordId = ?',
      whereArgs: [entity, recordId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> _mergeRemoteRecords(
    DatabaseExecutor db,
    String entity,
    String table,
    List<dynamic> records,
  ) async {
    for (final item in records) {
      final record = Map<String, dynamic>.from(item as Map);
      final remoteId = record['_id']?.toString();
      if (remoteId == null || remoteId.isEmpty) continue;
      final clientId = record['clientId']?.toString();
      final mappings = await db.query(
        'sync_id_map',
        columns: ['localId'],
        where: 'entity = ? AND remoteId = ?',
        whereArgs: [entity, remoteId],
        limit: 1,
      );
      final localId = mappings.isNotEmpty
          ? mappings.first['localId'].toString()
          : clientId ?? remoteId;
      await db.insert(
        'sync_id_map',
        {'entity': entity, 'localId': localId, 'remoteId': remoteId},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (await _hasPending(db, entity, localId)) continue;

      if (entity == 'expenses') {
        await db.insert(
          table,
          {'id': localId, ...Expense.fromJson(record).toJson()},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else if (entity == 'shifts') {
        await db.insert(
          table,
          {'id': localId, ...EarningShift.fromJson(record).toJson()},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else if (entity == 'fixed-bills') {
        await db.insert(
          table,
          {'id': localId, ...FixedBill.fromJson(record).toJson()},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else if (entity == 'debts') {
        await db.insert(
          table,
          {'id': localId, ...DebtItem.fromJson(record).toJson()},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else if (entity == 'people-money') {
        final entry = PeopleMoneyEntry.fromJson(record);
        await db.insert(
          table,
          {'id': localId, ..._peopleMoneyEntryToDatabase(entry)},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  // ─── Dashboard Summary ────────────────────────────────────────────────────

  Future<DashboardSummary> getSummary({String? month}) async {
    final expenses = await getExpenses(month: month);
    final shifts = await getShifts(month: month);
    final bills = await getFixedBills(month: month);
    final debts = await getDebts();
    final accounts = await getAccounts();
    final budget = await getBudget(month: month);

    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.price);
    final netEarnings =
        shifts.fold<double>(0, (sum, shift) => sum + shift.netAmount);
    final receivedEarnings = shifts
        .where((s) => s.paymentStatus == 'Received')
        .fold<double>(0, (sum, s) => sum + s.netAmount);
    final pendingEarnings = shifts
        .where((s) => s.paymentStatus == 'Pending')
        .fold<double>(0, (sum, s) => sum + s.netAmount);
    final totalFixedBills = bills.fold<double>(0, (sum, b) => sum + b.amount);
    final paidFixedBills = bills
        .where((bill) => bill.status == 'Paid')
        .fold<double>(0, (sum, bill) => sum + bill.amount);

    final totalDebt = debts.fold<double>(0, (sum, d) => sum + d.amount);
    final paidDebt = debts.fold<double>(0, (sum, d) => sum + d.paidAmount);
    final remainingDebt = math.max(0.0, totalDebt - paidDebt).toDouble();
    final debtPayoffPercent =
        totalDebt > 0 ? (paidDebt / totalDebt * 100) : 100.0;

    // Category breakdown
    final categoryBreakdown = <String, double>{};
    for (final expense in expenses) {
      categoryBreakdown[expense.category] =
          (categoryBreakdown[expense.category] ?? 0) + expense.price;
    }

    final dailySpending = <String, double>{};
    for (final expense in expenses) {
      final day =
          '${expense.date.day.toString().padLeft(2, '0')}/${expense.date.month.toString().padLeft(2, '0')}';
      dailySpending[day] = (dailySpending[day] ?? 0) + expense.price;
    }
    final remainingBudget =
        budget.amount > 0 ? budget.amount - totalExpenses : 0.0;

    return DashboardSummary(
      month: month ?? '',
      totalExpenses: totalExpenses,
      grossEarnings: shifts.fold<double>(0, (sum, s) => sum + s.grossAmount),
      netEarnings: netEarnings,
      pendingEarnings: pendingEarnings,
      receivedEarnings: receivedEarnings,
      totalFixedBills: totalFixedBills,
      monthlyBudget: budget.amount,
      remainingBudget: remainingBudget,
      budgetUsedPercent:
          budget.amount > 0 ? totalExpenses / budget.amount * 100 : 0,
      netBalance: netEarnings - totalExpenses - paidFixedBills,
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
    final db = _database;
    if (db == null) return;
    await db.close();
    _database = null;
  }
}

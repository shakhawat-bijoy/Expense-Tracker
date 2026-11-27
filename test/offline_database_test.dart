import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:path/path.dart" as path;
import "package:sqflite_common_ffi/sqflite_ffi.dart";
import "package:expense_shift_tracker/models/models.dart";
import "package:expense_shift_tracker/services/database_service.dart";

void main() {
  late Directory testDirectory;
  final database = DatabaseService.instance;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp("expense-offline-");
    DatabaseService.setDatabasePathForTesting(
      path.join(testDirectory.path, "offline-test.db"),
    );
  });

  tearDown(() async {
    await database.close();
    DatabaseService.setDatabasePathForTesting(null);
    await testDirectory.delete(recursive: true);
  });

  test("stores money entries and pending changes across database reopen",
      () async {
    final entry = PeopleMoneyEntry(
      id: "",
      personName: "Local person",
      relationship: "Friend",
      direction: "given",
      amount: 25,
      date: DateTime(2026, 11, 27),
      notes: "Saved offline",
    );

    await database.insertPeopleMoneyEntry(entry);
    await database.close();

    final entries = await database.getPeopleMoneyEntries();
    final pending = await database.pendingSyncOperations();

    expect(entries, hasLength(1));
    expect(entries.single.personName, "Local person");
    expect(entries.single.relationship, "Friend");
    expect(entries.single.direction, "given");
    expect(entries.single.amount, 25);
    expect(entries.single.date, entry.date);
    expect(entries.single.notes, "Saved offline");
    expect(pending, hasLength(1));
    expect(pending.single["entity"], "people-money");
    expect(pending.single["operation"], "upsert");
  });

  test("updates queued data locally and keeps user deletions queued", () async {
    final expense = Expense(
      id: "local-expense-1",
      item: "Groceries",
      category: "Groceries",
      price: 10,
      date: DateTime(2026, 11, 27),
    );
    await database.insertExpense(expense);
    await database.updateExpense(expense.copyWith(price: 12));

    var pending = await database.pendingSyncOperations();
    expect(pending, hasLength(1));
    expect(pending.single["operation"], "upsert");
    expect(
      (pending.single["payload"] as Map<String, dynamic>)["price"],
      12,
    );

    await database.deleteExpense(expense.id);
    expect(await database.getExpenses(), isEmpty);
    pending = await database.pendingSyncOperations();
    expect(pending, hasLength(1));
    expect(pending.single["operation"], "delete");
  });

  test("merges server data without overwriting pending local edits", () async {
    final expense = Expense(
      id: "local-expense-2",
      item: "Local value",
      category: "Other",
      price: 5,
      date: DateTime(2026, 11, 27),
    );
    await database.insertExpense(expense);

    await database.applyRemoteSnapshot({
      "expenses": [
        {
          "_id": "remote-expense-2",
          "clientId": expense.id,
          "item": "Server value",
          "category": "Other",
          "price": 7,
          "date": "2026-11-27T00:00:00.000",
          "month": "2026-11",
        },
        {
          "_id": "remote-expense-3",
          "item": "Imported value",
          "category": "Other",
          "price": 8,
          "date": "2026-11-26T00:00:00.000",
          "month": "2026-11",
        },
      ],
    });

    final expenses = await database.getExpenses();
    expect(
      expenses.singleWhere((record) => record.id == expense.id).item,
      "Local value",
    );
    expect(
      expenses.singleWhere((record) => record.id == "remote-expense-3").item,
      "Imported value",
    );
    expect(await database.pendingSyncCount(), 1);
  });

  test("upgrades an existing database without removing its records", () async {
    final oldDatabase = await openDatabase(
      path.join(testDirectory.path, "offline-test.db"),
      version: 4,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE expenses (id TEXT PRIMARY KEY, item TEXT NOT NULL, "
          "price REAL NOT NULL, category TEXT NOT NULL, "
          "paymentMethod TEXT NOT NULL, date TEXT NOT NULL, notes TEXT, "
          "month TEXT NOT NULL)",
        );
        await db.execute(
          "CREATE TABLE debts (id TEXT PRIMARY KEY, title TEXT NOT NULL, "
          "personName TEXT, amount REAL NOT NULL, paidAmount REAL NOT NULL, "
          "dueDate TEXT, category TEXT NOT NULL, status TEXT NOT NULL, "
          "notes TEXT, month TEXT NOT NULL)",
        );
        await db.execute(
          "CREATE TABLE custom_options (id INTEGER PRIMARY KEY AUTOINCREMENT, "
          "type TEXT NOT NULL, name TEXT NOT NULL, UNIQUE(type, name))",
        );
        await db.insert("expenses", {
          "id": "existing-expense",
          "item": "Preserve me",
          "price": 42.0,
          "category": "Other",
          "paymentMethod": "Pocket",
          "date": "2026-11-27T00:00:00.000",
          "notes": "Existing local record",
          "month": "2026-11",
        });
      },
    );
    await oldDatabase.close();

    final upgraded = await database.database;
    final records = await upgraded.query("expenses");
    final queueTables = await upgraded.query(
      "sqlite_master",
      columns: ["name"],
      where: "type = ? AND name = ?",
      whereArgs: ["table", "sync_queue"],
    );

    expect(records, hasLength(1));
    expect(records.single["item"], "Preserve me");
    expect(queueTables, hasLength(1));
    expect(await database.pendingSyncCount(), 0);
  });
}

// This file exists for compatibility but now uses SQLite internally
export 'database_service.dart';

// Re-export DatabaseService as MongoService for compatibility
import 'database_service.dart';

class MongoService {
  static final _db = DatabaseService.instance;

  static Future<void> loadBaseUrl() async {
    // No-op for SQLite
  }

  static Future<void> setCustomBaseUrl(String url) async {
    // No-op for SQLite
  }

  static String get baseUrl => "";

  static Future<void> connect() async {
    // Initialize database
    await _db.database;
  }

  // Delegate all methods to DatabaseService
  static Future<dynamic> getAccounts() => _db.getAccounts();
  static Future<void> updateAccounts(
          {required double pocket, required double bank, String notes = ""}) =>
      _db.updateAccounts(pocket: pocket, bank: bank, notes: notes);
  static Future<void> adjustAccount(
          {required String accountType,
          required double amount,
          String operation = "add"}) =>
      _db.adjustAccount(
          accountType: accountType, amount: amount, operation: operation);

  static Future<List<dynamic>> getDebts({String? month}) =>
      _db.getDebts(month: month);
  static Future<void> insertDebt(dynamic debt) => _db.insertDebt(debt);
  static Future<void> updateDebt(dynamic debt) => _db.updateDebt(debt);
  static Future<void> payDebt(
          {required String id,
          required double paymentAmount,
          String? deductFrom}) =>
      _db.payDebt(id: id, paymentAmount: paymentAmount, deductFrom: deductFrom);
  static Future<void> deleteDebt(String id) => _db.deleteDebt(id);

  static Future<List<String>> getCustomOptions(String type) =>
      _db.getCustomOptions(type);
  static Future<void> addCustomOption(String type, String name) =>
      _db.addCustomOption(type, name);

  static Future<List<dynamic>> getExpenses({String? month}) =>
      _db.getExpenses(month: month);
  static Future<void> insertExpense(dynamic expense,
          {bool deductFromAccount = false}) =>
      _db.insertExpense(expense, deductFromAccount: deductFromAccount);
  static Future<void> updateExpense(dynamic expense) =>
      _db.updateExpense(expense);
  static Future<void> deleteExpense(String id) => _db.deleteExpense(id);

  static Future<List<dynamic>> getShifts({String? month}) =>
      _db.getShifts(month: month);
  static Future<void> insertShift(dynamic shift) => _db.insertShift(shift);
  static Future<void> updateShift(dynamic shift) => _db.updateShift(shift);
  static Future<void> deleteShift(String id) => _db.deleteShift(id);
  static Future<void> toggleShiftStatus(String id) => _db.toggleShiftStatus(id);

  static Future<List<dynamic>> getFixedBills({String? month}) =>
      _db.getFixedBills(month: month);
  static Future<void> insertFixedBill(dynamic bill) =>
      _db.insertFixedBill(bill);
  static Future<void> updateFixedBill(dynamic bill) =>
      _db.updateFixedBill(bill);
  static Future<void> toggleFixedBillStatus(String id) =>
      _db.toggleFixedBillStatus(id);
  static Future<void> deleteFixedBill(String id) => _db.deleteFixedBill(id);

  static Future<dynamic> getBudget({String? month}) =>
      _db.getBudget(month: month);
  static Future<void> setBudget(dynamic budget) => _db.setBudget(budget);

  static Future<dynamic> getSummary({String? month}) =>
      _db.getSummary(month: month);
}

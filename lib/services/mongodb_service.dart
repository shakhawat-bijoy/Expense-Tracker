import "dart:async";
import "dart:convert";

import "package:connectivity_plus/connectivity_plus.dart";
import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;

import "../models/models.dart";
import "database_service.dart";
import "mongodb_service_old.dart" as remote;

class MongoService {
  static final DatabaseService _db = DatabaseService.instance;
  static StreamSubscription<List<ConnectivityResult>>? _connectivity;
  static Timer? _retryTimer;
  static bool _isSyncing = false;
  static String? _lastSyncError;
  static VoidCallback? _onSyncStateChanged;

  static String get baseUrl => remote.MongoService.baseUrl;
  static bool get isSyncing => _isSyncing;
  static String? get lastSyncError => _lastSyncError;
  static Future<int> get pendingSyncCount => _db.pendingSyncCount();

  static Future<void> loadBaseUrl() => remote.MongoService.loadBaseUrl();

  static Future<void> setCustomBaseUrl(String url) async {
    await remote.MongoService.setCustomBaseUrl(url);
    await syncPendingChanges();
  }

  static Future<void> connect() async {
    await _db.database;
    await remote.MongoService.loadBaseUrl();
    _connectivity ??= Connectivity().onConnectivityChanged.listen(
      (results) {
        if (results.any((result) => result != ConnectivityResult.none)) {
          unawaited(syncPendingChanges());
        }
      },
      onError: (Object error) {
        debugPrint("Connectivity monitoring failed: $error");
      },
    );
    _retryTimer ??= Timer.periodic(const Duration(seconds: 30), (_) async {
      if (await _db.pendingSyncCount() > 0) {
        await syncPendingChanges();
      }
    });
    unawaited(syncPendingChanges());
  }

  static void setOnSyncStateChanged(VoidCallback? callback) {
    _onSyncStateChanged = callback;
  }

  static Future<bool> syncPendingChanges() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    _onSyncStateChanged?.call();
    var succeeded = false;
    try {
      final health = await http
          .get(Uri.parse("$baseUrl/health"))
          .timeout(const Duration(seconds: 4));
      if (health.statusCode != 200) {
        throw StateError("Backend health check failed (${health.statusCode}).");
      }

      final operations = await _db.pendingSyncOperations();
      if (operations.isNotEmpty) {
        final failures = <dynamic>[];
        for (var start = 0; start < operations.length; start += 10) {
          final batch = operations.skip(start).take(10).toList();
          final response = await http
              .post(
                Uri.parse("$baseUrl/sync"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "operations": batch
                      .map((operation) => {
                            "queueId": operation["queueId"],
                            "entity": operation["entity"],
                            "recordId": operation["recordId"],
                            "remoteId": operation["remoteId"],
                            "action": operation["operation"],
                            "payload": operation["payload"],
                          })
                      .toList(),
                }),
              )
              .timeout(const Duration(seconds: 15));
          if (response.statusCode != 200) {
            throw StateError("Sync failed (${response.statusCode}).");
          }

          final result = jsonDecode(response.body) as Map<String, dynamic>;
          final acknowledged =
              result["acknowledged"] as List<dynamic>? ?? const [];
          for (final item in acknowledged) {
            final ack = Map<String, dynamic>.from(item as Map);
            final operation = batch.firstWhere(
              (pending) => pending["queueId"] == ack["queueId"],
            );
            await _db.acknowledgeSyncOperation(
              queueId: ack["queueId"] as int,
              entity: operation["entity"] as String,
              recordId: operation["recordId"] as String,
              operation: operation["operation"] as String,
              remoteId: ack["remoteId"]?.toString(),
            );
          }
          failures.addAll(result["failed"] as List<dynamic>? ?? const []);
        }
        if (failures.isNotEmpty) {
          throw StateError(
            "Some changes could not sync (${failures.length} pending).",
          );
        }
      }

      final snapshotResponse = await http
          .get(Uri.parse("$baseUrl/sync/snapshot"))
          .timeout(const Duration(seconds: 15));
      if (snapshotResponse.statusCode != 200) {
        throw StateError(
          "Could not refresh synced data (${snapshotResponse.statusCode}).",
        );
      }
      await _db.applyRemoteSnapshot(
        Map<String, dynamic>.from(jsonDecode(snapshotResponse.body) as Map),
      );
      _lastSyncError = null;
      succeeded = true;
    } catch (error) {
      _lastSyncError = error.toString();
      debugPrint("Offline data sync failed: $error");
    } finally {
      _isSyncing = false;
      _onSyncStateChanged?.call();
    }
    return succeeded;
  }

  static Future<void> _afterMutation(Future<void> Function() mutation) async {
    await mutation();
    unawaited(syncPendingChanges());
  }

  static Future<AccountBalance> getAccounts() => _db.getAccounts();

  static Future<void> updateAccounts({
    required double pocket,
    required double bank,
    String notes = "",
  }) =>
      _afterMutation(
          () => _db.updateAccounts(pocket: pocket, bank: bank, notes: notes));

  static Future<void> adjustAccount({
    required String accountType,
    required double amount,
    String operation = "add",
  }) =>
      _afterMutation(() => _db.adjustAccount(
            accountType: accountType,
            amount: amount,
            operation: operation,
          ));

  static Future<List<DebtItem>> getDebts({String? month}) =>
      _db.getDebts(month: month);

  static Future<void> insertDebt(DebtItem debt) =>
      _afterMutation(() => _db.insertDebt(debt));

  static Future<void> updateDebt(DebtItem debt) =>
      _afterMutation(() => _db.updateDebt(debt));

  static Future<void> payDebt({
    required String id,
    required double paymentAmount,
    String? deductFrom,
  }) =>
      _afterMutation(() => _db.payDebt(
            id: id,
            paymentAmount: paymentAmount,
            deductFrom: deductFrom,
          ));

  static Future<void> deleteDebt(String id) =>
      _afterMutation(() => _db.deleteDebt(id));

  static Future<List<PeopleMoneyEntry>> getPeopleMoneyEntries() =>
      _db.getPeopleMoneyEntries();

  static Future<void> insertPeopleMoneyEntry(PeopleMoneyEntry entry) =>
      _afterMutation(() => _db.insertPeopleMoneyEntry(entry));

  static Future<void> updatePeopleMoneyEntry(PeopleMoneyEntry entry) =>
      _afterMutation(() => _db.updatePeopleMoneyEntry(entry));

  static Future<void> deletePeopleMoneyEntry(String id) =>
      _afterMutation(() => _db.deletePeopleMoneyEntry(id));

  static Future<List<CustomOption>> getCustomOptions(String type) =>
      _db.getCustomOptions(type);

  static Future<void> addCustomOption(String type, String name,
          {int? colorValue}) =>
      _afterMutation(
          () => _db.addCustomOption(type, name, colorValue: colorValue));

  static Future<List<Expense>> getExpenses({String? month}) =>
      _db.getExpenses(month: month);

  static Future<void> insertExpense(Expense expense,
          {bool deductFromAccount = false}) =>
      _afterMutation(() =>
          _db.insertExpense(expense, deductFromAccount: deductFromAccount));

  static Future<void> updateExpense(Expense expense,
          {bool updateAccountBalance = true}) =>
      _afterMutation(() => _db.updateExpense(
            expense,
            updateAccountBalance: updateAccountBalance,
          ));

  static Future<void> deleteExpense(String id) =>
      _afterMutation(() => _db.deleteExpense(id));

  static Future<List<EarningShift>> getShifts({String? month}) =>
      _db.getShifts(month: month);

  static Future<void> insertShift(EarningShift shift) =>
      _afterMutation(() => _db.insertShift(shift));

  static Future<void> updateShift(EarningShift shift) =>
      _afterMutation(() => _db.updateShift(shift));

  static Future<void> deleteShift(String id) =>
      _afterMutation(() => _db.deleteShift(id));

  static Future<void> toggleShiftStatus(String id) =>
      _afterMutation(() => _db.toggleShiftStatus(id));

  static Future<List<FixedBill>> getFixedBills({String? month}) =>
      _db.getFixedBills(month: month);

  static Future<void> insertFixedBill(FixedBill bill) =>
      _afterMutation(() => _db.insertFixedBill(bill));

  static Future<void> updateFixedBill(FixedBill bill) =>
      _afterMutation(() => _db.updateFixedBill(bill));

  static Future<void> toggleFixedBillStatus(String id) =>
      _afterMutation(() => _db.toggleFixedBillStatus(id));

  static Future<void> deleteFixedBill(String id) =>
      _afterMutation(() => _db.deleteFixedBill(id));

  static Future<MonthlyBudget> getBudget({String? month}) =>
      _db.getBudget(month: month);

  static Future<void> setBudget(MonthlyBudget budget) =>
      _afterMutation(() => _db.setBudget(budget));

  static Future<DashboardSummary> getSummary({String? month}) =>
      _db.getSummary(month: month);
}

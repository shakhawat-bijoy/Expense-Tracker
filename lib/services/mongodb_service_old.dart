import "dart:convert";
import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";
import "../models/models.dart";

class MongoService {
  static const String _configuredBaseUrl =
      String.fromEnvironment("API_BASE_URL");
  static String? _customBaseUrl;

  static Future<void> loadBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customBaseUrl = prefs.getString("custom_backend_url");
    } catch (_) {}
  }

  static Future<void> setCustomBaseUrl(String url) async {
    _customBaseUrl = url.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customBaseUrl!.isEmpty) {
        await prefs.remove("custom_backend_url");
        _customBaseUrl = null;
      } else {
        await prefs.setString("custom_backend_url", _customBaseUrl!);
      }
    } catch (_) {}
    _isConnected = false;
    await connect();
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _normalizeBaseUrl(_customBaseUrl!);
    }
    if (_configuredBaseUrl.isNotEmpty) {
      return _normalizeBaseUrl(_configuredBaseUrl);
    }
    if (kIsWeb) {
      return "http://localhost:5000/api";
    }
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return "http://10.0.2.2:5000/api";
      }
    } catch (_) {}
    return "http://localhost:5000/api";
  }

  static String _normalizeBaseUrl(String url) {
    return url.trim().replaceFirst(RegExp(r"/+$"), "");
  }

  static bool _isConnected = false;

  static Future<void> connect() async {
    if (_isConnected) return;
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/health"))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        _isConnected = true;
        debugPrint("✅ Connected to Backend API at $baseUrl");
      }
    } catch (e) {
      debugPrint("⚠️ Backend API health check: $e");
    }
  }

  // ─── Accounts (Pocket & Bank Account) ────────────────────────────────────

  static Future<AccountBalance> getAccounts() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/accounts"));
      if (res.statusCode == 200) {
        return AccountBalance.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint("❌ Error fetching accounts: $e");
    }
    return AccountBalance.initial();
  }

  static Future<void> updateAccounts({
    required double pocket,
    required double bank,
    String notes = "",
  }) async {
    try {
      await http.put(
        Uri.parse("$baseUrl/accounts"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "pocket": pocket,
          "bank": bank,
          "notes": notes,
        }),
      );
    } catch (e) {
      debugPrint("❌ Error updating accounts: $e");
    }
  }

  static Future<void> adjustAccount({
    required String accountType, // "pocket" or "bank"
    required double amount,
    String operation = "add", // "add" or "deduct"
  }) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/accounts/adjust"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "accountType": accountType,
          "amount": amount,
          "operation": operation,
        }),
      );
    } catch (e) {
      debugPrint("❌ Error adjusting account: $e");
    }
  }

  // ─── Debts & Payoff ──────────────────────────────────────────────────────

  static Future<List<DebtItem>> getDebts({String? month}) async {
    try {
      final uri = month != null && month.isNotEmpty
          ? Uri.parse("$baseUrl/debts?month=$month")
          : Uri.parse("$baseUrl/debts");
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((json) => DebtItem.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("❌ Error fetching debts: $e");
    }
    return [];
  }

  static Future<void> insertDebt(DebtItem debt) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/debts"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(debt.toJson()),
      );
    } catch (e) {
      debugPrint("❌ Error inserting debt: $e");
    }
  }

  static Future<void> updateDebt(DebtItem debt) async {
    try {
      await http.put(
        Uri.parse("$baseUrl/debts/${debt.id}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(debt.toJson()),
      );
    } catch (e) {
      debugPrint("❌ Error updating debt: $e");
    }
  }

  static Future<void> payDebt({
    required String id,
    required double paymentAmount,
    String? deductFrom, // "pocket" or "bank"
  }) async {
    try {
      await http.patch(
        Uri.parse("$baseUrl/debts/$id/pay"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "paymentAmount": paymentAmount,
          if (deductFrom != null) "deductFrom": deductFrom,
        }),
      );
    } catch (e) {
      debugPrint("❌ Error paying debt: $e");
    }
  }

  static Future<void> deleteDebt(String id) async {
    try {
      await http.delete(Uri.parse("$baseUrl/debts/$id"));
    } catch (e) {
      debugPrint("❌ Error deleting debt: $e");
    }
  }

  // ─── Custom Dynamic Dropdown Options ─────────────────────────────────────

  static Future<List<String>> getCustomOptions(String type) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/custom-options?type=$type"));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => e["name"].toString()).toList();
      }
    } catch (e) {
      debugPrint("❌ Error fetching options for $type: $e");
    }
    return [];
  }

  static Future<void> addCustomOption(String type, String name) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/custom-options"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"type": type, "name": name}),
      );
    } catch (e) {
      debugPrint("❌ Error adding custom option: $e");
    }
  }

  // ─── Expenses ─────────────────────────────────────────────────────────────

  static Future<List<Expense>> getExpenses({String? month}) async {
    try {
      final uri = month != null && month.isNotEmpty
          ? Uri.parse("$baseUrl/expenses?month=$month")
          : Uri.parse("$baseUrl/expenses");
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((json) => Expense.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("❌ Error fetching expenses: $e");
    }
    return [];
  }

  static Future<void> insertExpense(Expense expense, {bool deductFromAccount = false}) async {
    try {
      final data = expense.toJson();
      if (deductFromAccount) {
        data["deductFromAccount"] = true;
      }
      await http.post(
        Uri.parse("$baseUrl/expenses"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
    } catch (e) {
      debugPrint("❌ Error inserting expense: $e");
    }
  }

  static Future<void> updateExpense(Expense expense) async {
    try {
      await http.put(
        Uri.parse("$baseUrl/expenses/${expense.id}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(expense.toJson()),
      );
    } catch (e) {
      debugPrint("❌ Error updating expense: $e");
    }
  }

  static Future<void> deleteExpense(String id) async {
    try {
      await http.delete(Uri.parse("$baseUrl/expenses/$id"));
    } catch (e) {
      debugPrint("❌ Error deleting expense: $e");
    }
  }

  // ─── Shifts ───────────────────────────────────────────────────────────────

  static Future<List<EarningShift>> getShifts({String? month}) async {
    try {
      final uri = month != null && month.isNotEmpty
          ? Uri.parse("$baseUrl/shifts?month=$month")
          : Uri.parse("$baseUrl/shifts");
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((json) => EarningShift.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("❌ Error fetching shifts: $e");
    }
    return [];
  }

  static Future<void> insertShift(EarningShift shift) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/shifts"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(shift.toJson()),
      );
    } catch (e) {
      debugPrint("❌ Error inserting shift: $e");
    }
  }

  static Future<void> updateShift(EarningShift shift) async {
    try {
      await http.put(
        Uri.parse("$baseUrl/shifts/${shift.id}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(shift.toJson()),
      );
    } catch (e) {
      debugPrint("❌ Error updating shift: $e");
    }
  }

  static Future<void> deleteShift(String id) async {
    try {
      await http.delete(Uri.parse("$baseUrl/shifts/$id"));
    } catch (e) {
      debugPrint("❌ Error deleting shift: $e");
    }
  }

  static Future<void> toggleShiftStatus(String id) async {
    try {
      await http.patch(Uri.parse("$baseUrl/shifts/$id/status"));
    } catch (e) {
      debugPrint("❌ Error toggling shift status: $e");
    }
  }

  // ─── Fixed Bills ──────────────────────────────────────────────────────────

  static Future<List<FixedBill>> getFixedBills({String? month}) async {
    try {
      final uri = month != null && month.isNotEmpty
          ? Uri.parse("$baseUrl/fixed-bills?month=$month")
          : Uri.parse("$baseUrl/fixed-bills");
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((json) => FixedBill.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("❌ Error fetching fixed bills: $e");
    }
    return [];
  }

  static Future<void> insertFixedBill(FixedBill bill) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/fixed-bills"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bill.toJson()),
      );
    } catch (e) {
      debugPrint("❌ Error inserting fixed bill: $e");
    }
  }

  static Future<void> updateFixedBill(FixedBill bill) async {
    try {
      await http.put(
        Uri.parse("$baseUrl/fixed-bills/${bill.id}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bill.toJson()),
      );
    } catch (e) {
      debugPrint("❌ Error updating fixed bill: $e");
    }
  }

  static Future<void> toggleFixedBillStatus(String id) async {
    try {
      await http.patch(Uri.parse("$baseUrl/fixed-bills/$id/toggle"));
    } catch (e) {
      debugPrint("❌ Error toggling fixed bill status: $e");
    }
  }

  static Future<void> deleteFixedBill(String id) async {
    try {
      await http.delete(Uri.parse("$baseUrl/fixed-bills/$id"));
    } catch (e) {
      debugPrint("❌ Error deleting fixed bill: $e");
    }
  }

  // ─── Monthly Budget ──────────────────────────────────────────────────────

  static Future<MonthlyBudget> getBudget({String? month}) async {
    try {
      final uri = month != null && month.isNotEmpty
          ? Uri.parse("$baseUrl/budget?month=$month")
          : Uri.parse("$baseUrl/budget");
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        return MonthlyBudget.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint("❌ Error fetching budget: $e");
    }
    return MonthlyBudget(month: month ?? "", amount: 0.0);
  }

  static Future<void> setBudget(MonthlyBudget budget) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/budget"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(budget.toJson()),
      );
    } catch (e) {
      debugPrint("❌ Error setting budget: $e");
    }
  }

  // ─── Dashboard Summary ───────────────────────────────────────────────────

  static Future<DashboardSummary> getSummary({String? month}) async {
    try {
      final uri = month != null && month.isNotEmpty
          ? Uri.parse("$baseUrl/dashboard/summary?month=$month")
          : Uri.parse("$baseUrl/dashboard/summary");
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(res.body);
        return DashboardSummary.fromJson(json);
      }
    } catch (e) {
      debugPrint("❌ Error fetching dashboard summary: $e");
    }
    return DashboardSummary.initial();
  }
}

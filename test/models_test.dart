import "package:flutter_test/flutter_test.dart";
import "package:expense_shift_tracker/models/models.dart";

void main() {
  group("Model Tests", () {
    test("Expense model parses correctly", () {
      final now = DateTime.now();
      final json = {
        "_id": "6537f0000000000000000001",
        "item": "Test Item",
        "category": "Groceries",
        "price": 12.50,
        "date": now.toIso8601String(),
        "notes": "Test notes",
      };

      final expense = Expense.fromJson(json);
      expect(expense.id, "6537f0000000000000000001");
      expect(expense.item, "Test Item");
      expect(expense.price, 12.50);
      expect(expense.category, "Groceries");
    });

    test("FixedBill model parses correctly", () {
      final json = {
        "_id": "6537f0000000000000000002",
        "name": "Gym",
        "amount": 29.90,
        "month": "October 2026",
        "status": "Paid",
      };

      final bill = FixedBill.fromJson(json);
      expect(bill.id, "6537f0000000000000000002");
      expect(bill.name, "Gym");
      expect(bill.amount, 29.90);
      expect(bill.status, "Paid");
    });

    test("EarningShift model parses correctly", () {
      final now = DateTime.now();
      final json = {
        "_id": "6537f0000000000000000003",
        "date": now.toIso8601String(),
        "category": "Delivery",
        "timeline": "10:00 - 18:00",
        "hours": 8.0,
        "grossAmount": 140.0,
        "rentDeduction": 8.33,
        "taxPercent": 8.0,
        "netAmount": 121.14,
        "paymentStatus": "Pending",
        "payoutBatch": "W-43",
      };

      final shift = EarningShift.fromJson(json);
      expect(shift.id, "6537f0000000000000000003");
      expect(shift.hours, 8.0);
      expect(shift.grossAmount, 140.0);
      expect(shift.netAmount, 121.14);
      expect(shift.paymentStatus, "Pending");
    });

    test("MonthlyBudget model parses correctly", () {
      final json = {
        "_id": "6537f0000000000000000004",
        "month": "2026-10",
        "amount": 1500.0,
        "notes": "Target for Oct",
      };

      final budget = MonthlyBudget.fromJson(json);
      expect(budget.id, "6537f0000000000000000004");
      expect(budget.month, "2026-10");
      expect(budget.amount, 1500.0);
      expect(budget.notes, "Target for Oct");
    });

    test("AccountBalance parses and computes total correctly", () {
      final json = {
        "pocket": 150.0,
        "bank": 2350.0,
      };

      final accounts = AccountBalance.fromJson(json);
      expect(accounts.pocket, 150.0);
      expect(accounts.bank, 2350.0);
      expect(accounts.total, 2500.0);
    });

    test("DebtItem calculates remaining amount and payoff percent correctly", () {
      final json = {
        "_id": "6537f0000000000000000005",
        "title": "Car Loan",
        "personName": "AutoBank",
        "amount": 1000.0,
        "paidAmount": 400.0,
        "category": "Bank Loan",
        "status": "Partial",
      };

      final debt = DebtItem.fromJson(json);
      expect(debt.title, "Car Loan");
      expect(debt.amount, 1000.0);
      expect(debt.paidAmount, 400.0);
      expect(debt.remainingAmount, 600.0);
      expect(debt.paidPercent, 40.0);
      expect(debt.isSettled, false);
    });
  });
}

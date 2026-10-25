class Expense {
  final String id;
  final String item;
  final String category;
  final double price;
  final String paymentMethod; // "Pocket", "Bank Account", etc.
  final DateTime date;
  final String month;
  final String notes;

  Expense({
    required this.id,
    required this.item,
    required this.category,
    required this.price,
    this.paymentMethod = "Pocket",
    required this.date,
    String? month,
    this.notes = "",
  }) : month = month ?? "${date.year}-${date.month.toString().padLeft(2, '0')}";

  factory Expense.fromJson(Map<String, dynamic> json) {
    final parsedDate = json["date"] != null
        ? DateTime.parse(json["date"].toString())
        : DateTime.now();
    return Expense(
      id: json["_id"] ?? json["id"] ?? "",
      item: json["item"] ?? "",
      category: json["category"] ?? "Other",
      price: (json["price"] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json["paymentMethod"] ?? "Pocket",
      date: parsedDate,
      month: json["month"] ??
          "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}",
      notes: json["notes"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        "item": item,
        "category": category,
        "price": price,
        "paymentMethod": paymentMethod,
        "date": date.toIso8601String(),
        "month": month,
        "notes": notes,
      };

  Expense copyWith({
    String? id,
    String? item,
    String? category,
    double? price,
    String? paymentMethod,
    DateTime? date,
    String? month,
    String? notes,
  }) =>
      Expense(
        id: id ?? this.id,
        item: item ?? this.item,
        category: category ?? this.category,
        price: price ?? this.price,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        date: date ?? this.date,
        month: month ?? this.month,
        notes: notes ?? this.notes,
      );
}

class EarningShift {
  final String id;
  final DateTime date;
  final String month;
  final String category;
  final String timeline;
  final double hours;
  final double grossAmount;
  final double rentDeduction;
  final double taxPercent;
  final double netAmount;
  String paymentStatus;
  final String payoutBatch;
  final String depositTo; // "Bank Account" or "Pocket"

  EarningShift({
    required this.id,
    required this.date,
    String? month,
    required this.category,
    required this.timeline,
    required this.hours,
    required this.grossAmount,
    this.rentDeduction = 8.33,
    this.taxPercent = 8.0,
    required this.netAmount,
    this.paymentStatus = "Pending",
    this.payoutBatch = "General",
    this.depositTo = "Bank Account",
  }) : month = month ?? "${date.year}-${date.month.toString().padLeft(2, '0')}";

  factory EarningShift.fromJson(Map<String, dynamic> json) {
    final parsedDate = json["date"] != null
        ? DateTime.parse(json["date"].toString())
        : DateTime.now();
    return EarningShift(
      id: json["_id"] ?? json["id"] ?? "",
      date: parsedDate,
      month: json["month"] ??
          "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}",
      category: json["category"] ?? "Delivery",
      timeline: json["timeline"] ?? "",
      hours: (json["hours"] as num?)?.toDouble() ?? 0.0,
      grossAmount: (json["grossAmount"] as num?)?.toDouble() ?? 0.0,
      rentDeduction: (json["rentDeduction"] as num?)?.toDouble() ?? 8.33,
      taxPercent: (json["taxPercent"] as num?)?.toDouble() ?? 8.0,
      netAmount: (json["netAmount"] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json["paymentStatus"] ?? "Pending",
      payoutBatch: json["payoutBatch"] ?? "General",
      depositTo: json["depositTo"] ?? "Bank Account",
    );
  }

  Map<String, dynamic> toJson() => {
        "date": date.toIso8601String(),
        "month": month,
        "category": category,
        "timeline": timeline,
        "hours": hours,
        "grossAmount": grossAmount,
        "rentDeduction": rentDeduction,
        "taxPercent": taxPercent,
        "netAmount": netAmount,
        "paymentStatus": paymentStatus,
        "payoutBatch": payoutBatch,
        "depositTo": depositTo,
      };

  EarningShift copyWith({
    String? id,
    DateTime? date,
    String? month,
    String? category,
    String? timeline,
    double? hours,
    double? grossAmount,
    double? rentDeduction,
    double? taxPercent,
    double? netAmount,
    String? paymentStatus,
    String? payoutBatch,
    String? depositTo,
  }) =>
      EarningShift(
        id: id ?? this.id,
        date: date ?? this.date,
        month: month ?? this.month,
        category: category ?? this.category,
        timeline: timeline ?? this.timeline,
        hours: hours ?? this.hours,
        grossAmount: grossAmount ?? this.grossAmount,
        rentDeduction: rentDeduction ?? this.rentDeduction,
        taxPercent: taxPercent ?? this.taxPercent,
        netAmount: netAmount ?? this.netAmount,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        payoutBatch: payoutBatch ?? this.payoutBatch,
        depositTo: depositTo ?? this.depositTo,
      );
}

class FixedBill {
  final String id;
  final String name;
  final double amount;
  final String category;
  final String month;
  final String status;

  FixedBill({
    required this.id,
    required this.name,
    required this.amount,
    this.category = "Utilities",
    required this.month,
    this.status = "Pending",
  });

  factory FixedBill.fromJson(Map<String, dynamic> json) => FixedBill(
        id: json["_id"] ?? json["id"] ?? "",
        name: json["name"] ?? "",
        amount: (json["amount"] as num?)?.toDouble() ?? 0.0,
        category: json["category"] ?? "Utilities",
        month: json["month"] ?? "",
        status: json["status"] ?? "Pending",
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "amount": amount,
        "category": category,
        "month": month,
        "status": status,
      };

  FixedBill copyWith({
    String? id,
    String? name,
    double? amount,
    String? category,
    String? month,
    String? status,
  }) =>
      FixedBill(
        id: id ?? this.id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        month: month ?? this.month,
        status: status ?? this.status,
      );
}

class MonthlyBudget {
  final String id;
  final String month;
  final double amount;
  final String notes;

  MonthlyBudget({
    this.id = "",
    required this.month,
    required this.amount,
    this.notes = "",
  });

  factory MonthlyBudget.fromJson(Map<String, dynamic> json) => MonthlyBudget(
        id: json["_id"] ?? json["id"] ?? "",
        month: json["month"] ?? "",
        amount: (json["amount"] as num?)?.toDouble() ?? 0.0,
        notes: json["notes"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "month": month,
        "amount": amount,
        "notes": notes,
      };
}

class AccountBalance {
  final double pocket;
  final double bank;
  final double total;
  final String notes;

  AccountBalance({
    this.pocket = 0.0,
    this.bank = 0.0,
    this.total = 0.0,
    this.notes = "",
  });

  factory AccountBalance.initial() => AccountBalance(
        pocket: 0.0,
        bank: 0.0,
        total: 0.0,
        notes: "",
      );

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    final p = (json["pocket"] as num?)?.toDouble() ?? 0.0;
    final b = (json["bank"] as num?)?.toDouble() ?? 0.0;
    return AccountBalance(
      pocket: p,
      bank: b,
      total: (json["total"] as num?)?.toDouble() ?? (p + b),
      notes: json["notes"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        "pocket": pocket,
        "bank": bank,
        "notes": notes,
      };

  AccountBalance copyWith({
    double? pocket,
    double? bank,
    double? total,
    String? notes,
  }) =>
      AccountBalance(
        pocket: pocket ?? this.pocket,
        bank: bank ?? this.bank,
        total: total ?? this.total,
        notes: notes ?? this.notes,
      );
}

class DebtItem {
  final String id;
  final String title;
  final String personName;
  final double amount;
  final double paidAmount;
  final DateTime? dueDate;
  final String category;
  final String status; // "Pending", "Partial", "Settled"
  final String notes;
  final String month;

  DebtItem({
    required this.id,
    required this.title,
    this.personName = "",
    required this.amount,
    this.paidAmount = 0.0,
    this.dueDate,
    this.category = "Personal",
    this.status = "Pending",
    this.notes = "",
    this.month = "",
  });

  double get remainingAmount =>
      (amount - paidAmount).clamp(0.0, double.infinity);
  double get paidPercent =>
      amount > 0 ? ((paidAmount / amount) * 100).clamp(0.0, 100.0) : 100.0;
  bool get isSettled => status == "Settled" || remainingAmount <= 0.01;

  factory DebtItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDue;
    if (json["dueDate"] != null) {
      try {
        parsedDue = DateTime.parse(json["dueDate"].toString());
      } catch (_) {}
    }
    return DebtItem(
      id: json["_id"] ?? json["id"] ?? "",
      title: json["title"] ?? json["personName"] ?? "Debt",
      personName: json["personName"] ?? "",
      amount: (json["amount"] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json["paidAmount"] as num?)?.toDouble() ??
          (json["returned"] as num?)?.toDouble() ??
          0.0,
      dueDate: parsedDue,
      category: json["category"] ?? "Personal",
      status: json["status"] ?? "Pending",
      notes: json["notes"] ?? "",
      month: json["month"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        "title": title,
        "personName": personName,
        "amount": amount,
        "paidAmount": paidAmount,
        "dueDate": dueDate?.toIso8601String(),
        "category": category,
        "status": status,
        "notes": notes,
        "month": month,
      };

  DebtItem copyWith({
    String? id,
    String? title,
    String? personName,
    double? amount,
    double? paidAmount,
    DateTime? dueDate,
    String? category,
    String? status,
    String? notes,
    String? month,
  }) =>
      DebtItem(
        id: id ?? this.id,
        title: title ?? this.title,
        personName: personName ?? this.personName,
        amount: amount ?? this.amount,
        paidAmount: paidAmount ?? this.paidAmount,
        dueDate: dueDate ?? this.dueDate,
        category: category ?? this.category,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        month: month ?? this.month,
      );
}

class CustomOption {
  final String id;
  final String type;
  final String name;

  CustomOption({required this.id, required this.type, required this.name});

  factory CustomOption.fromJson(Map<String, dynamic> json) => CustomOption(
        id: json["_id"] ?? "",
        type: json["type"] ?? "",
        name: json["name"] ?? "",
      );

  Map<String, dynamic> toJson() => {"type": type, "name": name};
}

class DashboardSummary {
  final String month;
  final double totalExpenses;
  final double grossEarnings;
  final double netEarnings;
  final double pendingEarnings;
  final double receivedEarnings;
  final double netBalance;
  final double totalFixedBills;
  final double monthlyBudget;
  final double remainingBudget;
  final double budgetUsedPercent;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> dailySpending;
  final int totalTransactions;
  // Pocket and Bank Balances
  final double pocketBalance;
  final double bankBalance;
  final double totalLiquidFunds;
  // Debts
  final double totalDebt;
  final double paidDebt;
  final double remainingDebt;
  final double debtPayoffPercent;

  DashboardSummary({
    this.month = "",
    required this.totalExpenses,
    required this.grossEarnings,
    required this.netEarnings,
    required this.pendingEarnings,
    required this.receivedEarnings,
    required this.netBalance,
    required this.totalFixedBills,
    this.monthlyBudget = 0.0,
    this.remainingBudget = 0.0,
    this.budgetUsedPercent = 0.0,
    required this.categoryBreakdown,
    this.dailySpending = const {},
    this.totalTransactions = 0,
    this.pocketBalance = 0.0,
    this.bankBalance = 0.0,
    this.totalLiquidFunds = 0.0,
    this.totalDebt = 0.0,
    this.paidDebt = 0.0,
    this.remainingDebt = 0.0,
    this.debtPayoffPercent = 100.0,
  });

  factory DashboardSummary.initial() => DashboardSummary(
        month: "",
        totalExpenses: 0.0,
        grossEarnings: 0.0,
        netEarnings: 0.0,
        pendingEarnings: 0.0,
        receivedEarnings: 0.0,
        netBalance: 0.0,
        totalFixedBills: 0.0,
        monthlyBudget: 0.0,
        remainingBudget: 0.0,
        budgetUsedPercent: 0.0,
        categoryBreakdown: {},
        dailySpending: {},
        totalTransactions: 0,
        pocketBalance: 0.0,
        bankBalance: 0.0,
        totalLiquidFunds: 0.0,
        totalDebt: 0.0,
        paidDebt: 0.0,
        remainingDebt: 0.0,
        debtPayoffPercent: 100.0,
      );

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final catRaw = json["categoryBreakdown"] as Map<String, dynamic>? ?? {};
    final catBreakdown =
        catRaw.map((k, v) => MapEntry(k, (v as num).toDouble()));

    final dailyRaw = json["dailySpending"] as Map<String, dynamic>? ?? {};
    final daily = dailyRaw.map((k, v) => MapEntry(k, (v as num).toDouble()));

    return DashboardSummary(
      month: json["month"] ?? "",
      totalExpenses: (json["totalExpenses"] as num?)?.toDouble() ?? 0.0,
      grossEarnings: (json["grossEarnings"] as num?)?.toDouble() ?? 0.0,
      netEarnings: (json["netEarnings"] as num?)?.toDouble() ?? 0.0,
      pendingEarnings: (json["pendingEarnings"] as num?)?.toDouble() ?? 0.0,
      receivedEarnings: (json["receivedEarnings"] as num?)?.toDouble() ?? 0.0,
      netBalance: (json["netBalance"] as num?)?.toDouble() ?? 0.0,
      totalFixedBills: (json["totalFixedBills"] as num?)?.toDouble() ?? 0.0,
      monthlyBudget: (json["monthlyBudget"] as num?)?.toDouble() ?? 0.0,
      remainingBudget: (json["remainingBudget"] as num?)?.toDouble() ?? 0.0,
      budgetUsedPercent: (json["budgetUsedPercent"] as num?)?.toDouble() ?? 0.0,
      categoryBreakdown: catBreakdown,
      dailySpending: daily,
      totalTransactions: (json["totalTransactions"] as num?)?.toInt() ?? 0,
      pocketBalance: (json["pocketBalance"] as num?)?.toDouble() ?? 0.0,
      bankBalance: (json["bankBalance"] as num?)?.toDouble() ?? 0.0,
      totalLiquidFunds: (json["totalLiquidFunds"] as num?)?.toDouble() ?? 0.0,
      totalDebt: (json["totalDebt"] as num?)?.toDouble() ?? 0.0,
      paidDebt: (json["paidDebt"] as num?)?.toDouble() ?? 0.0,
      remainingDebt: (json["remainingDebt"] as num?)?.toDouble() ?? 0.0,
      debtPayoffPercent:
          (json["debtPayoffPercent"] as num?)?.toDouble() ?? 100.0,
    );
  }
}

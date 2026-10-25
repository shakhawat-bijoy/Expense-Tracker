const mongoose = require("mongoose");

function getMonthString(date) {
  const d = date ? new Date(date) : new Date();
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, "0");
  return `${year}-${month}`;
}

// ─── Expense ─────────────────────────────────────────────────────────────
const ExpenseSchema = new mongoose.Schema({
  item: { type: String, required: true },
  category: { 
    type: String, 
    required: true,
    default: "Other"
  },
  price: { type: Number, required: true },
  paymentMethod: { type: String, default: "Pocket" }, // "Pocket", "Bank Account", or custom
  date: { type: Date, required: true, default: Date.now },
  month: { 
    type: String, 
    default: function() {
      return getMonthString(this.date);
    } 
  },
  notes: { type: String, default: "" }
}, { timestamps: true });

ExpenseSchema.pre("save", function(next) {
  if (!this.month && this.date) {
    this.month = getMonthString(this.date);
  }
  next();
});

// ─── Earning Shift ───────────────────────────────────────────────────────
const EarningShiftSchema = new mongoose.Schema({
  date: { type: Date, required: true },
  month: { 
    type: String, 
    default: function() {
      return getMonthString(this.date);
    } 
  },
  category: { type: String, required: true, default: "Delivery" },
  timeline: { type: String, required: true },
  hours: { type: Number, required: true },
  grossAmount: { type: Number, required: true },
  rentDeduction: { type: Number, default: 8.33 },
  taxPercent: { type: Number, default: 8.0 },
  netAmount: { type: Number, required: true },
  paymentStatus: { type: String, enum: ["Pending", "Received"], default: "Pending" },
  payoutBatch: { type: String, default: "General" },
  depositTo: { type: String, default: "Bank Account" } // "Bank Account" or "Pocket"
}, { timestamps: true });

EarningShiftSchema.pre("save", function(next) {
  if (!this.month && this.date) {
    this.month = getMonthString(this.date);
  }
  next();
});

// ─── Fixed Bill ──────────────────────────────────────────────────────────
const FixedBillSchema = new mongoose.Schema({
  name: { type: String, required: true },
  amount: { type: Number, required: true },
  category: { type: String, default: "Utilities" },
  month: { type: String, required: true },
  status: { type: String, enum: ["Pending", "Paid"], default: "Pending" }
}, { timestamps: true });

// ─── Monthly Budget ──────────────────────────────────────────────────────
const BudgetSchema = new mongoose.Schema({
  month: { type: String, required: true, unique: true }, // e.g. "2026-10"
  amount: { type: Number, required: true, default: 0 },
  notes: { type: String, default: "" }
}, { timestamps: true });

// ─── Debts to Pay Off ────────────────────────────────────────────────────
const DebtSchema = new mongoose.Schema({
  title: { type: String, required: true }, // e.g. "Car Loan", "Credit Card", "Loan from John"
  personName: { type: String, default: "" }, // Creditor / Lender / Person
  amount: { type: Number, required: true }, // Total amount owed
  paidAmount: { type: Number, default: 0 }, // Amount paid off so far
  dueDate: { type: Date },
  category: { type: String, default: "Personal" }, // "Personal", "Bank Loan", "Credit Card", "Family", etc.
  status: { type: String, enum: ["Pending", "Partial", "Settled"], default: "Pending" },
  notes: { type: String, default: "" },
  month: { type: String }
}, { timestamps: true });

DebtSchema.pre("save", function(next) {
  if (this.paidAmount >= this.amount && this.amount > 0) {
    this.status = "Settled";
  } else if (this.paidAmount > 0) {
    this.status = "Partial";
  } else {
    this.status = "Pending";
  }
  next();
});

// ─── Account Balances (Pocket / Cash and Bank Account) ───────────────────
const AccountBalanceSchema = new mongoose.Schema({
  pocket: { type: Number, default: 0 },
  bank: { type: Number, default: 0 },
  notes: { type: String, default: "" }
}, { timestamps: true });

// ─── Custom Dynamic Dropdown Options ─────────────────────────────────────
const CustomOptionSchema = new mongoose.Schema({
  type: { type: String, required: true }, // 'expense_category', 'shift_role', 'payment_method', 'bill_category', 'debt_category'
  name: { type: String, required: true }
}, { timestamps: true });

module.exports = {
  Expense: mongoose.model("Expense", ExpenseSchema, "expenses"),
  EarningShift: mongoose.model("EarningShift", EarningShiftSchema, "shifts"),
  FixedBill: mongoose.model("FixedBill", FixedBillSchema, "fixedbills"),
  Budget: mongoose.model("Budget", BudgetSchema, "budgets"),
  Debt: mongoose.model("Debt", DebtSchema, "debts"),
  AccountBalance: mongoose.model("AccountBalance", AccountBalanceSchema, "accountbalances"),
  CustomOption: mongoose.model("CustomOption", CustomOptionSchema, "customoptions"),
  getMonthString
};

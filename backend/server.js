const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
require("dotenv").config();

const { 
  Expense, 
  EarningShift, 
  FixedBill, 
  Budget, 
  Debt, 
  AccountBalance, 
  CustomOption, 
  getMonthString 
} = require("./models/Schemas");

const app = express();
const allowedOrigins = (process.env.CORS_ORIGINS || "")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);
app.set("trust proxy", 1);
app.use(cors({
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.length === 0 || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error("Origin not allowed by CORS"));
  },
}));
app.use(express.json({ limit: "1mb" }));

// Helper to build month query filter
function buildMonthFilter(monthQuery, dateField = "date") {
  if (!monthQuery || monthQuery === "all") return {};
  const parts = monthQuery.split("-");
  if (parts.length === 2) {
    const year = parseInt(parts[0], 10);
    const month = parseInt(parts[1], 10);
    const start = new Date(year, month - 1, 1);
    const end = new Date(year, month, 1);
    return {
      $or: [
        { month: monthQuery },
        { [dateField]: { $gte: start, $lt: end } }
      ]
    };
  }
  return { month: monthQuery };
}

// Health Check
app.get("/api/health", (req, res) => {
  const databaseConnected = mongoose.connection.readyState === 1;
  res.status(databaseConnected ? 200 : 503).json({
    status: databaseConnected ? "ok" : "degraded",
    database: databaseConnected ? "connected" : "disconnected",
    timestamp: new Date().toISOString()
  });
});

// ─── Account Balances (Pocket / Cash and Bank Account) ───────────────────
app.get("/api/accounts", async (req, res) => {
  try {
    let acc = await AccountBalance.findOne();
    if (!acc) {
      acc = await AccountBalance.create({ pocket: 0, bank: 0 });
    }
    res.json({
      pocket: acc.pocket || 0,
      bank: acc.bank || 0,
      total: Number(((acc.pocket || 0) + (acc.bank || 0)).toFixed(2)),
      notes: acc.notes || ""
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put("/api/accounts", async (req, res) => {
  try {
    const { pocket = 0, bank = 0, notes = "" } = req.body;
    let acc = await AccountBalance.findOne();
    if (!acc) {
      acc = new AccountBalance({ pocket, bank, notes });
    } else {
      acc.pocket = Number(pocket);
      acc.bank = Number(bank);
      if (notes) acc.notes = notes;
    }
    await acc.save();
    res.json({
      pocket: acc.pocket,
      bank: acc.bank,
      total: Number((acc.pocket + acc.bank).toFixed(2)),
      notes: acc.notes
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.post("/api/accounts/adjust", async (req, res) => {
  try {
    const { accountType, amount, operation = "add" } = req.body; // accountType: "pocket" | "bank"
    let acc = await AccountBalance.findOne();
    if (!acc) {
      acc = await AccountBalance.create({ pocket: 0, bank: 0 });
    }
    const delta = operation === "deduct" ? -Math.abs(amount) : Math.abs(amount);
    if (accountType === "pocket") {
      acc.pocket = Math.max(0, Number((acc.pocket + delta).toFixed(2)));
    } else if (accountType === "bank") {
      acc.bank = Math.max(0, Number((acc.bank + delta).toFixed(2)));
    }
    await acc.save();
    res.json({
      pocket: acc.pocket,
      bank: acc.bank,
      total: Number((acc.pocket + acc.bank).toFixed(2))
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ─── Debts to Pay Off ────────────────────────────────────────────────────
app.get("/api/debts", async (req, res) => {
  try {
    let filter = {};
    if (req.query.month && req.query.month !== "all") {
      filter = {
        $or: [
          { month: req.query.month },
          { month: "" },
          { month: null }
        ]
      };
    }
    const debts = await Debt.find(filter).sort({ createdAt: -1 });
    res.json(debts);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/debts", async (req, res) => {
  try {
    const debt = new Debt(req.body);
    await debt.save();
    res.status(201).json(debt);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.put("/api/debts/:id", async (req, res) => {
  try {
    const debt = await Debt.findById(req.params.id);
    if (!debt) return res.status(404).json({ error: "Debt not found" });

    Object.assign(debt, req.body);
    await debt.save();
    res.json(debt);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.patch("/api/debts/:id/pay", async (req, res) => {
  try {
    const { paymentAmount = 0, deductFrom } = req.body;
    const debt = await Debt.findById(req.params.id);
    if (!debt) return res.status(404).json({ error: "Debt not found" });

    debt.paidAmount = Number(((debt.paidAmount || 0) + Number(paymentAmount)).toFixed(2));
    await debt.save();

    // Optionally deduct from Pocket or Bank
    if (deductFrom === "pocket" || deductFrom === "bank") {
      let acc = await AccountBalance.findOne();
      if (acc) {
        if (deductFrom === "pocket") {
          acc.pocket = Math.max(0, Number((acc.pocket - paymentAmount).toFixed(2)));
        } else {
          acc.bank = Math.max(0, Number((acc.bank - paymentAmount).toFixed(2)));
        }
        await acc.save();
      }
    }

    res.json(debt);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete("/api/debts/:id", async (req, res) => {
  try {
    await Debt.findByIdAndDelete(req.params.id);
    res.json({ message: "Debt deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Custom Dynamic Dropdown Options ─────────────────────────────────────
app.get("/api/custom-options", async (req, res) => {
  try {
    const filter = req.query.type ? { type: req.query.type } : {};
    const options = await CustomOption.find(filter).sort({ name: 1 });
    res.json(options);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/custom-options", async (req, res) => {
  try {
    const { type, name } = req.body;
    if (!type || !name) return res.status(400).json({ error: "Type and name required" });

    let opt = await CustomOption.findOne({ type, name: { $regex: new RegExp(`^${name.trim()}$`, "i") } });
    if (!opt) {
      opt = await CustomOption.create({ type, name: name.trim() });
    }
    res.status(201).json(opt);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete("/api/custom-options/:id", async (req, res) => {
  try {
    await CustomOption.findByIdAndDelete(req.params.id);
    res.json({ message: "Option deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Expenses ─────────────────────────────────────────────────────────────
app.get("/api/expenses", async (req, res) => {
  try {
    const filter = req.query.month ? buildMonthFilter(req.query.month, "date") : {};
    const expenses = await Expense.find(filter).sort({ date: -1 });
    res.json(expenses);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/expenses", async (req, res) => {
  try {
    const date = req.body.date ? new Date(req.body.date) : new Date();
    const month = req.body.month || getMonthString(date);
    const expense = new Expense({
      ...req.body,
      date,
      month
    });
    await expense.save();

    // Optionally deduct from Pocket or Bank
    if (req.body.deductFromAccount) {
      let acc = await AccountBalance.findOne();
      if (!acc) acc = await AccountBalance.create({ pocket: 0, bank: 0 });
      if (req.body.paymentMethod === "Bank Account" || req.body.deductFromAccount === "bank") {
        acc.bank = Math.max(0, Number((acc.bank - expense.price).toFixed(2)));
      } else {
        acc.pocket = Math.max(0, Number((acc.pocket - expense.price).toFixed(2)));
      }
      await acc.save();
    }

    res.status(201).json(expense);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.put("/api/expenses/:id", async (req, res) => {
  try {
    const date = req.body.date ? new Date(req.body.date) : undefined;
    const month = req.body.month || (date ? getMonthString(date) : undefined);
    
    const updateData = { ...req.body };
    if (date) updateData.date = date;
    if (month) updateData.month = month;

    const updated = await Expense.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );
    if (!updated) return res.status(404).json({ error: "Expense not found" });
    res.json(updated);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete("/api/expenses/:id", async (req, res) => {
  try {
    await Expense.findByIdAndDelete(req.params.id);
    res.json({ message: "Expense deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Shifts & Earnings ───────────────────────────────────────────────────
app.get("/api/shifts", async (req, res) => {
  try {
    const filter = req.query.month ? buildMonthFilter(req.query.month, "date") : {};
    const shifts = await EarningShift.find(filter).sort({ date: -1 });
    res.json(shifts);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/shifts", async (req, res) => {
  try {
    const date = req.body.date ? new Date(req.body.date) : new Date();
    const month = req.body.month || getMonthString(date);
    const { grossAmount = 0, rentDeduction = 8.33, taxPercent = 8.0 } = req.body;
    const base = Math.max(0, grossAmount - rentDeduction);
    const net = base * (1 - taxPercent / 100);

    const shift = new EarningShift({
      ...req.body,
      date,
      month,
      grossAmount,
      rentDeduction,
      taxPercent,
      netAmount: Number(net.toFixed(2))
    });
    await shift.save();
    res.status(201).json(shift);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.put("/api/shifts/:id", async (req, res) => {
  try {
    const date = req.body.date ? new Date(req.body.date) : undefined;
    const month = req.body.month || (date ? getMonthString(date) : undefined);
    const grossAmount = req.body.grossAmount !== undefined ? req.body.grossAmount : undefined;
    const rentDeduction = req.body.rentDeduction !== undefined ? req.body.rentDeduction : 8.33;
    const taxPercent = req.body.taxPercent !== undefined ? req.body.taxPercent : 8.0;

    let netAmount = req.body.netAmount;
    if (grossAmount !== undefined && netAmount === undefined) {
      const base = Math.max(0, grossAmount - rentDeduction);
      netAmount = Number((base * (1 - taxPercent / 100)).toFixed(2));
    }

    const updateData = { ...req.body };
    if (date) updateData.date = date;
    if (month) updateData.month = month;
    if (netAmount !== undefined) updateData.netAmount = netAmount;

    const updated = await EarningShift.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );
    if (!updated) return res.status(404).json({ error: "Shift not found" });
    res.json(updated);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.patch("/api/shifts/:id/status", async (req, res) => {
  try {
    const shift = await EarningShift.findById(req.params.id);
    if (!shift) return res.status(404).json({ error: "Shift not found" });
    shift.paymentStatus = shift.paymentStatus === "Pending" ? "Received" : "Pending";
    await shift.save();

    // If marked received, optionally deposit to Account
    if (shift.paymentStatus === "Received") {
      let acc = await AccountBalance.findOne();
      if (!acc) acc = await AccountBalance.create({ pocket: 0, bank: 0 });
      if (shift.depositTo === "Pocket") {
        acc.pocket = Number((acc.pocket + shift.netAmount).toFixed(2));
      } else {
        acc.bank = Number((acc.bank + shift.netAmount).toFixed(2));
      }
      await acc.save();
    }

    res.json(shift);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete("/api/shifts/:id", async (req, res) => {
  try {
    await EarningShift.findByIdAndDelete(req.params.id);
    res.json({ message: "Shift deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Fixed Bills ─────────────────────────────────────────────────────────
app.get("/api/fixed-bills", async (req, res) => {
  try {
    let filter = {};
    if (req.query.month && req.query.month !== "all") {
      filter = {
        $or: [
          { month: req.query.month },
          { month: "" },
          { month: null }
        ]
      };
    }
    const bills = await FixedBill.find(filter);
    res.json(bills);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/fixed-bills", async (req, res) => {
  try {
    const bill = new FixedBill(req.body);
    await bill.save();
    res.status(201).json(bill);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.put("/api/fixed-bills/:id", async (req, res) => {
  try {
    const updated = await FixedBill.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    if (!updated) return res.status(404).json({ error: "Fixed bill not found" });
    res.json(updated);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.patch("/api/fixed-bills/:id/toggle", async (req, res) => {
  try {
    const bill = await FixedBill.findById(req.params.id);
    if (!bill) return res.status(404).json({ error: "Bill not found" });
    bill.status = bill.status === "Paid" ? "Pending" : "Paid";
    await bill.save();
    res.json(bill);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete("/api/fixed-bills/:id", async (req, res) => {
  try {
    await FixedBill.findByIdAndDelete(req.params.id);
    res.json({ message: "Fixed bill deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Monthly Budget ──────────────────────────────────────────────────────
app.get("/api/budget", async (req, res) => {
  try {
    const month = req.query.month || getMonthString(new Date());
    let budget = await Budget.findOne({ month });
    if (!budget) {
      budget = { month, amount: 0, notes: "" };
    }
    res.json(budget);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/budget", async (req, res) => {
  try {
    const { month, amount = 0, notes = "" } = req.body;
    if (!month) return res.status(400).json({ error: "Month is required (YYYY-MM)" });
    
    const budget = await Budget.findOneAndUpdate(
      { month },
      { amount: Number(amount), notes },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
    res.json(budget);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ─── Dashboard Analytics Summary (Month-by-Month) ────────────────────────
app.get("/api/dashboard/summary", async (req, res) => {
  try {
    const selectedMonth = req.query.month || getMonthString(new Date());
    const filter = buildMonthFilter(selectedMonth, "date");

    const expenses = await Expense.find(filter);
    const shifts = await EarningShift.find(filter);
    
    // Bills for that month
    const fixedBills = await FixedBill.find({
      $or: [
        { month: selectedMonth },
        { month: "" },
        { month: null }
      ]
    });

    // Budget for that month
    const budgetDoc = await Budget.findOne({ month: selectedMonth });
    const monthlyBudget = budgetDoc ? budgetDoc.amount : 0.0;

    // Accounts
    let accountDoc = await AccountBalance.findOne();
    if (!accountDoc) accountDoc = await AccountBalance.create({ pocket: 0, bank: 0 });

    // Debts
    const debts = await Debt.find();
    const totalDebt = debts.reduce((acc, curr) => acc + (curr.amount || 0), 0);
    const paidDebt = debts.reduce((acc, curr) => acc + (curr.paidAmount || 0), 0);
    const remainingDebt = Math.max(0, totalDebt - paidDebt);
    const debtPayoffPercent = totalDebt > 0 ? Number(((paidDebt / totalDebt) * 100).toFixed(1)) : 100.0;

    const totalExpenses = expenses.reduce((acc, curr) => acc + (curr.price || 0), 0);
    const grossEarnings = shifts.reduce((acc, curr) => acc + (curr.grossAmount || 0), 0);
    const netEarnings = shifts.reduce((acc, curr) => acc + (curr.netAmount || 0), 0);
    const pendingEarnings = shifts
      .filter(s => s.paymentStatus === "Pending")
      .reduce((acc, curr) => acc + (curr.netAmount || 0), 0);
    const receivedEarnings = shifts
      .filter(s => s.paymentStatus === "Received")
      .reduce((acc, curr) => acc + (curr.netAmount || 0), 0);
    const paidFixedBills = fixedBills
      .filter(b => b.status === "Paid")
      .reduce((acc, curr) => acc + (curr.amount || 0), 0);
    const totalFixedBills = fixedBills.reduce((acc, curr) => acc + (curr.amount || 0), 0);

    const categoryBreakdown = {};
    expenses.forEach(e => {
      const cat = e.category || "Other";
      categoryBreakdown[cat] = (categoryBreakdown[cat] || 0) + (e.price || 0);
    });

    // Daily spending for the selected month
    const dailySpending = {};
    const parts = selectedMonth.split("-");
    if (parts.length === 2) {
      const year = parseInt(parts[0], 10);
      const month = parseInt(parts[1], 10);
      const daysInMonth = new Date(year, month, 0).getDate();
      
      for (let day = 1; day <= daysInMonth; day++) {
        const d = new Date(year, month - 1, day);
        const dayKey = `${String(day).padStart(2, "0")}/${String(month).padStart(2, "0")}`;
        const dayTotal = expenses
          .filter(e => {
            const ed = new Date(e.date);
            return (
              ed.getFullYear() === d.getFullYear() &&
              ed.getMonth() === d.getMonth() &&
              ed.getDate() === d.getDate()
            );
          })
          .reduce((acc, curr) => acc + (curr.price || 0), 0);
        
        if (dayTotal > 0 || daysInMonth <= 10) {
          dailySpending[dayKey] = Number(dayTotal.toFixed(2));
        }
      }
    }

    const remainingBudget = monthlyBudget > 0 ? Number((monthlyBudget - totalExpenses).toFixed(2)) : 0;
    const budgetUsedPercent = monthlyBudget > 0 ? Number(((totalExpenses / monthlyBudget) * 100).toFixed(1)) : 0;

    res.json({
      month: selectedMonth,
      totalExpenses: Number(totalExpenses.toFixed(2)),
      grossEarnings: Number(grossEarnings.toFixed(2)),
      netEarnings: Number(netEarnings.toFixed(2)),
      pendingEarnings: Number(pendingEarnings.toFixed(2)),
      receivedEarnings: Number(receivedEarnings.toFixed(2)),
      netBalance: Number((netEarnings - totalExpenses - paidFixedBills).toFixed(2)),
      totalFixedBills: Number(totalFixedBills.toFixed(2)),
      monthlyBudget: Number(monthlyBudget.toFixed(2)),
      remainingBudget,
      budgetUsedPercent,
      categoryBreakdown,
      dailySpending,
      totalTransactions: expenses.length + shifts.length,
      // Accounts balances
      pocketBalance: Number((accountDoc.pocket || 0).toFixed(2)),
      bankBalance: Number((accountDoc.bank || 0).toFixed(2)),
      totalLiquidFunds: Number(((accountDoc.pocket || 0) + (accountDoc.bank || 0)).toFixed(2)),
      // Debts info
      totalDebt: Number(totalDebt.toFixed(2)),
      paidDebt: Number(paidDebt.toFixed(2)),
      remainingDebt: Number(remainingDebt.toFixed(2)),
      debtPayoffPercent
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || "0.0.0.0";
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log("✅ Connected to MongoDB Atlas");
    const server = app.listen(PORT, HOST, () =>
      console.log(`🚀 Server listening on ${HOST}:${PORT}`)
    );
    const shutdown = async (signal) => {
      console.log(`\n${signal} received, shutting down...`);
      await new Promise((resolve) => server.close(resolve));
      await mongoose.disconnect();
      process.exit(0);
    };
    process.once("SIGTERM", () => shutdown("SIGTERM"));
    process.once("SIGINT", () => shutdown("SIGINT"));
  })
  .catch(err => console.error("❌ MongoDB Atlas Connection Error:", err));

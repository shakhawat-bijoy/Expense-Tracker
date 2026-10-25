import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import "../providers/app_provider.dart";

import "../widgets/month_navigation_bar.dart";

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final summary = provider.summary;
    final currency = NumberFormat.currency(locale: "de_DE", symbol: "€");
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final categories = summary.categoryBreakdown;
    final hasData = categories.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      children: [
        // ─── Month Navigation Bar ─────────────────────────────────────
        const MonthNavigationBar(),
        const SizedBox(height: 8),

        // ─── Overview Cards ─────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatOverviewCard(
                title: "Transactions",
                value: "${summary.totalTransactions}",
                subtitle:
                    "${provider.expenses.length} expenses · ${provider.shifts.length} shifts",
                icon: Icons.swap_horiz_rounded,
                color: const Color(0xFF6366F1),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatOverviewCard(
                title: "Avg / Day",
                value: _avgPerDay(provider),
                subtitle: "Based on this month",
                icon: Icons.trending_flat_rounded,
                color: const Color(0xFFEC4899),
                isDark: isDark,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _StatOverviewCard(
                title: "Highest Expense",
                value: provider.expenses.isNotEmpty
                    ? currency.format(provider.expenses
                        .map((e) => e.price)
                        .reduce((a, b) => a > b ? a : b))
                    : "€0.00",
                subtitle: provider.expenses.isNotEmpty
                    ? provider.expenses
                        .reduce((a, b) => a.price > b.price ? a : b)
                        .item
                    : "No data",
                icon: Icons.arrow_upward_rounded,
                color: const Color(0xFFEF4444),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatOverviewCard(
                title: "Top Category",
                value: _topCategory(categories),
                subtitle: _topCategory(categories) != "N/A"
                    ? currency.format(categories[_topCategory(categories)] ?? 0)
                    : "No data",
                icon: Icons.category_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 24),

        // ─── Pie Chart ──────────────────────────────────────────────
        Text("Expense Distribution",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A4A) : Colors.grey.shade200,
            ),
          ),
          child: hasData
              ? Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 50,
                          sections: _buildPieSections(
                              categories, summary.totalExpenses),
                          pieTouchData: PieTouchData(enabled: true),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Legend
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: categories.entries.map((entry) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(entry.key),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${entry.key} (${(entry.value / summary.totalExpenses * 100).toStringAsFixed(0)}%)",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                )
              : SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pie_chart_outline_rounded,
                            size: 56,
                            color:
                                isDark ? Colors.white24 : Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text("No expense data to visualize",
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 24),

        // ─── Earnings vs Expenses ───────────────────────────────────
        Text("Income vs Expenses",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A4A) : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              _ComparisonBar(
                label: "Net Earnings",
                value: summary.netEarnings,
                maxValue: (summary.netEarnings > summary.totalExpenses
                        ? summary.netEarnings
                        : summary.totalExpenses)
                    .clamp(1, double.infinity),
                color: const Color(0xFF10B981),
                formattedValue: currency.format(summary.netEarnings),
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              _ComparisonBar(
                label: "Total Expenses",
                value: summary.totalExpenses,
                maxValue: (summary.netEarnings > summary.totalExpenses
                        ? summary.netEarnings
                        : summary.totalExpenses)
                    .clamp(1, double.infinity),
                color: const Color(0xFFEF4444),
                formattedValue: currency.format(summary.totalExpenses),
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              _ComparisonBar(
                label: "Fixed Bills",
                value: summary.totalFixedBills,
                maxValue: (summary.netEarnings > summary.totalExpenses
                        ? summary.netEarnings
                        : summary.totalExpenses)
                    .clamp(1, double.infinity),
                color: const Color(0xFFF59E0B),
                formattedValue: currency.format(summary.totalFixedBills),
                isDark: isDark,
              ),
              const Divider(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Net Balance",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      )),
                  Text(
                    currency.format(summary.netBalance),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: summary.netBalance >= 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 24),

        // ─── Category Details Table ─────────────────────────────────
        if (hasData) ...[
          Text("Category Details",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2A2A4A) : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text("Category",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: cs.primary))),
                      Expanded(
                          flex: 2,
                          child: Text("Amount",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: cs.primary),
                              textAlign: TextAlign.right)),
                      Expanded(
                          flex: 1,
                          child: Text("%",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: cs.primary),
                              textAlign: TextAlign.right)),
                      Expanded(
                          flex: 1,
                          child: Text("Count",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: cs.primary),
                              textAlign: TextAlign.right)),
                    ],
                  ),
                ),
                // Rows
                ...categories.entries.map((entry) {
                  final count = provider.expenses
                      .where((e) => e.category == entry.key)
                      .length;
                  final pct = summary.totalExpenses > 0
                      ? (entry.value / summary.totalExpenses * 100)
                      : 0.0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? const Color(0xFF2A2A4A)
                              : Colors.grey.shade100,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(entry.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(entry.key,
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        Expanded(
                            flex: 2,
                            child: Text(currency.format(entry.value),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.right)),
                        Expanded(
                            flex: 1,
                            child: Text("${pct.toStringAsFixed(0)}%",
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isDark ? Colors.white38 : Colors.grey),
                                textAlign: TextAlign.right)),
                        Expanded(
                            flex: 1,
                            child: Text("$count",
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isDark ? Colors.white38 : Colors.grey),
                                textAlign: TextAlign.right)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  String _avgPerDay(AppProvider provider) {
    final now = DateTime.now();
    final dayOfMonth = now.day;
    final avg = dayOfMonth > 0 ? provider.thisMonthExpenses / dayOfMonth : 0.0;
    return "€${avg.toStringAsFixed(2)}";
  }

  String _topCategory(Map<String, double> categories) {
    if (categories.isEmpty) return "N/A";
    return categories.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  List<PieChartSectionData> _buildPieSections(
      Map<String, double> categories, double total) {
    return categories.entries.map((entry) {
      final pct = total > 0 ? entry.value / total * 100 : 0.0;
      return PieChartSectionData(
        value: entry.value,
        color: _getCategoryColor(entry.key),
        radius: 35,
        title: pct >= 8 ? "${pct.toStringAsFixed(0)}%" : "",
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }).toList();
  }

  static Color _getCategoryColor(String cat) {
    switch (cat) {
      case "Groceries":
        return const Color(0xFF10B981);
      case "Drinks":
        return const Color(0xFFF59E0B);
      case "Transport":
        return const Color(0xFF3B82F6);
      case "Restaurant":
        return const Color(0xFFEF4444);
      case "Health":
        return const Color(0xFFEC4899);
      case "Utility":
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

// ─── Widget Components ──────────────────────────────────────────────────────

class _StatOverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatOverviewCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A4A) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.grey)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final String formattedValue;
  final bool isDark;

  const _ComparisonBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.formattedValue,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final percent = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87)),
            Text(formattedValue,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

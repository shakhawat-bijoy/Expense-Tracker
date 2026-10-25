import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:google_fonts/google_fonts.dart";
import "package:provider/provider.dart";
import "providers/app_provider.dart";
import "screens/dashboard_screen.dart";
import "screens/earnings_screen.dart";
import "screens/expenses_screen.dart";
import "screens/statistics_screen.dart";
import "screens/bills_screen.dart";
import "screens/debts_screen.dart";
import "services/mongodb_service_old.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await MongoService.loadBaseUrl();
  await MongoService.connect();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AppProvider()
              ..loadTheme()
              ..fetchAllData()),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return MaterialApp(
      title: "Expense Tracker",
      debugShowCheckedModeBanner: false,
      themeMode: provider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6366F1),
          foregroundColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          height: 70,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF818CF8),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F23),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2A2A4A)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A2A4A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A2A4A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF818CF8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF818CF8),
          foregroundColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0F0F23),
          indicatorColor: const Color(0xFF818CF8).withValues(alpha: 0.2),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          height: 70,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F23),
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1A1A2E),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1A1A2E),
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  static const _titles = [
    "Dashboard",
    "Shift Earnings",
    "Daily Expenses",
    "Debts & Payoffs",
    "Recurring Bills",
    "Statistics",
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    EarningsScreen(),
    ExpensesScreen(),
    DebtsScreen(),
    BillsScreen(),
    StatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDarkMode;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  RotationTransition(turns: anim, child: child),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
              ),
            ),
            tooltip: isDark ? "Switch to Light Mode" : "Switch to Dark Mode",
            onPressed: () => provider.toggleTheme(),
          ),
          IconButton(
            icon: provider.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed:
                provider.isLoading ? null : () => provider.fetchAllData(),
          ),
          IconButton(
            icon: const Icon(Icons.dns_outlined, size: 20),
            tooltip: "Backend Server URL",
            onPressed: () => _showServerSettingsDialog(context, provider),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: "Shifts",
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: "Expenses",
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_off_outlined),
            selectedIcon: Icon(Icons.credit_card_off_rounded),
            label: "Debts",
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: "Bills",
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: "Stats",
          ),
        ],
      ),
    );
  }

  void _showServerSettingsDialog(BuildContext context, AppProvider provider) {
    final ctrl = TextEditingController(text: MongoService.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Backend Server URL"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "When running on physical Android devices, set your computer's local Wi-Fi IP (e.g. http://192.168.1.15:5000/api) or production host.",
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: "Server Base URL",
                hintText: "https://your-api.example.com/api",
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text("Emulator (10.0.2.2)",
                      style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = "http://10.0.2.2:5000/api",
                ),
                ActionChip(
                  label:
                      const Text("Localhost", style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = "http://localhost:5000/api",
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await MongoService.setCustomBaseUrl(ctrl.text);
              await provider.fetchAllData();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Save & Connect"),
          ),
        ],
      ),
    );
  }
}

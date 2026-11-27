import "package:flutter/material.dart";
import "debts_screen.dart";
import "people_money_screen.dart";

class PeopleDebtsScreen extends StatelessWidget {
  const PeopleDebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.credit_card_off_outlined),
                  text: "Debts",
                ),
                Tab(icon: Icon(Icons.people_alt_outlined), text: "People"),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                DebtsScreen(),
                PeopleMoneyScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

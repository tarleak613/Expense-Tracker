import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:intl/intl.dart';

import 'review_page.dart';
import 'history_page.dart';
import '../services/notification_repository.dart';
import '../services/reminder_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final repo = NotificationRepository();
  int pendingCategorizationCount = 0;
  int pendingReviewCount = 0;
  double monthlyIncome = 0;
  double monthlyExpense = 0;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    final categCount = await repo.pendingCategorizationCount();
    final reviewCount = await repo.getPendingReviewCount();
    final totals = await repo.getMonthlyTotals(DateTime.now());

    if (!mounted) {
      return;
    }

    setState(() {
      pendingCategorizationCount = categCount;
      pendingReviewCount = reviewCount;
      monthlyIncome = totals["income"] ?? 0;
      monthlyExpense = totals["expense"] ?? 0;
    });
  }

  Future<void> openNotificationSettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS',
    );

    await intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Expense Inbox")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const Icon(Icons.account_balance_wallet, size: 100),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                "Review Your Daily Spending",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                "Capture payment notifications and review them later.",
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Pending Review",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pendingReviewCount.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Pending Categorization",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pendingCategorizationCount.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      DateFormat("MMMM yyyy").format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Income",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${monthlyIncome.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Expense",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${monthlyExpense.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text("Notification Access"),
                subtitle: const Text("Tap Grant to manage access"),
                trailing: ElevatedButton(
                  onPressed: openNotificationSettings,
                  child: const Text("Grant"),
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              icon: const Icon(Icons.rate_review),
              label: const Text("Review Transactions"),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReviewPage()),
                );
                await loadDashboardData();
                await ReminderService.refreshScheduleSafely();
              },
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text("View History"),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
                await loadDashboardData();
                await ReminderService.refreshScheduleSafely();
              },
            ),
          ],
        ),
      ),
    );
  }
}

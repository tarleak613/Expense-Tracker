import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_repository.dart';
import '../services/reminder_service.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final repo = NotificationRepository();

  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final allNotifications = await repo.getNotifications();

    final pendingNotifications = allNotifications
        .where((item) => item["reviewed"] != true)
        .toList();

    if (!mounted) {
      return;
    }

    setState(() {
      notifications = pendingNotifications;
    });
  }

  Future<void> reviewTransaction(dynamic id, String type) async {
    await repo.updateTransaction(id, type);
    await loadData();
    unawaited(ReminderService.refreshScheduleSafely());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Captured Transactions")),
      body: notifications.isEmpty
          ? const Center(child: Text("No pending transactions 🎉"))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];

                final timestamp = item["timestamp"] ?? 0;

                final date = DateFormat(
                  'dd MMM yyyy • hh:mm a',
                ).format(DateTime.fromMillisecondsSinceEpoch(timestamp));

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["sender"] ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(item["message"] ?? ""),

                        const SizedBox(height: 8),

                        Text(date, style: const TextStyle(color: Colors.grey)),

                        const SizedBox(height: 8),

                        Text(
                          "ID: ${item["id"]}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () =>
                                  reviewTransaction(item["id"], "expense"),
                              child: const Text("Expense"),
                            ),

                            const SizedBox(width: 8),

                            ElevatedButton(
                              onPressed: () =>
                                  reviewTransaction(item["id"], "income"),
                              child: const Text("Income"),
                            ),

                            const SizedBox(width: 8),

                            ElevatedButton(
                              onPressed: () =>
                                  reviewTransaction(item["id"], "ignore"),
                              child: const Text("Ignore"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

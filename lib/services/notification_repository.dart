import 'dart:convert';
import 'dart:io';

class NotificationRepository {
  final String filePath =
      '/data/user/0/com.example.expense_inbox/files/expense_notifications.json';

  Future<List<dynamic>> getNotifications() async {
    final file = File(filePath);

    if (!await file.exists()) {
      return [];
    }

    final content = await file.readAsString();

    return jsonDecode(content);
  }

  Future<int> pendingCategorizationCount() async {
    final notifications = await getNotifications();

    return notifications.where((item) {
      final category = (item["category"] ?? "").toString().trim();

      return item["reviewed"] == true &&
          (item["type"] == "expense" || item["type"] == "income") &&
          (category.isEmpty || category == "Not set");
    }).length;
  }

  Future<void> editTransaction({
    required dynamic id,
    required double amount,
    required String category,
  }) async {
    final file = File(filePath);

    final content = await file.readAsString();

    final List<dynamic> data = jsonDecode(content);

    for (final item in data) {
      if (item["id"] == id) {
        item["amount"] = amount;
        item["category"] = category;
        break;
      }
    }

    await file.writeAsString(jsonEncode(data));
  }

  Future<void> updateTransaction(dynamic id, String type) async {
    final file = File(filePath);

    final content = await file.readAsString();

    final List<dynamic> data = jsonDecode(content);

    for (final item in data) {
      if (item["id"] == id) {
        item["reviewed"] = true;
        item["type"] = type;

        break;
      }
    }

    await file.writeAsString(jsonEncode(data));
  }

  Future<void> addTransaction({
    required double amount,
    required String type,
    required String category,
    required String message,
  }) async {
    final file = File(filePath);

    List<dynamic> data = [];

    if (await file.exists()) {
      final content = await file.readAsString();
      data = jsonDecode(content);
    }

    data.add({
      "id": DateTime.now().millisecondsSinceEpoch,
      "packageName": "manual",
      "sender": "Manual Entry",
      "message": message,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "amount": amount,
      "reviewed": true,
      "type": type,
      "category": category,
    });

    await file.writeAsString(jsonEncode(data));
  }

  Future<void> deleteTransaction(dynamic id) async {
    final file = File(filePath);

    if (!await file.exists()) return;

    final content = await file.readAsString();
    final List<dynamic> data = jsonDecode(content);

    data.removeWhere((item) => item["id"] == id);

    await file.writeAsString(jsonEncode(data));
  }

  Future<int> getPendingReviewCount() async {
    final notifications = await getNotifications();

    return notifications.where((item) => item["reviewed"] != true).length;
  }

  Future<Map<String, double>> getMonthlyTotals(DateTime month) async {
    final notifications = await getNotifications();

    double totalIncome = 0;
    double totalExpense = 0;

    for (final item in notifications) {
      if (item["reviewed"] != true || item["type"] == "ignore") {
        continue;
      }

      final timestamp = item["timestamp"] ?? 0;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

      if (date.year == month.year && date.month == month.month) {
        final amount = (item["amount"] as num?)?.toDouble() ?? 0.0;

        if (item["type"] == "income") {
          totalIncome += amount;
        } else if (item["type"] == "expense") {
          totalExpense += amount;
        }
      }
    }

    return {
      "income": totalIncome,
      "expense": totalExpense,
    };
  }
}

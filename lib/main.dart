import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'services/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReminderService.initialize();
  runApp(const ExpenseInboxApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ReminderService.openHistoryIfNotificationLaunchedApp();
  });
}

class ExpenseInboxApp extends StatelessWidget {
  const ExpenseInboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: ReminderService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Expense Inbox',
      theme: ThemeData(colorSchemeSeed: Colors.green),
      home: const HomePage(),
    );
  }
}

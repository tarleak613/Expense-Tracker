# Expense Inbox

A Flutter-based expense tracking application that automatically captures transaction notifications from your Android device and helps you organize, categorize, and review your spending.

## Features

* 📱 Automatic notification capture using Android Notification Listener Service
* 💰 Detects payment and banking transaction notifications
* 📊 Categorize transactions as Income, Expense, or Ignore
* 📅 Monthly transaction tracking and summaries
* 🔒 Fully local storage – no server required
* 🎨 Clean Material Design interface
* ⚡ Built with Flutter for a smooth cross-platform experience

## Screenshots

Add screenshots here.

| Home Screen | Review Transactions |
| ----------- | ------------------- |
| Screenshot  | Screenshot          |

## Tech Stack

* Flutter
* Dart
* Android Native (Kotlin)
* Notification Listener Service
* Shared Preferences / Local Storage

## How It Works

1. Grant Notification Access permission.
2. The app listens for incoming payment and banking notifications.
3. Transactions are stored locally on the device.
4. Users review and categorize transactions.
5. Monthly summaries help track spending patterns.

## Installation

Download the latest APK from the Releases section.

## Building from Source

```bash
git clone https://github.com/tarleak613/Expense-Tracker.git
cd Expense-Tracker
flutter pub get
flutter run
```

## Permissions

### Notification Access

This app requires Notification Access permission to read transaction-related notifications from banking and payment applications.

The app only processes notifications on the user's device and does not transmit personal financial information to external servers.

## Privacy

All captured notification data remains on the device.

The application does not:

* Upload financial data to any server
* Share information with third parties
* Track users
* Collect analytics

## Future Enhancements

* Smart transaction categorization
* Expense charts and analytics
* Export to CSV
* Budget planning
* Cloud backup

## License

MIT License

class ExpenseNotification {
  final int? id;
  final String sender;
  final String message;
  final String timestamp;
  final String status;

  ExpenseNotification({
    this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
    required this.status,
  });
}
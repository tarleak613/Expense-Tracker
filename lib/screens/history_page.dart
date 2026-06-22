import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/notification_repository.dart';
import '../services/reminder_service.dart';
import '../services/export_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final repo = NotificationRepository();

  List<dynamic> transactions = [];
  DateTime selectedMonth = DateTime.now();
  int? selectedDay;
  final Set<dynamic> expandedTransactions = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final allTransactions = await repo.getNotifications();

    final reviewedTransactions = allTransactions.where((e) {
      return e["reviewed"] == true && e["type"] != "ignore";
    }).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      transactions = reviewedTransactions;
    });
  }

  void changeMonth(int offset) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + offset,
      );
      selectedDay = null;
    });
  }

  DateTime transactionDate(dynamic item) {
    final timestamp = item["timestamp"] ?? 0;

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  bool isInSelectedMonth(dynamic item) {
    final date = transactionDate(item);

    return date.year == selectedMonth.year && date.month == selectedMonth.month;
  }

  bool isOnSelectedDay(dynamic item) {
    if (selectedDay == null) {
      return true;
    }

    return transactionDate(item).day == selectedDay;
  }

  Future<void> exportToCSV(
    String monthLabel,
    List<dynamic> transactions,
  ) async {
    if (transactions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No transactions to export.")),
      );
      return;
    }

    try {
      final csv = await ExportService.generateCSV(transactions);
      final fileName =
          "Transactions_${monthLabel.replaceAll(" ", "_")}.csv";
      await ExportService.saveCSVFile(csv, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("CSV exported: $fileName")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to export CSV: $e")),
        );
      }
    }
  }

  Future<void> exportToPDF(
    String monthLabel,
    List<dynamic> transactions,
    double totalIncome,
    double totalExpense,
  ) async {
    if (transactions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No transactions to export.")),
      );
      return;
    }

    try {
      final pdfData = await ExportService.generatePDF(
        monthLabel,
        transactions,
        totalIncome,
        totalExpense,
      );
      final fileName =
          "Transactions_${monthLabel.replaceAll(" ", "_")}.pdf";
      await ExportService.savePDFFile(pdfData, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF exported: $fileName")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to export PDF: $e")),
        );
      }
    }
  }

  Future<void> copyToClipboard(
    String monthLabel,
    List<dynamic> transactions,
    double totalIncome,
    double totalExpense,
  ) async {
    if (transactions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No transactions to copy.")),
      );
      return;
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln(monthLabel);
    buffer.writeln();

    for (final tx in transactions) {
      final timestamp = tx["timestamp"] ?? 0;
      final date = DateFormat("dd MMM yyyy")
          .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
      final time = DateFormat("hh:mm a")
          .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
      final type = tx["type"] ?? "";
      final amount = (tx["amount"] as num?)?.toStringAsFixed(2) ?? "0.00";
      final category = ((tx["category"] ?? "") as String).isEmpty
          ? "Not set"
          : tx["category"];

      buffer.writeln("$date | $time | $type | ₹$amount | $category");
    }

    buffer.writeln();
    buffer.writeln("Total Income: ₹${totalIncome.toStringAsFixed(2)}");
    buffer.writeln("Total Expense: ₹${totalExpense.toStringAsFixed(2)}");

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transactions copied to clipboard.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0;
    double totalExpense = 0;
    final monthTransactions = transactions.where(isInSelectedMonth).toList();
    final displayedTransactions = monthTransactions
        .where(isOnSelectedDay)
        .toList();
    final selectedMonthLabel = DateFormat("MMMM yyyy").format(selectedMonth);
    final availableDays =
        monthTransactions.map((item) => transactionDate(item).day).toSet()
          ..addAll(selectedDay == null ? const <int>[] : [selectedDay!]);
    final sortedDays = availableDays.toList()..sort();

    for (final tx in monthTransactions) {
      final amount = (tx["amount"] as num?)?.toDouble() ?? 0.0;

      if (tx["type"] == "income") {
        totalIncome += amount;
      } else if (tx["type"] == "expense") {
        totalExpense += amount;
      }
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final amountController = TextEditingController();

          final categoryController = TextEditingController();

          final noteController = TextEditingController();

          String selectedType = "expense";

          await showDialog(
            context: context,
            builder: (dialogContext) {
              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return AlertDialog(
                    title: const Text("Add Transaction"),

                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: "Amount",
                            ),
                          ),

                          const SizedBox(height: 12),

                          DropdownButton<String>(
                            value: selectedType,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: "expense",
                                child: Text("Expense"),
                              ),

                              DropdownMenuItem(
                                value: "income",
                                child: Text("Income"),
                              ),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                selectedType = value!;
                              });
                            },
                          ),

                          const SizedBox(height: 12),

                          TextField(
                            controller: categoryController,
                            decoration: const InputDecoration(
                              labelText: "Category",
                            ),
                          ),

                          const SizedBox(height: 12),

                          TextField(
                            controller: noteController,
                            decoration: const InputDecoration(
                              labelText: "Note",
                            ),
                          ),
                        ],
                      ),
                    ),

                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text("Cancel"),
                      ),

                      ElevatedButton(
                        onPressed: () async {
                          await repo.addTransaction(
                            amount: double.tryParse(amountController.text) ?? 0,

                            type: selectedType,

                            category: categoryController.text,

                            message: noteController.text,
                          );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          await loadData();
                          unawaited(ReminderService.refreshScheduleSafely());
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      appBar: AppBar(title: const Text("Transaction History")),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => changeMonth(-1),
                    ),
                    Text(
                      selectedMonthLabel,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => changeMonth(1),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<int?>(
                  initialValue: selectedDay,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Day",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text("All Days"),
                    ),
                    ...sortedDays.map((day) {
                      return DropdownMenuItem<int?>(
                        value: day,
                        child: Text(
                          DateFormat("d MMM").format(
                            DateTime(
                              selectedMonth.year,
                              selectedMonth.month,
                              day,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedDay = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                Text("Total Income: ₹${totalIncome.toStringAsFixed(2)}"),

                Text("Total Expense: ₹${totalExpense.toStringAsFixed(2)}"),

                const SizedBox(height: 16),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_download),
                        label: const Text("CSV"),
                        onPressed: displayedTransactions.isEmpty
                            ? null
                            : () => exportToCSV(
                                  selectedMonthLabel,
                                  displayedTransactions,
                                ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("PDF"),
                        onPressed: displayedTransactions.isEmpty
                            ? null
                            : () => exportToPDF(
                                  selectedMonthLabel,
                                  displayedTransactions,
                                  totalIncome,
                                  totalExpense,
                                ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.content_copy),
                        label: const Text("Copy"),
                        onPressed: displayedTransactions.isEmpty
                            ? null
                            : () => copyToClipboard(
                                  selectedMonthLabel,
                                  displayedTransactions,
                                  totalIncome,
                                  totalExpense,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: displayedTransactions.isEmpty
                ? const Center(
                    child: Text(
                      "No transactions found for the selected filters.",
                    ),
                  )
                : ListView.builder(
                    itemCount: displayedTransactions.length,
                    itemBuilder: (context, index) {
                      final item = displayedTransactions[index];

                      final timestamp = item["timestamp"] ?? 0;

                      final formattedDate = DateFormat(
                        "dd MMM yyyy • hh:mm a",
                      ).format(DateTime.fromMillisecondsSinceEpoch(timestamp));

                      final amount = (item["amount"] as num?)?.toDouble() ?? 0;

                      final isIncome = item["type"] == "income";
                      final transactionId = item["id"] ?? "$timestamp-$index";
                      final message = item["message"] ?? "";
                      final isExpanded = expandedTransactions.contains(
                        transactionId,
                      );
                      final previewMessage = message.length > 80
                          ? "${message.substring(0, 80)}..."
                          : message;
                      final category =
                          ((item["category"] ?? "") as String).isEmpty
                          ? "Not set"
                          : item["category"];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                  Text(
                                    isIncome
                                        ? "+ ₹${amount.toStringAsFixed(2)}"
                                        : "- ₹${amount.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isIncome
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              Text(
                                isExpanded ? message : previewMessage,
                                maxLines: isExpanded ? null : 2,
                                overflow: isExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "Category: $category",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),

                              if (message.isNotEmpty)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (isExpanded) {
                                          expandedTransactions.remove(
                                            transactionId,
                                          );
                                        } else {
                                          expandedTransactions.add(
                                            transactionId,
                                          );
                                        }
                                      });
                                    },
                                    child: Text(
                                      isExpanded ? "View Less" : "View More",
                                    ),
                                  ),
                                ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.edit),
                                    label: const Text("Edit"),
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () async {
                                      final amountController =
                                          TextEditingController(
                                            text: amount.toString(),
                                          );

                                      final categoryController =
                                          TextEditingController(
                                            text: item["category"] ?? "",
                                          );

                                      await showDialog(
                                        context: context,
                                        builder: (_) {
                                          return AlertDialog(
                                            title: const Text(
                                              "Edit Transaction",
                                            ),

                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: amountController,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: "Amount",
                                                      ),
                                                ),

                                                const SizedBox(height: 12),

                                                TextField(
                                                  controller:
                                                      categoryController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: "Category",
                                                      ),
                                                ),
                                              ],
                                            ),

                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text("Cancel"),
                                              ),

                                              ElevatedButton(
                                                onPressed: () async {
                                                  await repo.editTransaction(
                                                    id: item["id"],
                                                    amount:
                                                        double.tryParse(
                                                          amountController.text,
                                                        ) ??
                                                        amount,
                                                    category:
                                                        categoryController.text,
                                                  );

                                                  if (context.mounted) {
                                                    Navigator.pop(context);
                                                  }

                                                  await loadData();
                                                  unawaited(
                                                    ReminderService.refreshScheduleSafely(),
                                                  );
                                                },
                                                child: const Text("Save"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),

                                  const SizedBox(width: 8),

                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.delete),
                                    label: const Text("Delete"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      visualDensity: VisualDensity.compact,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (dialogContext) {
                                          return AlertDialog(
                                            title: const Text(
                                              "Delete Transaction",
                                            ),
                                            content: const Text(
                                              "Are you sure you want to delete this transaction?\n\nThis action cannot be undone.",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  dialogContext,
                                                  false,
                                                ),
                                                child: const Text("No"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                  dialogContext,
                                                  true,
                                                ),
                                                child: const Text(
                                                  "Yes, Delete",
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirm == true) {
                                        await repo.deleteTransaction(
                                          item["id"],
                                        );
                                        await loadData();
                                        unawaited(
                                          ReminderService.refreshScheduleSafely(),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

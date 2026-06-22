import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class ExportService {
  static String _formatDate(int timestamp) {
    return DateFormat("dd MMM yyyy")
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  static String _formatTime(int timestamp) {
    return DateFormat("hh:mm a")
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  static Future<String> generateCSV(List<dynamic> transactions) async {
    final List<List<String>> rows = [
      ["Date", "Time", "Type", "Amount", "Category", "Note"],
    ];

    for (final tx in transactions) {
      final timestamp = tx["timestamp"] ?? 0;
      final date = _formatDate(timestamp);
      final time = _formatTime(timestamp);
      final type = tx["type"] ?? "";
      final amount = (tx["amount"] as num?)?.toStringAsFixed(2) ?? "0.00";
      final category = ((tx["category"] ?? "") as String).isEmpty
          ? "Not set"
          : tx["category"];
      final note = tx["message"] ?? "";

      rows.add([
        date,
        time,
        type,
        amount,
        category,
        note,
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    return csv;
  }

  static Future<Uint8List> generatePDF(
    String monthLabel,
    List<dynamic> transactions,
    double totalIncome,
    double totalExpense,
  ) async {
    final pdf = pw.Document();

    const pageSize = PdfPageFormat.a4;
    const itemsPerPage = 15;
    final totalPages =
        ((transactions.length + itemsPerPage - 1) / itemsPerPage).ceil();

    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      final start = pageNum * itemsPerPage;
      final end = (start + itemsPerPage).clamp(0, transactions.length);
      final pageTransactions = transactions.sublist(start, end);

      pdf.addPage(
        pw.Page(
          pageFormat: pageSize,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (pageNum == 0) ...[
                  pw.Text(
                    monthLabel,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Total Income: ₹${totalIncome.toStringAsFixed(2)}",
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                        ),
                      ),
                      pw.Text(
                        "Total Expense: ₹${totalExpense.toStringAsFixed(2)}",
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 15),
                ],
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1.2),
                    3: const pw.FlexColumnWidth(1.2),
                    4: const pw.FlexColumnWidth(1.5),
                    5: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            "Date",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            "Time",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            "Type",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            "Amount",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            "Category",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            "Note",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...pageTransactions.map((tx) {
                      final timestamp = tx["timestamp"] ?? 0;
                      final date = _formatDate(timestamp);
                      final time = _formatTime(timestamp);
                      final type = tx["type"] ?? "";
                      final amount =
                          (tx["amount"] as num?)?.toStringAsFixed(2) ?? "0.00";
                      final category = ((tx["category"] ?? "") as String)
                              .isEmpty
                          ? "Not set"
                          : tx["category"];
                      final note = tx["message"] ?? "";

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              date,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              time,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              type,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              "₹$amount",
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              category,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              note,
                              style: const pw.TextStyle(fontSize: 9),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    "Page ${pageNum + 1} of $totalPages",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static Future<String> getExportDirectory() async {
    try {
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return externalDir.path;
      }
    } catch (e) {
      // Fall back to app documents directory
    }

    final Directory appDir = await getApplicationDocumentsDirectory();
    return appDir.path;
  }

  static Future<String> saveCSVFile(
    String csvContent,
    String fileName,
  ) async {
    final dir = await getExportDirectory();
    final file = File("$dir/$fileName");

    await file.writeAsString(csvContent);
    return file.path;
  }

  static Future<String> savePDFFile(
    Uint8List pdfContent,
    String fileName,
  ) async {
    final dir = await getExportDirectory();
    final file = File("$dir/$fileName");

    await file.writeAsBytes(pdfContent);
    return file.path;
  }
}

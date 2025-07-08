import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:expense_sage/model/payment.model.dart';
import 'package:expense_sage/model/category.model.dart';
import 'package:expense_sage/model/account.model.dart';
import 'package:expense_sage/helpers/currency.helper.dart';
import 'package:intl/intl.dart';

class ExportService {
  static const String _appFolderName = 'ExpenseSage';

  // Get the app's documents directory
  static Future<Directory> _getAppDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('File operations not supported on web');
    }

    Directory? directory;
    if (Platform.isAndroid) {
      // For Android, use external storage
      directory = await getExternalStorageDirectory();
      if (directory != null) {
        final appDir = Directory('${directory.path}/$_appFolderName');
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        return appDir;
      }
    }

    // Fallback to documents directory
    directory = await getApplicationDocumentsDirectory();
    final appDir = Directory('${directory.path}/$_appFolderName');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  // Request storage permissions
  static Future<bool> _requestStoragePermission() async {
    if (kIsWeb || Platform.isIOS) return true;

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Export payments to CSV
  static Future<String?> exportPaymentsToCSV(
    List<Payment> payments, {
    String? fileName,
    String currency = 'USD',
  }) async {
    try {
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      final directory = await _getAppDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file =
          File('${directory.path}/${fileName ?? 'payments_$timestamp'}.csv');

      // Prepare CSV data
      List<List<dynamic>> csvData = [
        [
          'Date',
          'Title',
          'Description',
          'Account',
          'Category',
          'Amount',
          'Type',
          'Currency'
        ]
      ];

      for (final payment in payments) {
        csvData.add([
          DateFormat('yyyy-MM-dd HH:mm:ss').format(payment.datetime),
          payment.title,
          payment.description,
          payment.account.name,
          payment.category.name,
          payment.amount,
          payment.type == PaymentType.credit ? 'Income' : 'Expense',
          currency,
        ]);
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);

      // Write to file
      await file.writeAsString(csvString);

      return file.path;
    } catch (e) {
      print('Error exporting to CSV: $e');
      return null;
    }
  }

  // Export categories to CSV
  static Future<String?> exportCategoriesToCSV(
    List<Category> categories, {
    String? fileName,
    String currency = 'USD',
  }) async {
    try {
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      final directory = await _getAppDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file =
          File('${directory.path}/${fileName ?? 'categories_$timestamp'}.csv');

      // Prepare CSV data
      List<List<dynamic>> csvData = [
        ['Name', 'Budget', 'Expense', 'Remaining', 'Currency']
      ];

      for (final category in categories) {
        final budget = category.budget ?? 0;
        final expense = category.expense ?? 0;
        final remaining = budget - expense;

        csvData.add([
          category.name,
          budget,
          expense,
          remaining,
          currency,
        ]);
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);

      // Write to file
      await file.writeAsString(csvString);

      return file.path;
    } catch (e) {
      print('Error exporting categories to CSV: $e');
      return null;
    }
  }

  // Export accounts to CSV
  static Future<String?> exportAccountsToCSV(
    List<Account> accounts, {
    String? fileName,
    String currency = 'USD',
  }) async {
    try {
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      final directory = await _getAppDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file =
          File('${directory.path}/${fileName ?? 'accounts_$timestamp'}.csv');

      // Prepare CSV data
      List<List<dynamic>> csvData = [
        [
          'Name',
          'Holder Name',
          'Account Number',
          'Balance',
          'Income',
          'Expense',
          'Is Default',
          'Currency'
        ]
      ];

      for (final account in accounts) {
        csvData.add([
          account.name,
          account.holderName,
          account.accountNumber,
          account.balance ?? 0,
          account.income ?? 0,
          account.expense ?? 0,
          account.isDefault == true ? 'Yes' : 'No',
          currency,
        ]);
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);

      // Write to file
      await file.writeAsString(csvString);

      return file.path;
    } catch (e) {
      print('Error exporting accounts to CSV: $e');
      return null;
    }
  }

  // Generate PDF report
  static Future<Uint8List> generatePDFReport({
    required List<Payment> payments,
    required List<Category> categories,
    required List<Account> accounts,
    required DateTimeRange dateRange,
    String currency = 'USD',
    String? userName,
  }) async {
    final pdf = pw.Document();

    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;
    for (final payment in payments) {
      if (payment.type == PaymentType.credit) {
        totalIncome += payment.amount;
      } else {
        totalExpense += payment.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text(
                'Expense Sage - Financial Report',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),

            pw.SizedBox(height: 20),

            // Report Info
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (userName != null)
                    pw.Text('Generated for: $userName',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      'Report Period: ${DateFormat('MMM dd, yyyy').format(dateRange.start)} - ${DateFormat('MMM dd, yyyy').format(dateRange.end)}'),
                  pw.Text(
                      'Generated on: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}'),
                  pw.Text('Currency: $currency'),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Summary Section
            pw.Header(level: 1, child: pw.Text('Financial Summary')),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Metric',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total Income')),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                          CurrencyHelper.format(totalIncome, name: currency))),
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total Expenses')),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                          CurrencyHelper.format(totalExpense, name: currency))),
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Net Income')),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(CurrencyHelper.format(
                          totalIncome - totalExpense,
                          name: currency))),
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total Transactions')),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${payments.length}')),
                ]),
              ],
            ),

            pw.SizedBox(height: 20),

            // Accounts Section
            pw.Header(level: 1, child: pw.Text('Account Summary')),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Account',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Balance',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Income',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Expense',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...accounts.map((account) => pw.TableRow(children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(account.name)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(CurrencyHelper.format(
                              account.balance ?? 0,
                              name: currency))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(CurrencyHelper.format(
                              account.income ?? 0,
                              name: currency))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(CurrencyHelper.format(
                              account.expense ?? 0,
                              name: currency))),
                    ])),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Save PDF to file
  static Future<String?> savePDFReport({
    required List<Payment> payments,
    required List<Category> categories,
    required List<Account> accounts,
    required DateTimeRange dateRange,
    String currency = 'USD',
    String? userName,
    String? fileName,
  }) async {
    try {
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      final pdfData = await generatePDFReport(
        payments: payments,
        categories: categories,
        accounts: accounts,
        dateRange: dateRange,
        currency: currency,
        userName: userName,
      );

      final directory = await _getAppDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File(
          '${directory.path}/${fileName ?? 'financial_report_$timestamp'}.pdf');

      await file.writeAsBytes(pdfData);
      return file.path;
    } catch (e) {
      print('Error saving PDF report: $e');
      return null;
    }
  }

  // Print PDF report
  static Future<void> printPDFReport({
    required List<Payment> payments,
    required List<Category> categories,
    required List<Account> accounts,
    required DateTimeRange dateRange,
    String currency = 'USD',
    String? userName,
  }) async {
    final pdfData = await generatePDFReport(
      payments: payments,
      categories: categories,
      accounts: accounts,
      dateRange: dateRange,
      currency: currency,
      userName: userName,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
    );
  }
}

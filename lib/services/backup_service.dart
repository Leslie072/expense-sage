import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:expense_sage/dao/payment_dao.dart';
import 'package:expense_sage/dao/category_dao.dart';
import 'package:expense_sage/dao/account_dao.dart';
import 'package:expense_sage/dao/user_dao.dart';
import 'package:expense_sage/model/payment.model.dart';
import 'package:expense_sage/model/category.model.dart' as category_model;
import 'package:expense_sage/model/account.model.dart';
import 'package:expense_sage/model/user.model.dart';
import 'package:expense_sage/helpers/db.helper.dart';
import 'package:intl/intl.dart';

class BackupData {
  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> accounts;
  final Map<String, dynamic> userInfo;
  final String version;
  final DateTime createdAt;

  BackupData({
    required this.payments,
    required this.categories,
    required this.accounts,
    required this.userInfo,
    required this.version,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'userInfo': userInfo,
      'payments': payments,
      'categories': categories,
      'accounts': accounts,
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] ?? '1.0.0',
      createdAt: DateTime.parse(json['createdAt']),
      userInfo: json['userInfo'] ?? {},
      payments: List<Map<String, dynamic>>.from(json['payments'] ?? []),
      categories: List<Map<String, dynamic>>.from(json['categories'] ?? []),
      accounts: List<Map<String, dynamic>>.from(json['accounts'] ?? []),
    );
  }
}

class BackupService {
  static const String _appFolderName = 'ExpenseSage';
  static const String _currentVersion = '1.0.1';

  static final PaymentDao _paymentDao = PaymentDao();
  static final CategoryDao _categoryDao = CategoryDao();
  static final AccountDao _accountDao = AccountDao();
  static final UserDao _userDao = UserDao();

  // Get the app's documents directory
  static Future<Directory> _getAppDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('File operations not supported on web');
    }

    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
      if (directory != null) {
        final appDir = Directory('${directory.path}/$_appFolderName');
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        return appDir;
      }
    }

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

  // Create backup of all user data
  static Future<String?> createBackup({String? fileName}) async {
    try {
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      final int? userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch all user data
      final payments = await _paymentDao.find();
      final categories = await _categoryDao.find(withSummery: false);
      final accounts = await _accountDao.find(withSummery: false);
      final user = await _userDao.findById(userId);

      if (user == null) {
        throw Exception('User not found');
      }

      // Convert to JSON format
      final backupData = BackupData(
        version: _currentVersion,
        createdAt: DateTime.now(),
        userInfo: {
          'username': user.username,
          'email': user.email,
          'createdAt': user.createdAt.toIso8601String(),
          // Don't include sensitive data like passwords
        },
        payments: payments.map((p) => p.toJson()).toList(),
        categories: categories.map((c) => c.toJson()).toList(),
        accounts: accounts.map((a) => a.toJson()).toList(),
      );

      // Save to file
      final directory = await _getAppDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File(
          '${directory.path}/${fileName ?? 'expense_sage_backup_$timestamp'}.json');

      final jsonString =
          const JsonEncoder.withIndent('  ').convert(backupData.toJson());
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      print('Error creating backup: $e');
      return null;
    }
  }

  // Restore data from backup file
  static Future<bool> restoreFromBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString);
      final backupData = BackupData.fromJson(jsonData);

      final int? userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Clear existing data (optional - you might want to merge instead)
      // await _clearUserData(userId);

      // Restore accounts first (as they're referenced by payments)
      for (final accountData in backupData.accounts) {
        try {
          final account = Account.fromJson(accountData);
          account.id = null; // Let database assign new ID
          await _accountDao.create(account);
        } catch (e) {
          print('Error restoring account: $e');
        }
      }

      // Restore categories
      for (final categoryData in backupData.categories) {
        try {
          final category = category_model.Category.fromJson(categoryData);
          category.id = null; // Let database assign new ID
          await _categoryDao.create(category);
        } catch (e) {
          print('Error restoring category: $e');
        }
      }

      // Get the newly created accounts and categories to map IDs
      final newAccounts = await _accountDao.find();
      final newCategories = await _categoryDao.find(withSummery: false);

      // Restore payments
      for (final paymentData in backupData.payments) {
        try {
          // Find matching account and category by name
          final accountName = paymentData['account'] is Map
              ? paymentData['account']['name']
              : null;
          final categoryName = paymentData['category'] is Map
              ? paymentData['category']['name']
              : null;

          if (accountName == null || categoryName == null) continue;

          final account = newAccounts.firstWhere(
            (a) => a.name == accountName,
            orElse: () => newAccounts.first,
          );
          final category = newCategories.firstWhere(
            (c) => c.name == categoryName,
            orElse: () => newCategories.first,
          );

          final payment = Payment(
            account: account,
            category: category,
            amount: paymentData['amount']?.toDouble() ?? 0.0,
            type: paymentData['type'] == 'CR'
                ? PaymentType.credit
                : PaymentType.debit,
            datetime: DateTime.parse(paymentData['datetime']),
            title: paymentData['title'] ?? '',
            description: paymentData['description'] ?? '',
          );

          await _paymentDao.create(payment);
        } catch (e) {
          print('Error restoring payment: $e');
        }
      }

      return true;
    } catch (e) {
      print('Error restoring from backup: $e');
      return false;
    }
  }

  // Pick backup file from device
  static Future<String?> pickBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path!;
      }

      return null;
    } catch (e) {
      print('Error picking backup file: $e');
      return null;
    }
  }

  // Get list of available backup files
  static Future<List<FileSystemEntity>> getBackupFiles() async {
    try {
      final directory = await _getAppDirectory();
      final files = directory
          .listSync()
          .where((file) =>
              file.path.endsWith('.json') && file.path.contains('backup'))
          .toList();

      // Sort by modification date (newest first)
      files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      return files;
    } catch (e) {
      print('Error getting backup files: $e');
      return [];
    }
  }

  // Delete backup file
  static Future<bool> deleteBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting backup file: $e');
      return false;
    }
  }

  // Get backup file info
  static Future<Map<String, dynamic>?> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final stat = await file.stat();
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString);
      final backupData = BackupData.fromJson(jsonData);

      return {
        'fileName': file.path.split('/').last,
        'filePath': file.path,
        'fileSize': stat.size,
        'createdAt': backupData.createdAt,
        'version': backupData.version,
        'userInfo': backupData.userInfo,
        'paymentCount': backupData.payments.length,
        'categoryCount': backupData.categories.length,
        'accountCount': backupData.accounts.length,
      };
    } catch (e) {
      print('Error getting backup info: $e');
      return null;
    }
  }

  // Clear user data (use with caution)
  static Future<void> _clearUserData(int userId) async {
    // This would clear all user data - implement with caution
    // You might want to implement this in the DAOs
    print('Warning: Clear user data not implemented for safety');
  }

  // Validate backup file
  static Future<bool> validateBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString);

      // Check required fields
      return jsonData.containsKey('version') &&
          jsonData.containsKey('createdAt') &&
          jsonData.containsKey('payments') &&
          jsonData.containsKey('categories') &&
          jsonData.containsKey('accounts');
    } catch (e) {
      print('Error validating backup file: $e');
      return false;
    }
  }
}

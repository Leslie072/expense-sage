import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_sage/dao/payment_dao.dart';
import 'package:expense_sage/dao/category_dao.dart';
import 'package:expense_sage/dao/account_dao.dart';
import 'package:expense_sage/dao/user_dao.dart';
import 'package:expense_sage/model/payment.model.dart';
import 'package:expense_sage/model/category.model.dart';
import 'package:expense_sage/model/account.model.dart';
import 'package:expense_sage/model/user.model.dart';
import 'package:expense_sage/helpers/db.helper.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  conflict,
}

class SyncResult {
  final SyncStatus status;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  SyncResult({
    required this.status,
    required this.message,
    required this.timestamp,
    this.data,
  });
}

class CloudSyncService {
  static const String _baseUrl =
      'https://api.expensesage.com'; // Replace with actual API
  static const String _syncTokenKey = 'sync_token';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncEnabledKey = 'sync_enabled';
  static const String _autoSyncKey = 'auto_sync_enabled';

  static final PaymentDao _paymentDao = PaymentDao();
  static final CategoryDao _categoryDao = CategoryDao();
  static final AccountDao _accountDao = AccountDao();
  static final UserDao _userDao = UserDao();

  // Check if sync is enabled
  static Future<bool> isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncEnabledKey) ?? false;
  }

  // Enable/disable sync
  static Future<void> setSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, enabled);
  }

  // Check if auto-sync is enabled
  static Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSyncKey) ?? true;
  }

  // Enable/disable auto-sync
  static Future<void> setAutoSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, enabled);
  }

  // Get last sync timestamp
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  // Set last sync timestamp
  static Future<void> _setLastSyncTime(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, timestamp.toIso8601String());
  }

  // Get sync token
  static Future<String?> _getSyncToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_syncTokenKey);
  }

  // Set sync token
  static Future<void> _setSyncToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncTokenKey, token);
  }

  // Authenticate with cloud service
  static Future<SyncResult> authenticate(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'device_id': await _getDeviceId(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _setSyncToken(data['token']);
        await setSyncEnabled(true);

        return SyncResult(
          status: SyncStatus.success,
          message: 'Authentication successful',
          timestamp: DateTime.now(),
          data: data,
        );
      } else {
        return SyncResult(
          status: SyncStatus.error,
          message: 'Authentication failed: ${response.body}',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Authentication error: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  // Sign out from cloud service
  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_syncTokenKey);
    await prefs.remove(_lastSyncKey);
    await setSyncEnabled(false);
  }

  // Perform full sync
  static Future<SyncResult> performSync({bool force = false}) async {
    if (!await isSyncEnabled()) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Sync is not enabled',
        timestamp: DateTime.now(),
      );
    }

    final token = await _getSyncToken();
    if (token == null) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Not authenticated',
        timestamp: DateTime.now(),
      );
    }

    try {
      // Get last sync time
      final lastSync = await getLastSyncTime();
      final syncTimestamp = force ? null : lastSync?.toIso8601String();

      // Upload local changes
      final uploadResult = await _uploadChanges(token, syncTimestamp);
      if (uploadResult.status == SyncStatus.error) {
        return uploadResult;
      }

      // Download remote changes
      final downloadResult = await _downloadChanges(token, syncTimestamp);
      if (downloadResult.status == SyncStatus.error) {
        return downloadResult;
      }

      // Update last sync time
      await _setLastSyncTime(DateTime.now());

      return SyncResult(
        status: SyncStatus.success,
        message: 'Sync completed successfully',
        timestamp: DateTime.now(),
        data: {
          'uploaded': uploadResult.data,
          'downloaded': downloadResult.data,
        },
      );
    } catch (e) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Sync failed: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  // Upload local changes to cloud
  static Future<SyncResult> _uploadChanges(String token, String? since) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get local data that needs to be uploaded
      final payments = await _paymentDao.find();
      final categories = await _categoryDao.find(withSummery: false);
      final accounts = await _accountDao.find(withSummery: false);
      final user = await _userDao.findById(userId);

      final uploadData = {
        'user_id': userId,
        'device_id': await _getDeviceId(),
        'timestamp': DateTime.now().toIso8601String(),
        'since': since,
        'data': {
          'payments': payments.map((p) => p.toJson()).toList(),
          'categories': categories.map((c) => c.toJson()).toList(),
          'accounts': accounts.map((a) => a.toJson()).toList(),
          'user': user?.toJson(),
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/sync/upload'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(uploadData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return SyncResult(
          status: SyncStatus.success,
          message: 'Upload successful',
          timestamp: DateTime.now(),
          data: responseData,
        );
      } else {
        return SyncResult(
          status: SyncStatus.error,
          message: 'Upload failed: ${response.body}',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Upload error: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  // Download remote changes from cloud
  static Future<SyncResult> _downloadChanges(
      String token, String? since) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final queryParams = {
        'user_id': userId.toString(),
        'device_id': await _getDeviceId(),
        if (since != null) 'since': since,
      };

      final uri = Uri.parse('$_baseUrl/sync/download').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Apply remote changes to local database
        await _applyRemoteChanges(responseData['data']);

        return SyncResult(
          status: SyncStatus.success,
          message: 'Download successful',
          timestamp: DateTime.now(),
          data: responseData,
        );
      } else {
        return SyncResult(
          status: SyncStatus.error,
          message: 'Download failed: ${response.body}',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Download error: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  // Apply remote changes to local database
  static Future<void> _applyRemoteChanges(Map<String, dynamic> data) async {
    // This is a simplified implementation
    // In a real app, you'd need to handle conflicts, deletions, etc.

    try {
      // Apply account changes
      if (data['accounts'] != null) {
        for (final accountData in data['accounts']) {
          final account = Account.fromJson(accountData);
          // Check if account exists locally and merge/update
          // For now, we'll just create new ones
          await _accountDao.create(account);
        }
      }

      // Apply category changes
      if (data['categories'] != null) {
        for (final categoryData in data['categories']) {
          final category = Category.fromJson(categoryData);
          await _categoryDao.create(category);
        }
      }

      // Apply payment changes
      if (data['payments'] != null) {
        for (final paymentData in data['payments']) {
          // This would need proper account/category resolution
          // For now, we'll skip payments to avoid foreign key issues
          debugPrint('Would apply payment: ${paymentData['title']}');
        }
      }
    } catch (e) {
      debugPrint('Error applying remote changes: $e');
      rethrow;
    }
  }

  // Get device ID for sync tracking
  static Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    if (deviceId == null) {
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('device_id', deviceId);
    }

    return deviceId;
  }

  // Check if device is online
  static Future<bool> isOnline() async {
    try {
      final result = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return result.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Auto-sync if enabled and conditions are met
  static Future<SyncResult?> autoSync() async {
    if (!await isAutoSyncEnabled() || !await isSyncEnabled()) {
      return null;
    }

    // Check if enough time has passed since last sync
    final lastSync = await getLastSyncTime();
    if (lastSync != null) {
      final timeSinceLastSync = DateTime.now().difference(lastSync);
      if (timeSinceLastSync.inMinutes < 30) {
        return null; // Don't sync too frequently
      }
    }

    // Check if online
    if (!await isOnline()) {
      return null;
    }

    return await performSync();
  }

  // Get sync statistics
  static Future<Map<String, dynamic>> getSyncStats() async {
    final lastSync = await getLastSyncTime();
    final isEnabled = await isSyncEnabled();
    final isAutoEnabled = await isAutoSyncEnabled();
    final isOnlineNow = await isOnline();

    return {
      'lastSync': lastSync?.toIso8601String(),
      'syncEnabled': isEnabled,
      'autoSyncEnabled': isAutoEnabled,
      'isOnline': isOnlineNow,
      'deviceId': await _getDeviceId(),
    };
  }
}

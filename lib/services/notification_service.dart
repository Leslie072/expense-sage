import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_sage/model/payment.model.dart';
import 'package:expense_sage/dao/category_dao.dart';
import 'package:expense_sage/dao/payment_dao.dart';
import 'package:expense_sage/helpers/currency.helper.dart';
import 'dart:convert';

enum AlertType {
  budgetExceeded,
  budgetWarning,
  unusualSpending,
  recurringTransactionDue,
  monthlyReport,
  savingsGoal,
}

class SpendingAlert {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  SpendingAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory SpendingAlert.fromJson(Map<String, dynamic> json) {
    return SpendingAlert(
      id: json['id'],
      type: AlertType.values[json['type']],
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  SpendingAlert copyWith({
    String? id,
    AlertType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return SpendingAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

class NotificationSettings {
  final bool budgetAlerts;
  final bool unusualSpendingAlerts;
  final bool recurringTransactionAlerts;
  final bool monthlyReports;
  final double budgetWarningThreshold; // Percentage (0.0 to 1.0)
  final double unusualSpendingThreshold; // Multiplier for average spending

  NotificationSettings({
    this.budgetAlerts = true,
    this.unusualSpendingAlerts = true,
    this.recurringTransactionAlerts = true,
    this.monthlyReports = true,
    this.budgetWarningThreshold = 0.8, // 80%
    this.unusualSpendingThreshold = 2.0, // 2x average
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      budgetAlerts: json['budgetAlerts'] ?? true,
      unusualSpendingAlerts: json['unusualSpendingAlerts'] ?? true,
      recurringTransactionAlerts: json['recurringTransactionAlerts'] ?? true,
      monthlyReports: json['monthlyReports'] ?? true,
      budgetWarningThreshold: json['budgetWarningThreshold'] ?? 0.8,
      unusualSpendingThreshold: json['unusualSpendingThreshold'] ?? 2.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'budgetAlerts': budgetAlerts,
      'unusualSpendingAlerts': unusualSpendingAlerts,
      'recurringTransactionAlerts': recurringTransactionAlerts,
      'monthlyReports': monthlyReports,
      'budgetWarningThreshold': budgetWarningThreshold,
      'unusualSpendingThreshold': unusualSpendingThreshold,
    };
  }
}

class NotificationService {
  static const String _alertsKey = 'spending_alerts';
  static const String _settingsKey = 'notification_settings';
  static const String _lastCheckKey = 'last_notification_check';

  static final CategoryDao _categoryDao = CategoryDao();
  static final PaymentDao _paymentDao = PaymentDao();

  // Get notification settings
  static Future<NotificationSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson != null) {
      return NotificationSettings.fromJson(json.decode(settingsJson));
    }

    return NotificationSettings();
  }

  // Save notification settings
  static Future<void> saveSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(settings.toJson()));
  }

  // Get all alerts
  static Future<List<SpendingAlert>> getAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final alertsJson = prefs.getStringList(_alertsKey) ?? [];

    return alertsJson.map((alertJson) {
      return SpendingAlert.fromJson(json.decode(alertJson));
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Add new alert
  static Future<void> addAlert(SpendingAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await getAlerts();

    alerts.insert(0, alert);

    // Keep only last 50 alerts
    if (alerts.length > 50) {
      alerts.removeRange(50, alerts.length);
    }

    final alertsJson =
        alerts.map((alert) => json.encode(alert.toJson())).toList();
    await prefs.setStringList(_alertsKey, alertsJson);
  }

  // Mark alert as read
  static Future<void> markAsRead(String alertId) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await getAlerts();

    final updatedAlerts = alerts.map((alert) {
      if (alert.id == alertId) {
        return alert.copyWith(isRead: true);
      }
      return alert;
    }).toList();

    final alertsJson =
        updatedAlerts.map((alert) => json.encode(alert.toJson())).toList();
    await prefs.setStringList(_alertsKey, alertsJson);
  }

  // Clear all alerts
  static Future<void> clearAllAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_alertsKey);
  }

  // Check for new alerts
  static Future<List<SpendingAlert>> checkForAlerts() async {
    final settings = await getSettings();
    final newAlerts = <SpendingAlert>[];

    try {
      // Check budget alerts
      if (settings.budgetAlerts) {
        newAlerts.addAll(await _checkBudgetAlerts(settings));
      }

      // Check unusual spending
      if (settings.unusualSpendingAlerts) {
        newAlerts.addAll(await _checkUnusualSpending(settings));
      }

      // Save new alerts
      for (final alert in newAlerts) {
        await addAlert(alert);
      }

      // Update last check time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error checking for alerts: $e');
    }

    return newAlerts;
  }

  // Check budget alerts
  static Future<List<SpendingAlert>> _checkBudgetAlerts(
      NotificationSettings settings) async {
    final alerts = <SpendingAlert>[];
    final categories = await _categoryDao.find(withSummery: true);

    for (final category in categories) {
      final budget = category.budget ?? 0;
      final expense = category.expense ?? 0;

      if (budget > 0) {
        final percentage = expense / budget;

        if (percentage >= 1.0) {
          // Budget exceeded
          alerts.add(SpendingAlert(
            id: 'budget_exceeded_${category.id}_${DateTime.now().millisecondsSinceEpoch}',
            type: AlertType.budgetExceeded,
            title: 'Budget Exceeded!',
            message: 'You have exceeded your budget for ${category.name}. '
                'Spent: ${CurrencyHelper.format(expense)} / Budget: ${CurrencyHelper.format(budget)}',
            createdAt: DateTime.now(),
            data: {
              'categoryId': category.id,
              'categoryName': category.name,
              'budget': budget,
              'expense': expense,
              'percentage': percentage,
            },
          ));
        } else if (percentage >= settings.budgetWarningThreshold) {
          // Budget warning
          alerts.add(SpendingAlert(
            id: 'budget_warning_${category.id}_${DateTime.now().millisecondsSinceEpoch}',
            type: AlertType.budgetWarning,
            title: 'Budget Warning',
            message:
                'You have used ${(percentage * 100).toStringAsFixed(0)}% of your budget for ${category.name}. '
                'Spent: ${CurrencyHelper.format(expense)} / Budget: ${CurrencyHelper.format(budget)}',
            createdAt: DateTime.now(),
            data: {
              'categoryId': category.id,
              'categoryName': category.name,
              'budget': budget,
              'expense': expense,
              'percentage': percentage,
            },
          ));
        }
      }
    }

    return alerts;
  }

  // Check for unusual spending patterns
  static Future<List<SpendingAlert>> _checkUnusualSpending(
      NotificationSettings settings) async {
    final alerts = <SpendingAlert>[];

    try {
      // Get recent payments (last 7 days)
      final recentRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      );
      final recentPayments = await _paymentDao.find(range: recentRange);

      // Get historical payments (last 30 days, excluding recent 7 days)
      final historicalRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now().subtract(const Duration(days: 7)),
      );
      final historicalPayments = await _paymentDao.find(range: historicalRange);

      if (historicalPayments.isNotEmpty) {
        // Calculate average daily spending
        final historicalTotal = historicalPayments
            .where((p) => p.type == PaymentType.debit)
            .fold(0.0, (sum, p) => sum + p.amount);
        final historicalDays = historicalRange.duration.inDays;
        final averageDailySpending = historicalTotal / historicalDays;

        // Calculate recent daily spending
        final recentTotal = recentPayments
            .where((p) => p.type == PaymentType.debit)
            .fold(0.0, (sum, p) => sum + p.amount);
        final recentDays = recentRange.duration.inDays;
        final recentDailySpending = recentTotal / recentDays;

        // Check if recent spending is unusually high
        if (recentDailySpending >
            averageDailySpending * settings.unusualSpendingThreshold) {
          alerts.add(SpendingAlert(
            id: 'unusual_spending_${DateTime.now().millisecondsSinceEpoch}',
            type: AlertType.unusualSpending,
            title: 'Unusual Spending Detected',
            message: 'Your spending has increased significantly. '
                'Recent daily average: ${CurrencyHelper.format(recentDailySpending)} '
                '(vs normal: ${CurrencyHelper.format(averageDailySpending)})',
            createdAt: DateTime.now(),
            data: {
              'recentDailySpending': recentDailySpending,
              'averageDailySpending': averageDailySpending,
              'multiplier': recentDailySpending / averageDailySpending,
            },
          ));
        }
      }
    } catch (e) {
      debugPrint('Error checking unusual spending: $e');
    }

    return alerts;
  }

  // Get unread alerts count
  static Future<int> getUnreadCount() async {
    final alerts = await getAlerts();
    return alerts.where((alert) => !alert.isRead).length;
  }

  // Create manual alert (for testing or custom notifications)
  static Future<void> createAlert({
    required AlertType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final alert = SpendingAlert(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      data: data,
    );

    await addAlert(alert);
  }

  // Get alert icon based on type
  static IconData getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.budgetExceeded:
        return Icons.warning;
      case AlertType.budgetWarning:
        return Icons.info;
      case AlertType.unusualSpending:
        return Icons.trending_up;
      case AlertType.recurringTransactionDue:
        return Icons.schedule;
      case AlertType.monthlyReport:
        return Icons.assessment;
      case AlertType.savingsGoal:
        return Icons.savings;
    }
  }

  // Get alert color based on type
  static Color getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.budgetExceeded:
        return Colors.red;
      case AlertType.budgetWarning:
        return Colors.orange;
      case AlertType.unusualSpending:
        return Colors.purple;
      case AlertType.recurringTransactionDue:
        return Colors.blue;
      case AlertType.monthlyReport:
        return Colors.green;
      case AlertType.savingsGoal:
        return Colors.teal;
    }
  }
}

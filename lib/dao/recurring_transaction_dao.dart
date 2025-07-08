import 'dart:async';
import 'package:expense_sage/helpers/db.helper.dart';
import 'package:expense_sage/model/recurring_transaction.model.dart';
import 'package:expense_sage/model/account.model.dart';
import 'package:expense_sage/model/category.model.dart';
import 'package:expense_sage/model/payment.model.dart';
import 'package:expense_sage/dao/account_dao.dart';
import 'package:expense_sage/dao/category_dao.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';

class RecurringTransactionDao {
  final AccountDao _accountDao = AccountDao();
  final CategoryDao _categoryDao = CategoryDao();

  Future<int> create(RecurringTransaction recurringTransaction) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> data = recurringTransaction.toJson();
    data['user_id'] = userId;
    data.remove('id'); // Let database assign ID

    var result = await db.insert("recurring_transactions", data);
    return result;
  }

  Future<List<RecurringTransaction>> find({
    RecurrenceStatus? status,
    bool? isDue,
    int? limit,
  }) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    String whereClause = "rt.user_id = ?";
    List<dynamic> whereArgs = [userId];

    if (status != null) {
      whereClause += " AND rt.status = ?";
      whereArgs.add(status.index);
    }

    if (isDue == true) {
      whereClause += " AND rt.next_due <= datetime('now')";
    }

    String sql = """
      SELECT 
        rt.*,
        a.id as account_id, a.name as account_name, a.holderName as account_holder_name,
        a.accountNumber as account_number, a.icon as account_icon, a.color as account_color,
        a.isDefault as account_is_default, a.balance as account_balance,
        a.income as account_income, a.expense as account_expense,
        c.id as category_id, c.name as category_name, c.icon as category_icon,
        c.color as category_color, c.budget as category_budget, c.expense as category_expense
      FROM recurring_transactions rt
      LEFT JOIN accounts a ON rt.account = a.id
      LEFT JOIN categories c ON rt.category = c.id
      WHERE $whereClause
      ORDER BY rt.next_due ASC
    """;

    if (limit != null) {
      sql += " LIMIT $limit";
    }

    List<Map<String, dynamic>> result = await db.rawQuery(sql, whereArgs);

    return result.map((data) => _mapToRecurringTransaction(data)).toList();
  }

  Future<RecurringTransaction?> findById(int id) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    String sql = """
      SELECT 
        rt.*,
        a.id as account_id, a.name as account_name, a.holderName as account_holder_name,
        a.accountNumber as account_number, a.icon as account_icon, a.color as account_color,
        a.isDefault as account_is_default, a.balance as account_balance,
        a.income as account_income, a.expense as account_expense,
        c.id as category_id, c.name as category_name, c.icon as category_icon,
        c.color as category_color, c.budget as category_budget, c.expense as category_expense
      FROM recurring_transactions rt
      LEFT JOIN accounts a ON rt.account = a.id
      LEFT JOIN categories c ON rt.category = c.id
      WHERE rt.id = ? AND rt.user_id = ?
    """;

    List<Map<String, dynamic>> result = await db.rawQuery(sql, [id, userId]);

    if (result.isNotEmpty) {
      return _mapToRecurringTransaction(result.first);
    }
    return null;
  }

  Future<int> update(RecurringTransaction recurringTransaction) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> data = recurringTransaction.toJson();
    data['user_id'] = userId;
    data['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      "recurring_transactions",
      data,
      where: "id = ? AND user_id = ?",
      whereArgs: [recurringTransaction.id, userId],
    );
  }

  Future<int> delete(int id) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return await db.delete(
      "recurring_transactions",
      where: "id = ? AND user_id = ?",
      whereArgs: [id, userId],
    );
  }

  Future<List<RecurringTransaction>> getDueTransactions() async {
    return await find(status: RecurrenceStatus.active, isDue: true);
  }

  Future<List<RecurringTransaction>> getActiveTransactions() async {
    return await find(status: RecurrenceStatus.active);
  }

  Future<int> markAsExecuted(int id) async {
    final recurringTransaction = await findById(id);
    if (recurringTransaction == null) {
      throw Exception('Recurring transaction not found');
    }

    recurringTransaction.markAsExecuted();
    return await update(recurringTransaction);
  }

  Future<int> pauseTransaction(int id) async {
    final recurringTransaction = await findById(id);
    if (recurringTransaction == null) {
      throw Exception('Recurring transaction not found');
    }

    recurringTransaction.pause();
    return await update(recurringTransaction);
  }

  Future<int> resumeTransaction(int id) async {
    final recurringTransaction = await findById(id);
    if (recurringTransaction == null) {
      throw Exception('Recurring transaction not found');
    }

    recurringTransaction.resume();
    return await update(recurringTransaction);
  }

  Future<int> cancelTransaction(int id) async {
    final recurringTransaction = await findById(id);
    if (recurringTransaction == null) {
      throw Exception('Recurring transaction not found');
    }

    recurringTransaction.cancel();
    return await update(recurringTransaction);
  }

  RecurringTransaction _mapToRecurringTransaction(Map<String, dynamic> data) {
    // Map account data
    Account account = Account(
      id: data['account_id'],
      name: data['account_name'] ?? '',
      holderName: data['account_holder_name'] ?? '',
      accountNumber: data['account_number'] ?? '',
      icon: IconData(data['account_icon'] ?? 0, fontFamily: 'MaterialIcons'),
      color: Color(data['account_color'] ?? 0),
      isDefault: data['account_is_default'] == 1,
      balance: data['account_balance']?.toDouble(),
      income: data['account_income']?.toDouble(),
      expense: data['account_expense']?.toDouble(),
    );

    // Map category data
    Category category = Category(
      id: data['category_id'],
      name: data['category_name'] ?? '',
      icon: IconData(data['category_icon'] ?? 0, fontFamily: 'MaterialIcons'),
      color: Color(data['category_color'] ?? 0),
      budget: data['category_budget']?.toDouble(),
      expense: data['category_expense']?.toDouble(),
    );

    // Create recurring transaction with mapped account and category
    return RecurringTransaction(
      id: data['id'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      account: account,
      category: category,
      amount: data['amount']?.toDouble() ?? 0.0,
      type: data['type'] == 'CR' ? PaymentType.credit : PaymentType.debit,
      recurrenceType: RecurrenceType.values[data['recurrence_type'] ?? 0],
      status: RecurrenceStatus.values[data['status'] ?? 0],
      startDate: DateTime.parse(data['start_date']),
      endDate:
          data['end_date'] != null ? DateTime.parse(data['end_date']) : null,
      lastExecuted: data['last_executed'] != null
          ? DateTime.parse(data['last_executed'])
          : null,
      nextDue:
          data['next_due'] != null ? DateTime.parse(data['next_due']) : null,
      maxOccurrences: data['max_occurrences'],
      executedCount: data['executed_count'] ?? 0,
      isAutoExecute: data['is_auto_execute'] == 1,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get counts by status
    final statusCounts = await db.rawQuery("""
      SELECT status, COUNT(*) as count
      FROM recurring_transactions
      WHERE user_id = ?
      GROUP BY status
    """, [userId]);

    // Get due transactions count
    final dueCount = await db.rawQuery("""
      SELECT COUNT(*) as count
      FROM recurring_transactions
      WHERE user_id = ? AND status = ? AND next_due <= datetime('now')
    """, [userId, RecurrenceStatus.active.index]);

    // Get total amount by type
    final amountByType = await db.rawQuery("""
      SELECT type, SUM(amount) as total
      FROM recurring_transactions
      WHERE user_id = ? AND status = ?
      GROUP BY type
    """, [userId, RecurrenceStatus.active.index]);

    return {
      'statusCounts': statusCounts,
      'dueCount': dueCount.first['count'] ?? 0,
      'amountByType': amountByType,
    };
  }
}

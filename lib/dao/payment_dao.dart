import 'dart:async';
import 'package:expense_sage/dao/account_dao.dart';
import 'package:expense_sage/dao/category_dao.dart';
import 'package:expense_sage/helpers/db.helper.dart';
import 'package:expense_sage/model/account.model.dart';
import 'package:expense_sage/model/category.model.dart';
import 'package:expense_sage/model/payment.model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentDao {
  Future<int> create(Payment payment) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> paymentData = payment.toJson();
    paymentData['user_id'] = userId;
    var result = db.insert("payments", paymentData);
    return result;
  }

  Future<List<Payment>> find(
      {DateTimeRange? range,
      PaymentType? type,
      Category? category,
      Account? account}) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    String where = "AND user_id = $userId ";

    if (range != null) {
      where +=
          "AND datetime BETWEEN DATE('${DateFormat('yyyy-MM-dd kk:mm:ss').format(range.start)}') AND DATE('${DateFormat('yyyy-MM-dd kk:mm:ss').format(range.end.add(const Duration(days: 1)))}')";
    }

    //type check
    if (type != null) {
      where += "AND type='${type == PaymentType.credit ? "DR" : "CR"}' ";
    }

    //icon check
    if (account != null) {
      where += "AND account='${account.id}' ";
    }

    //icon check
    if (category != null) {
      where += "AND category='${category.id}' ";
    }

    //categories
    List<Category> categories = await CategoryDao().find();
    List<Account> accounts = await AccountDao().find();

    List<Payment> payments = [];
    List<Map<String, Object?>> rows = await db.query("payments",
        orderBy: "datetime DESC, id DESC", where: "1=1 $where");
    for (var row in rows) {
      Map<String, dynamic> payment = Map<String, dynamic>.from(row);
      Account account = accounts.firstWhere((a) => a.id == payment["account"]);
      Category category =
          categories.firstWhere((c) => c.id == payment["category"]);
      payment["category"] = category.toJson();
      payment["account"] = account.toJson();
      payments.add(Payment.fromJson(payment));
    }

    return payments;
  }

  Future<int> update(Payment payment) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> paymentData = payment.toJson();
    paymentData['user_id'] = userId;
    var result = await db.update("payments", paymentData,
        where: "id = ? AND user_id = ?", whereArgs: [payment.id, userId]);

    return result;
  }

  Future<int> upsert(Payment payment) async {
    final db = await getDBInstance();
    int result;
    if (payment.id != null) {
      result = await db.update("payments", payment.toJson(),
          where: "id = ?", whereArgs: [payment.id]);
    } else {
      result = await db.insert("payments", payment.toJson());
    }

    return result;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    var result = await db.delete("payments",
        where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
    return result;
  }

  Future deleteAllTransactions() async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    var result = await db.delete(
      "payments",
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result;
  }
}

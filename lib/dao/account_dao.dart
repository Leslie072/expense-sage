import 'dart:async';
import 'package:expense_sage/helpers/db.helper.dart';
import 'package:expense_sage/model/account.model.dart';
import 'package:sqflite/sqflite.dart';

class AccountDao {
  Future<int> create(Account account) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> accountData = account.toJson();
    accountData['user_id'] = userId;
    var result = await db.insert("accounts", accountData);
    return result;
  }

  Future<List<Account>> find({bool withSummery = false}) async {
    final Database db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    List<Map<String, dynamic>> result;
    if (withSummery) {
      String fields = [
        "a.id",
        "a.name",
        "a.holderName",
        "a.accountNumber",
        "a.icon",
        "a.color",
        "a.isDefault",
        "SUM(CASE WHEN t.type='DR' AND t.account=a.id THEN t.amount END) as expense",
        "SUM(CASE WHEN t.type='CR' AND t.account=a.id THEN t.amount END) as income"
      ].join(",");
      String sql =
          "SELECT $fields FROM accounts a LEFT JOIN payments t ON t.account = a.id AND t.user_id = $userId WHERE a.user_id = $userId GROUP BY a.id";
      result = await db.rawQuery(sql);
    } else {
      result = await db.query(
        "accounts",
        where: "user_id = ?",
        whereArgs: [userId],
      );
    }
    List<Account> accounts = [];
    if (result.isNotEmpty) {
      accounts = result.map((item) {
        Map<String, dynamic> nItem = Map.from(item);
        if (withSummery) {
          nItem["income"] = nItem["income"] ?? 0.0;
          nItem["expense"] = nItem["expense"] ?? 0.0;
          nItem["balance"] =
              double.parse((nItem["income"] - nItem["expense"]).toString());
        }
        return Account.fromJson(nItem);
      }).toList();
    }
    return accounts;
  }

  Future<int> update(Account account) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> accountData = account.toJson();
    accountData['user_id'] = userId;
    var result = await db.update("accounts", accountData,
        where: "id = ? AND user_id = ?", whereArgs: [account.id, userId]);
    return result;
  }

  Future<int> upsert(Account account) async {
    if (account.id != null) {
      return await update(account);
    } else {
      return await create(account);
    }
  }

  Future<int> delete(int id) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    var result = await db.delete("accounts",
        where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
    await db.delete("payments",
        where: "account = ? AND user_id = ?", whereArgs: [id, userId]);
    return result;
  }
}

import 'dart:async';
import 'package:expense_sage/helpers/db.helper.dart';
import 'package:expense_sage/model/receipt.model.dart';
import 'package:sqflite/sqflite.dart';

class ReceiptDao {
  Future<int> create(Receipt receipt) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> data = receipt.toJson();
    data['user_id'] = userId;
    data.remove('id'); // Let database assign ID
    
    var result = await db.insert("receipts", data);
    return result;
  }

  Future<List<Receipt>> find({
    ReceiptStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? merchantName,
    int? paymentId,
    int? limit,
  }) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    String whereClause = "user_id = ?";
    List<dynamic> whereArgs = [userId];

    if (status != null) {
      whereClause += " AND status = ?";
      whereArgs.add(status.index);
    }

    if (startDate != null) {
      whereClause += " AND transaction_date >= ?";
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += " AND transaction_date <= ?";
      whereArgs.add(endDate.toIso8601String());
    }

    if (merchantName != null && merchantName.isNotEmpty) {
      whereClause += " AND merchant_name LIKE ?";
      whereArgs.add('%$merchantName%');
    }

    if (paymentId != null) {
      whereClause += " AND payment_id = ?";
      whereArgs.add(paymentId);
    }

    String sql = "SELECT * FROM receipts WHERE $whereClause ORDER BY transaction_date DESC";

    if (limit != null) {
      sql += " LIMIT $limit";
    }

    List<Map<String, dynamic>> result = await db.rawQuery(sql, whereArgs);
    
    return result.map((data) => Receipt.fromJson(data)).toList();
  }

  Future<Receipt?> findById(int id) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT * FROM receipts WHERE id = ? AND user_id = ?",
      [id, userId],
    );
    
    if (result.isNotEmpty) {
      return Receipt.fromJson(result.first);
    }
    return null;
  }

  Future<int> update(Receipt receipt) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> data = receipt.toJson();
    data['user_id'] = userId;
    data['updated_at'] = DateTime.now().toIso8601String();
    
    return await db.update(
      "receipts",
      data,
      where: "id = ? AND user_id = ?",
      whereArgs: [receipt.id, userId],
    );
  }

  Future<int> delete(int id) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return await db.delete(
      "receipts",
      where: "id = ? AND user_id = ?",
      whereArgs: [id, userId],
    );
  }

  Future<List<Receipt>> getPendingReceipts() async {
    return await find(status: ReceiptStatus.pending);
  }

  Future<List<Receipt>> getProcessedReceipts() async {
    return await find(status: ReceiptStatus.processed);
  }

  Future<List<Receipt>> getVerifiedReceipts() async {
    return await find(status: ReceiptStatus.verified);
  }

  Future<List<Receipt>> getUnlinkedReceipts() async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT * FROM receipts WHERE user_id = ? AND payment_id IS NULL ORDER BY transaction_date DESC",
      [userId],
    );
    
    return result.map((data) => Receipt.fromJson(data)).toList();
  }

  Future<List<Receipt>> getReceiptsByPayment(int paymentId) async {
    return await find(paymentId: paymentId);
  }

  Future<int> linkToPayment(int receiptId, int paymentId) async {
    final receipt = await findById(receiptId);
    if (receipt == null) {
      throw Exception('Receipt not found');
    }

    receipt.linkToPayment(paymentId);
    return await update(receipt);
  }

  Future<int> unlinkFromPayment(int receiptId) async {
    final receipt = await findById(receiptId);
    if (receipt == null) {
      throw Exception('Receipt not found');
    }

    receipt.unlinkFromPayment();
    return await update(receipt);
  }

  Future<int> updateStatus(int receiptId, ReceiptStatus status) async {
    final receipt = await findById(receiptId);
    if (receipt == null) {
      throw Exception('Receipt not found');
    }

    receipt.updateStatus(status);
    return await update(receipt);
  }

  Future<int> archiveReceipt(int receiptId) async {
    final receipt = await findById(receiptId);
    if (receipt == null) {
      throw Exception('Receipt not found');
    }

    receipt.archive();
    return await update(receipt);
  }

  Future<int> restoreReceipt(int receiptId) async {
    final receipt = await findById(receiptId);
    if (receipt == null) {
      throw Exception('Receipt not found');
    }

    receipt.restore();
    return await update(receipt);
  }

  Future<Map<String, dynamic>> getReceiptsSummary() async {
    final receipts = await find();
    
    double totalAmount = 0;
    double totalTax = 0;
    int pendingCount = 0;
    int processedCount = 0;
    int verifiedCount = 0;
    int archivedCount = 0;
    
    for (final receipt in receipts) {
      totalAmount += receipt.totalAmount;
      totalTax += receipt.taxAmount;
      
      switch (receipt.status) {
        case ReceiptStatus.pending:
          pendingCount++;
          break;
        case ReceiptStatus.processed:
          processedCount++;
          break;
        case ReceiptStatus.verified:
          verifiedCount++;
          break;
        case ReceiptStatus.archived:
          archivedCount++;
          break;
      }
    }
    
    return {
      'totalReceipts': receipts.length,
      'totalAmount': totalAmount,
      'totalTax': totalTax,
      'pendingCount': pendingCount,
      'processedCount': processedCount,
      'verifiedCount': verifiedCount,
      'archivedCount': archivedCount,
      'receipts': receipts,
    };
  }

  Future<List<Receipt>> searchReceipts(String query) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    List<Map<String, dynamic>> result = await db.rawQuery("""
      SELECT * FROM receipts 
      WHERE user_id = ? AND (
        merchant_name LIKE ? OR 
        receipt_number LIKE ? OR 
        ocr_text LIKE ?
      )
      ORDER BY transaction_date DESC
    """, [userId, '%$query%', '%$query%', '%$query%']);
    
    return result.map((data) => Receipt.fromJson(data)).toList();
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
      FROM receipts
      WHERE user_id = ?
      GROUP BY status
    """, [userId]);

    // Get monthly totals
    final monthlyTotals = await db.rawQuery("""
      SELECT 
        strftime('%Y-%m', transaction_date) as month,
        COUNT(*) as count,
        SUM(total_amount) as total
      FROM receipts
      WHERE user_id = ?
      GROUP BY strftime('%Y-%m', transaction_date)
      ORDER BY month DESC
      LIMIT 12
    """, [userId]);

    // Get top merchants
    final topMerchants = await db.rawQuery("""
      SELECT 
        merchant_name,
        COUNT(*) as count,
        SUM(total_amount) as total
      FROM receipts
      WHERE user_id = ? AND merchant_name != ''
      GROUP BY merchant_name
      ORDER BY count DESC
      LIMIT 10
    """, [userId]);

    return {
      'statusCounts': statusCounts,
      'monthlyTotals': monthlyTotals,
      'topMerchants': topMerchants,
    };
  }

  Future<List<Receipt>> getReceiptsNeedingReview() async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    List<Map<String, dynamic>> result = await db.rawQuery("""
      SELECT * FROM receipts 
      WHERE user_id = ? AND (
        status = ? OR 
        (ocr_text IS NOT NULL AND ocr_text != '' AND items IS NULL)
      )
      ORDER BY created_at DESC
    """, [userId, ReceiptStatus.pending.index]);
    
    return result.map((data) => Receipt.fromJson(data)).toList();
  }
}

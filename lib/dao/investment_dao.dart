import 'dart:async';
import 'package:expense_sage/helpers/db.helper.dart';
import 'package:expense_sage/model/investment.model.dart';

class InvestmentDao {
  Future<int> create(Investment investment) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> data = investment.toJson();
    data['user_id'] = userId;
    data.remove('id'); // Let database assign ID

    var result = await db.insert("investments", data);
    return result;
  }

  Future<List<Investment>> find({
    InvestmentStatus? status,
    InvestmentType? type,
    String? symbol,
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

    if (type != null) {
      whereClause += " AND type = ?";
      whereArgs.add(type.index);
    }

    if (symbol != null && symbol.isNotEmpty) {
      whereClause += " AND symbol LIKE ?";
      whereArgs.add('%$symbol%');
    }

    String sql =
        "SELECT * FROM investments WHERE $whereClause ORDER BY created_at DESC";

    if (limit != null) {
      sql += " LIMIT $limit";
    }

    List<Map<String, dynamic>> result = await db.rawQuery(sql, whereArgs);

    return result.map((data) => Investment.fromJson(data)).toList();
  }

  Future<Investment?> findById(int id) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT * FROM investments WHERE id = ? AND user_id = ?",
      [id, userId],
    );

    if (result.isNotEmpty) {
      return Investment.fromJson(result.first);
    }
    return null;
  }

  Future<Investment?> findBySymbol(String symbol) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT * FROM investments WHERE symbol = ? AND user_id = ? AND status = ?",
      [symbol, userId, InvestmentStatus.active.index],
    );

    if (result.isNotEmpty) {
      return Investment.fromJson(result.first);
    }
    return null;
  }

  Future<int> update(Investment investment) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> data = investment.toJson();
    data['user_id'] = userId;
    data['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      "investments",
      data,
      where: "id = ? AND user_id = ?",
      whereArgs: [investment.id, userId],
    );
  }

  Future<int> delete(int id) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return await db.delete(
      "investments",
      where: "id = ? AND user_id = ?",
      whereArgs: [id, userId],
    );
  }

  Future<List<Investment>> getActiveInvestments() async {
    return await find(status: InvestmentStatus.active);
  }

  Future<List<Investment>> getInvestmentsByType(InvestmentType type) async {
    return await find(type: type);
  }

  Future<Map<String, dynamic>> getPortfolioSummary() async {
    final investments = await getActiveInvestments();

    double totalValue = 0;
    double totalCost = 0;
    double totalGainLoss = 0;
    Map<InvestmentType, double> typeAllocation = {};
    Map<String, double> sectorAllocation = {};

    for (final investment in investments) {
      final currentValue = investment.currentMarketValue;
      final cost = investment.totalPurchaseValue;

      totalValue += currentValue;
      totalCost += cost;
      totalGainLoss += investment.unrealizedGainLoss;

      // Type allocation
      typeAllocation[investment.type] =
          (typeAllocation[investment.type] ?? 0) + currentValue;

      // Sector allocation
      if (investment.sector.isNotEmpty) {
        sectorAllocation[investment.sector] =
            (sectorAllocation[investment.sector] ?? 0) + currentValue;
      }
    }

    return {
      'totalValue': totalValue,
      'totalCost': totalCost,
      'totalGainLoss': totalGainLoss,
      'totalGainLossPercentage':
          totalCost > 0 ? (totalGainLoss / totalCost) * 100 : 0,
      'investmentCount': investments.length,
      'typeAllocation': typeAllocation,
      'sectorAllocation': sectorAllocation,
      'investments': investments,
    };
  }

  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    final investments = await getActiveInvestments();

    if (investments.isEmpty) {
      return {
        'bestPerformer': null,
        'worstPerformer': null,
        'averageReturn': 0.0,
        'totalDividends': 0.0,
      };
    }

    Investment? bestPerformer;
    Investment? worstPerformer;
    double totalReturn = 0;

    for (final investment in investments) {
      final returnPercentage = investment.gainLossPercentage;
      totalReturn += returnPercentage;

      if (bestPerformer == null ||
          returnPercentage > bestPerformer.gainLossPercentage) {
        bestPerformer = investment;
      }

      if (worstPerformer == null ||
          returnPercentage < worstPerformer.gainLossPercentage) {
        worstPerformer = investment;
      }
    }

    return {
      'bestPerformer': bestPerformer,
      'worstPerformer': worstPerformer,
      'averageReturn': totalReturn / investments.length,
      'totalDividends': 0.0, // Would need dividend tracking
    };
  }

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    List<Map<String, dynamic>> result = await db.rawQuery("""
      SELECT * FROM investments 
      WHERE user_id = ? 
      ORDER BY updated_at DESC 
      LIMIT ?
    """, [userId, limit]);

    return result;
  }

  Future<int> updatePrice(String symbol, double newPrice) async {
    final investment = await findBySymbol(symbol);
    if (investment == null) return 0;

    investment.updatePrice(newPrice);
    return await update(investment);
  }

  Future<int> updateMultiplePrices(Map<String, double> prices) async {
    int updatedCount = 0;

    for (final entry in prices.entries) {
      final count = await updatePrice(entry.key, entry.value);
      updatedCount += count;
    }

    return updatedCount;
  }

  Future<List<String>> getAllSymbols() async {
    final investments = await getActiveInvestments();
    return investments.map((i) => i.symbol).toSet().toList();
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
      FROM investments
      WHERE user_id = ?
      GROUP BY status
    """, [userId]);

    // Get counts by type
    final typeCounts = await db.rawQuery("""
      SELECT type, COUNT(*) as count
      FROM investments
      WHERE user_id = ? AND status = ?
      GROUP BY type
    """, [userId, InvestmentStatus.active.index]);

    return {
      'statusCounts': statusCounts,
      'typeCounts': typeCounts,
    };
  }
}

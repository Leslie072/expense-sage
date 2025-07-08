import 'dart:async';
import 'package:expense_sage/helpers/db.helper.dart';
import 'package:expense_sage/model/savings_goal.model.dart';
import 'package:sqflite/sqflite.dart';

class SavingsGoalDao {
  Future<int> create(SavingsGoal goal) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> data = goal.toJson();
    data['user_id'] = userId;
    data.remove('id'); // Let database assign ID
    
    var result = await db.insert("savings_goals", data);
    return result;
  }

  Future<List<SavingsGoal>> find({
    GoalStatus? status,
    GoalPriority? priority,
    bool? isActive,
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

    if (priority != null) {
      whereClause += " AND priority = ?";
      whereArgs.add(priority.index);
    }

    if (isActive == true) {
      whereClause += " AND status = ?";
      whereArgs.add(GoalStatus.active.index);
    }

    String sql = "SELECT * FROM savings_goals WHERE $whereClause ORDER BY priority DESC, created_at DESC";

    if (limit != null) {
      sql += " LIMIT $limit";
    }

    List<Map<String, dynamic>> result = await db.rawQuery(sql, whereArgs);
    
    return result.map((data) => SavingsGoal.fromJson(data)).toList();
  }

  Future<SavingsGoal?> findById(int id) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT * FROM savings_goals WHERE id = ? AND user_id = ?",
      [id, userId],
    );
    
    if (result.isNotEmpty) {
      return SavingsGoal.fromJson(result.first);
    }
    return null;
  }

  Future<int> update(SavingsGoal goal) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> data = goal.toJson();
    data['user_id'] = userId;
    data['updated_at'] = DateTime.now().toIso8601String();
    
    return await db.update(
      "savings_goals",
      data,
      where: "id = ? AND user_id = ?",
      whereArgs: [goal.id, userId],
    );
  }

  Future<int> delete(int id) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return await db.delete(
      "savings_goals",
      where: "id = ? AND user_id = ?",
      whereArgs: [id, userId],
    );
  }

  Future<List<SavingsGoal>> getActiveGoals() async {
    return await find(status: GoalStatus.active);
  }

  Future<List<SavingsGoal>> getCompletedGoals() async {
    return await find(status: GoalStatus.completed);
  }

  Future<List<SavingsGoal>> getGoalsByPriority(GoalPriority priority) async {
    return await find(priority: priority);
  }

  Future<List<SavingsGoal>> getAutoSaveGoals() async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT * FROM savings_goals WHERE user_id = ? AND is_auto_save = 1 AND status = ?",
      [userId, GoalStatus.active.index],
    );
    
    return result.map((data) => SavingsGoal.fromJson(data)).toList();
  }

  Future<int> addAmountToGoal(int goalId, double amount) async {
    final goal = await findById(goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    goal.addAmount(amount);
    return await update(goal);
  }

  Future<int> subtractAmountFromGoal(int goalId, double amount) async {
    final goal = await findById(goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    goal.subtractAmount(amount);
    return await update(goal);
  }

  Future<int> markGoalCompleted(int goalId) async {
    final goal = await findById(goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    goal.markCompleted();
    return await update(goal);
  }

  Future<int> pauseGoal(int goalId) async {
    final goal = await findById(goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    goal.pause();
    return await update(goal);
  }

  Future<int> resumeGoal(int goalId) async {
    final goal = await findById(goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    goal.resume();
    return await update(goal);
  }

  Future<int> cancelGoal(int goalId) async {
    final goal = await findById(goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    goal.cancel();
    return await update(goal);
  }

  Future<Map<String, dynamic>> getSavingsSummary() async {
    final goals = await find();
    
    double totalTargetAmount = 0;
    double totalCurrentAmount = 0;
    double totalRemaining = 0;
    int activeGoals = 0;
    int completedGoals = 0;
    
    for (final goal in goals) {
      totalTargetAmount += goal.targetAmount;
      totalCurrentAmount += goal.currentAmount;
      totalRemaining += goal.remainingAmount;
      
      if (goal.status == GoalStatus.active) {
        activeGoals++;
      } else if (goal.status == GoalStatus.completed) {
        completedGoals++;
      }
    }
    
    return {
      'totalTargetAmount': totalTargetAmount,
      'totalCurrentAmount': totalCurrentAmount,
      'totalRemaining': totalRemaining,
      'totalGoals': goals.length,
      'activeGoals': activeGoals,
      'completedGoals': completedGoals,
      'overallProgress': totalTargetAmount > 0 ? (totalCurrentAmount / totalTargetAmount) : 0.0,
      'goals': goals,
    };
  }

  Future<List<SavingsGoal>> getGoalsDueSoon({int days = 30}) async {
    final db = await getDBInstance();
    int? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final cutoffDate = DateTime.now().add(Duration(days: days));
    
    List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT * FROM savings_goals WHERE user_id = ? AND status = ? AND target_date <= ?",
      [userId, GoalStatus.active.index, cutoffDate.toIso8601String()],
    );
    
    return result.map((data) => SavingsGoal.fromJson(data)).toList();
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
      FROM savings_goals
      WHERE user_id = ?
      GROUP BY status
    """, [userId]);

    // Get counts by priority
    final priorityCounts = await db.rawQuery("""
      SELECT priority, COUNT(*) as count
      FROM savings_goals
      WHERE user_id = ? AND status = ?
      GROUP BY priority
    """, [userId, GoalStatus.active.index]);

    // Get auto-save goals count
    final autoSaveCount = await db.rawQuery("""
      SELECT COUNT(*) as count
      FROM savings_goals
      WHERE user_id = ? AND is_auto_save = 1 AND status = ?
    """, [userId, GoalStatus.active.index]);

    return {
      'statusCounts': statusCounts,
      'priorityCounts': priorityCounts,
      'autoSaveCount': autoSaveCount.first['count'] ?? 0,
    };
  }

  Future<int> executeAutoSave() async {
    final autoSaveGoals = await getAutoSaveGoals();
    int executedCount = 0;
    
    for (final goal in autoSaveGoals) {
      if (goal.isAutoSaveDue()) {
        goal.executeAutoSave();
        await update(goal);
        executedCount++;
      }
    }
    
    return executedCount;
  }
}

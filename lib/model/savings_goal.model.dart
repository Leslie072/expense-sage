import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum GoalStatus {
  active,
  completed,
  paused,
  cancelled,
}

enum GoalPriority {
  low,
  medium,
  high,
  urgent,
}

class SavingsGoal {
  int? id;
  String name;
  String description;
  double targetAmount;
  double currentAmount;
  DateTime targetDate;
  DateTime createdAt;
  DateTime updatedAt;
  GoalStatus status;
  GoalPriority priority;
  IconData icon;
  Color color;
  bool isAutoSave;
  double autoSaveAmount;
  String autoSaveFrequency; // daily, weekly, monthly
  DateTime? lastAutoSave;

  SavingsGoal({
    this.id,
    required this.name,
    required this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    required this.createdAt,
    required this.updatedAt,
    this.status = GoalStatus.active,
    this.priority = GoalPriority.medium,
    this.icon = Icons.savings,
    this.color = Colors.blue,
    this.isAutoSave = false,
    this.autoSaveAmount = 0.0,
    this.autoSaveFrequency = 'monthly',
    this.lastAutoSave,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> data) {
    return SavingsGoal(
      id: data["id"],
      name: data["name"] ?? "",
      description: data["description"] ?? "",
      targetAmount: data["target_amount"]?.toDouble() ?? 0.0,
      currentAmount: data["current_amount"]?.toDouble() ?? 0.0,
      targetDate: DateTime.parse(data["target_date"]),
      createdAt: DateTime.parse(data["created_at"]),
      updatedAt: DateTime.parse(data["updated_at"]),
      status: GoalStatus.values[data["status"] ?? 0],
      priority: GoalPriority.values[data["priority"] ?? 1],
      icon: IconData(data["icon"] ?? Icons.savings.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(data["color"] ?? Colors.blue.value),
      isAutoSave: data["is_auto_save"] == 1,
      autoSaveAmount: data["auto_save_amount"]?.toDouble() ?? 0.0,
      autoSaveFrequency: data["auto_save_frequency"] ?? 'monthly',
      lastAutoSave: data["last_auto_save"] != null ? DateTime.parse(data["last_auto_save"]) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "target_amount": targetAmount,
    "current_amount": currentAmount,
    "target_date": DateFormat('yyyy-MM-dd').format(targetDate),
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "status": status.index,
    "priority": priority.index,
    "icon": icon.codePoint,
    "color": color.value,
    "is_auto_save": isAutoSave ? 1 : 0,
    "auto_save_amount": autoSaveAmount,
    "auto_save_frequency": autoSaveFrequency,
    "last_auto_save": lastAutoSave?.toIso8601String(),
  };

  // Calculate progress percentage
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  // Calculate remaining amount
  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0.0, double.infinity);
  }

  // Calculate days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (targetDate.isBefore(now)) return 0;
    return targetDate.difference(now).inDays;
  }

  // Calculate required daily savings
  double get requiredDailySavings {
    if (daysRemaining <= 0) return remainingAmount;
    return remainingAmount / daysRemaining;
  }

  // Calculate required monthly savings
  double get requiredMonthlySavings {
    if (daysRemaining <= 0) return remainingAmount;
    final monthsRemaining = daysRemaining / 30.0;
    return remainingAmount / monthsRemaining;
  }

  // Check if goal is completed
  bool get isCompleted {
    return currentAmount >= targetAmount || status == GoalStatus.completed;
  }

  // Check if goal is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(targetDate) && !isCompleted;
  }

  // Get status description
  String get statusDescription {
    switch (status) {
      case GoalStatus.active:
        return 'Active';
      case GoalStatus.completed:
        return 'Completed';
      case GoalStatus.paused:
        return 'Paused';
      case GoalStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Get priority description
  String get priorityDescription {
    switch (priority) {
      case GoalPriority.low:
        return 'Low';
      case GoalPriority.medium:
        return 'Medium';
      case GoalPriority.high:
        return 'High';
      case GoalPriority.urgent:
        return 'Urgent';
    }
  }

  // Get priority color
  Color get priorityColor {
    switch (priority) {
      case GoalPriority.low:
        return Colors.green;
      case GoalPriority.medium:
        return Colors.blue;
      case GoalPriority.high:
        return Colors.orange;
      case GoalPriority.urgent:
        return Colors.red;
    }
  }

  // Add amount to goal
  void addAmount(double amount) {
    currentAmount += amount;
    updatedAt = DateTime.now();
    
    if (currentAmount >= targetAmount && status == GoalStatus.active) {
      status = GoalStatus.completed;
    }
  }

  // Subtract amount from goal
  void subtractAmount(double amount) {
    currentAmount = (currentAmount - amount).clamp(0.0, double.infinity);
    updatedAt = DateTime.now();
    
    if (status == GoalStatus.completed && currentAmount < targetAmount) {
      status = GoalStatus.active;
    }
  }

  // Mark as completed
  void markCompleted() {
    status = GoalStatus.completed;
    updatedAt = DateTime.now();
  }

  // Pause goal
  void pause() {
    if (status == GoalStatus.active) {
      status = GoalStatus.paused;
      updatedAt = DateTime.now();
    }
  }

  // Resume goal
  void resume() {
    if (status == GoalStatus.paused) {
      status = GoalStatus.active;
      updatedAt = DateTime.now();
    }
  }

  // Cancel goal
  void cancel() {
    status = GoalStatus.cancelled;
    updatedAt = DateTime.now();
  }

  // Check if auto-save is due
  bool isAutoSaveDue() {
    if (!isAutoSave || status != GoalStatus.active) return false;
    if (lastAutoSave == null) return true;
    
    final now = DateTime.now();
    switch (autoSaveFrequency) {
      case 'daily':
        return now.difference(lastAutoSave!).inDays >= 1;
      case 'weekly':
        return now.difference(lastAutoSave!).inDays >= 7;
      case 'monthly':
        return now.difference(lastAutoSave!).inDays >= 30;
      default:
        return false;
    }
  }

  // Execute auto-save
  void executeAutoSave() {
    if (isAutoSaveDue()) {
      addAmount(autoSaveAmount);
      lastAutoSave = DateTime.now();
    }
  }

  // Get estimated completion date based on current progress
  DateTime? getEstimatedCompletionDate() {
    if (isCompleted) return null;
    if (currentAmount <= 0) return null;
    
    final daysSinceStart = DateTime.now().difference(createdAt).inDays;
    if (daysSinceStart <= 0) return null;
    
    final dailyProgress = currentAmount / daysSinceStart;
    if (dailyProgress <= 0) return null;
    
    final remainingDays = remainingAmount / dailyProgress;
    return DateTime.now().add(Duration(days: remainingDays.ceil()));
  }

  // Copy with new values
  SavingsGoal copyWith({
    int? id,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    GoalStatus? status,
    GoalPriority? priority,
    IconData? icon,
    Color? color,
    bool? isAutoSave,
    double? autoSaveAmount,
    String? autoSaveFrequency,
    DateTime? lastAutoSave,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isAutoSave: isAutoSave ?? this.isAutoSave,
      autoSaveAmount: autoSaveAmount ?? this.autoSaveAmount,
      autoSaveFrequency: autoSaveFrequency ?? this.autoSaveFrequency,
      lastAutoSave: lastAutoSave ?? this.lastAutoSave,
    );
  }
}

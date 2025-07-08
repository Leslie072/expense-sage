import 'package:expense_sage/model/account.model.dart';
import 'package:expense_sage/model/category.model.dart';
import 'package:expense_sage/model/payment.model.dart';
import 'package:intl/intl.dart';

enum RecurrenceType {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
}

enum RecurrenceStatus {
  active,
  paused,
  completed,
  cancelled,
}

class RecurringTransaction {
  int? id;
  String title;
  String description;
  Account account;
  Category category;
  double amount;
  PaymentType type;
  RecurrenceType recurrenceType;
  RecurrenceStatus status;
  DateTime startDate;
  DateTime? endDate;
  DateTime? lastExecuted;
  DateTime? nextDue;
  int? maxOccurrences;
  int executedCount;
  bool isAutoExecute;
  DateTime createdAt;
  DateTime updatedAt;

  RecurringTransaction({
    this.id,
    required this.title,
    required this.description,
    required this.account,
    required this.category,
    required this.amount,
    required this.type,
    required this.recurrenceType,
    this.status = RecurrenceStatus.active,
    required this.startDate,
    this.endDate,
    this.lastExecuted,
    this.nextDue,
    this.maxOccurrences,
    this.executedCount = 0,
    this.isAutoExecute = false,
    required this.createdAt,
    required this.updatedAt,
  }) {
    nextDue ??= calculateNextDue();
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> data) {
    return RecurringTransaction(
      id: data["id"],
      title: data["title"] ?? "",
      description: data["description"] ?? "",
      account: Account.fromJson(data["account"]),
      category: Category.fromJson(data["category"]),
      amount: data["amount"]?.toDouble() ?? 0.0,
      type: data["type"] == "CR" ? PaymentType.credit : PaymentType.debit,
      recurrenceType: RecurrenceType.values[data["recurrence_type"] ?? 0],
      status: RecurrenceStatus.values[data["status"] ?? 0],
      startDate: DateTime.parse(data["start_date"]),
      endDate: data["end_date"] != null ? DateTime.parse(data["end_date"]) : null,
      lastExecuted: data["last_executed"] != null ? DateTime.parse(data["last_executed"]) : null,
      nextDue: data["next_due"] != null ? DateTime.parse(data["next_due"]) : null,
      maxOccurrences: data["max_occurrences"],
      executedCount: data["executed_count"] ?? 0,
      isAutoExecute: data["is_auto_execute"] == 1,
      createdAt: DateTime.parse(data["created_at"]),
      updatedAt: DateTime.parse(data["updated_at"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
    "account": account.id,
    "category": category.id,
    "amount": amount,
    "type": type == PaymentType.credit ? "CR" : "DR",
    "recurrence_type": recurrenceType.index,
    "status": status.index,
    "start_date": DateFormat('yyyy-MM-dd').format(startDate),
    "end_date": endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
    "last_executed": lastExecuted != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(lastExecuted!) : null,
    "next_due": nextDue != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(nextDue!) : null,
    "max_occurrences": maxOccurrences,
    "executed_count": executedCount,
    "is_auto_execute": isAutoExecute ? 1 : 0,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };

  DateTime calculateNextDue() {
    DateTime baseDate = lastExecuted ?? startDate;
    
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return baseDate.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        return baseDate.add(const Duration(days: 7));
      case RecurrenceType.biweekly:
        return baseDate.add(const Duration(days: 14));
      case RecurrenceType.monthly:
        return DateTime(baseDate.year, baseDate.month + 1, baseDate.day);
      case RecurrenceType.quarterly:
        return DateTime(baseDate.year, baseDate.month + 3, baseDate.day);
      case RecurrenceType.yearly:
        return DateTime(baseDate.year + 1, baseDate.month, baseDate.day);
    }
  }

  bool isDue() {
    if (status != RecurrenceStatus.active) return false;
    if (nextDue == null) return false;
    
    return DateTime.now().isAfter(nextDue!) || DateTime.now().isAtSameMomentAs(nextDue!);
  }

  bool isCompleted() {
    if (maxOccurrences != null && executedCount >= maxOccurrences!) {
      return true;
    }
    if (endDate != null && DateTime.now().isAfter(endDate!)) {
      return true;
    }
    return false;
  }

  String getRecurrenceDescription() {
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.biweekly:
        return 'Every 2 weeks';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.quarterly:
        return 'Quarterly';
      case RecurrenceType.yearly:
        return 'Yearly';
    }
  }

  String getStatusDescription() {
    switch (status) {
      case RecurrenceStatus.active:
        return 'Active';
      case RecurrenceStatus.paused:
        return 'Paused';
      case RecurrenceStatus.completed:
        return 'Completed';
      case RecurrenceStatus.cancelled:
        return 'Cancelled';
    }
  }

  Payment createPayment() {
    return Payment(
      account: account,
      category: category,
      amount: amount,
      type: type,
      datetime: DateTime.now(),
      title: title,
      description: '$description (Recurring)',
    );
  }

  RecurringTransaction copyWith({
    int? id,
    String? title,
    String? description,
    Account? account,
    Category? category,
    double? amount,
    PaymentType? type,
    RecurrenceType? recurrenceType,
    RecurrenceStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastExecuted,
    DateTime? nextDue,
    int? maxOccurrences,
    int? executedCount,
    bool? isAutoExecute,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      account: account ?? this.account,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      nextDue: nextDue ?? this.nextDue,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      executedCount: executedCount ?? this.executedCount,
      isAutoExecute: isAutoExecute ?? this.isAutoExecute,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  void markAsExecuted() {
    lastExecuted = DateTime.now();
    executedCount++;
    nextDue = calculateNextDue();
    updatedAt = DateTime.now();
    
    if (isCompleted()) {
      status = RecurrenceStatus.completed;
    }
  }

  void pause() {
    status = RecurrenceStatus.paused;
    updatedAt = DateTime.now();
  }

  void resume() {
    if (status == RecurrenceStatus.paused) {
      status = RecurrenceStatus.active;
      nextDue = calculateNextDue();
      updatedAt = DateTime.now();
    }
  }

  void cancel() {
    status = RecurrenceStatus.cancelled;
    updatedAt = DateTime.now();
  }
}

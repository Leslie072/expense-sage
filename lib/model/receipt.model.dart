import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ReceiptStatus {
  pending,
  processed,
  verified,
  archived,
}

class ReceiptItem {
  final String name;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String? category;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.category,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] ?? '',
      quantity: json['quantity']?.toDouble() ?? 1.0,
      unitPrice: json['unitPrice']?.toDouble() ?? 0.0,
      totalPrice: json['totalPrice']?.toDouble() ?? 0.0,
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'category': category,
    };
  }
}

class Receipt {
  int? id;
  String merchantName;
  String merchantAddress;
  DateTime transactionDate;
  double totalAmount;
  double taxAmount;
  double subtotalAmount;
  String currency;
  String receiptNumber;
  String imagePath;
  String? ocrText;
  List<ReceiptItem> items;
  ReceiptStatus status;
  DateTime createdAt;
  DateTime updatedAt;
  int? paymentId; // Link to payment transaction
  Map<String, dynamic>? metadata;

  Receipt({
    this.id,
    required this.merchantName,
    this.merchantAddress = '',
    required this.transactionDate,
    required this.totalAmount,
    this.taxAmount = 0.0,
    this.subtotalAmount = 0.0,
    this.currency = 'USD',
    this.receiptNumber = '',
    required this.imagePath,
    this.ocrText,
    this.items = const [],
    this.status = ReceiptStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.paymentId,
    this.metadata,
  });

  factory Receipt.fromJson(Map<String, dynamic> data) {
    List<ReceiptItem> items = [];
    if (data['items'] != null) {
      final itemsJson = data['items'] is String
          ? List<Map<String, dynamic>>.from(
              (data['items'] as String).split('|').map((item) => {
                    'name': item.split(':')[0],
                    'totalPrice':
                        double.tryParse(item.split(':')[1] ?? '0') ?? 0.0,
                    'quantity': 1.0,
                    'unitPrice':
                        double.tryParse(item.split(':')[1] ?? '0') ?? 0.0,
                  }))
          : List<Map<String, dynamic>>.from(data['items']);

      items = itemsJson.map((item) => ReceiptItem.fromJson(item)).toList();
    }

    return Receipt(
      id: data["id"],
      merchantName: data["merchant_name"] ?? "",
      merchantAddress: data["merchant_address"] ?? "",
      transactionDate: DateTime.parse(data["transaction_date"]),
      totalAmount: data["total_amount"]?.toDouble() ?? 0.0,
      taxAmount: data["tax_amount"]?.toDouble() ?? 0.0,
      subtotalAmount: data["subtotal_amount"]?.toDouble() ?? 0.0,
      currency: data["currency"] ?? "USD",
      receiptNumber: data["receipt_number"] ?? "",
      imagePath: data["image_path"] ?? "",
      ocrText: data["ocr_text"],
      items: items,
      status: ReceiptStatus.values[data["status"] ?? 0],
      createdAt: DateTime.parse(data["created_at"]),
      updatedAt: DateTime.parse(data["updated_at"]),
      paymentId: data["payment_id"],
      metadata: data["metadata"] != null
          ? Map<String, dynamic>.from(data["metadata"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "merchant_name": merchantName,
        "merchant_address": merchantAddress,
        "transaction_date":
            DateFormat('yyyy-MM-dd HH:mm:ss').format(transactionDate),
        "total_amount": totalAmount,
        "tax_amount": taxAmount,
        "subtotal_amount": subtotalAmount,
        "currency": currency,
        "receipt_number": receiptNumber,
        "image_path": imagePath,
        "ocr_text": ocrText,
        "items": items.map((item) => item.toJson()).toList(),
        "status": status.index,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "payment_id": paymentId,
        "metadata": metadata,
      };

  // Get status description
  String get statusDescription {
    switch (status) {
      case ReceiptStatus.pending:
        return 'Pending';
      case ReceiptStatus.processed:
        return 'Processed';
      case ReceiptStatus.verified:
        return 'Verified';
      case ReceiptStatus.archived:
        return 'Archived';
    }
  }

  // Get status color
  Color get statusColor {
    switch (status) {
      case ReceiptStatus.pending:
        return Colors.orange;
      case ReceiptStatus.processed:
        return Colors.blue;
      case ReceiptStatus.verified:
        return Colors.green;
      case ReceiptStatus.archived:
        return Colors.grey;
    }
  }

  // Get status icon
  IconData get statusIcon {
    switch (status) {
      case ReceiptStatus.pending:
        return Icons.pending;
      case ReceiptStatus.processed:
        return Icons.check_circle;
      case ReceiptStatus.verified:
        return Icons.verified;
      case ReceiptStatus.archived:
        return Icons.archive;
    }
  }

  // Calculate subtotal from items
  double get calculatedSubtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Calculate tax percentage
  double get taxPercentage {
    if (subtotalAmount <= 0) return 0.0;
    return (taxAmount / subtotalAmount) * 100;
  }

  // Check if receipt data is complete
  bool get isComplete {
    return merchantName.isNotEmpty && totalAmount > 0 && imagePath.isNotEmpty;
  }

  // Check if receipt needs review
  bool get needsReview {
    return status == ReceiptStatus.pending ||
        (ocrText != null && ocrText!.isNotEmpty && items.isEmpty);
  }

  // Update status
  void updateStatus(ReceiptStatus newStatus) {
    status = newStatus;
    updatedAt = DateTime.now();
  }

  // Add item
  void addItem(ReceiptItem item) {
    items = [...items, item];
    updatedAt = DateTime.now();
  }

  // Remove item
  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items = [...items]..removeAt(index);
      updatedAt = DateTime.now();
    }
  }

  // Update item
  void updateItem(int index, ReceiptItem item) {
    if (index >= 0 && index < items.length) {
      items = [...items]..[index] = item;
      updatedAt = DateTime.now();
    }
  }

  // Link to payment
  void linkToPayment(int paymentId) {
    this.paymentId = paymentId;
    status = ReceiptStatus.verified;
    updatedAt = DateTime.now();
  }

  // Unlink from payment
  void unlinkFromPayment() {
    paymentId = null;
    status = ReceiptStatus.processed;
    updatedAt = DateTime.now();
  }

  // Archive receipt
  void archive() {
    status = ReceiptStatus.archived;
    updatedAt = DateTime.now();
  }

  // Restore from archive
  void restore() {
    status =
        paymentId != null ? ReceiptStatus.verified : ReceiptStatus.processed;
    updatedAt = DateTime.now();
  }

  // Copy with new values
  Receipt copyWith({
    int? id,
    String? merchantName,
    String? merchantAddress,
    DateTime? transactionDate,
    double? totalAmount,
    double? taxAmount,
    double? subtotalAmount,
    String? currency,
    String? receiptNumber,
    String? imagePath,
    String? ocrText,
    List<ReceiptItem>? items,
    ReceiptStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? paymentId,
    Map<String, dynamic>? metadata,
  }) {
    return Receipt(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      merchantAddress: merchantAddress ?? this.merchantAddress,
      transactionDate: transactionDate ?? this.transactionDate,
      totalAmount: totalAmount ?? this.totalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      currency: currency ?? this.currency,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      imagePath: imagePath ?? this.imagePath,
      ocrText: ocrText ?? this.ocrText,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentId: paymentId ?? this.paymentId,
      metadata: metadata ?? this.metadata,
    );
  }
}

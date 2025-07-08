import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum InvestmentType {
  stock,
  bond,
  mutualFund,
  etf,
  cryptocurrency,
  realEstate,
  commodity,
  other,
}

enum InvestmentStatus {
  active,
  sold,
  suspended,
}

class Investment {
  int? id;
  String symbol;
  String name;
  InvestmentType type;
  double quantity;
  double purchasePrice;
  double currentPrice;
  DateTime purchaseDate;
  DateTime? saleDate;
  double? salePrice;
  InvestmentStatus status;
  String currency;
  String exchange;
  String sector;
  String description;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? lastPriceUpdate;

  Investment({
    this.id,
    required this.symbol,
    required this.name,
    required this.type,
    required this.quantity,
    required this.purchasePrice,
    this.currentPrice = 0.0,
    required this.purchaseDate,
    this.saleDate,
    this.salePrice,
    this.status = InvestmentStatus.active,
    this.currency = 'USD',
    this.exchange = '',
    this.sector = '',
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    this.lastPriceUpdate,
  });

  factory Investment.fromJson(Map<String, dynamic> data) {
    return Investment(
      id: data["id"],
      symbol: data["symbol"] ?? "",
      name: data["name"] ?? "",
      type: InvestmentType.values[data["type"] ?? 0],
      quantity: data["quantity"]?.toDouble() ?? 0.0,
      purchasePrice: data["purchase_price"]?.toDouble() ?? 0.0,
      currentPrice: data["current_price"]?.toDouble() ?? 0.0,
      purchaseDate: DateTime.parse(data["purchase_date"]),
      saleDate: data["sale_date"] != null ? DateTime.parse(data["sale_date"]) : null,
      salePrice: data["sale_price"]?.toDouble(),
      status: InvestmentStatus.values[data["status"] ?? 0],
      currency: data["currency"] ?? "USD",
      exchange: data["exchange"] ?? "",
      sector: data["sector"] ?? "",
      description: data["description"] ?? "",
      createdAt: DateTime.parse(data["created_at"]),
      updatedAt: DateTime.parse(data["updated_at"]),
      lastPriceUpdate: data["last_price_update"] != null 
          ? DateTime.parse(data["last_price_update"]) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "symbol": symbol,
    "name": name,
    "type": type.index,
    "quantity": quantity,
    "purchase_price": purchasePrice,
    "current_price": currentPrice,
    "purchase_date": DateFormat('yyyy-MM-dd').format(purchaseDate),
    "sale_date": saleDate != null ? DateFormat('yyyy-MM-dd').format(saleDate!) : null,
    "sale_price": salePrice,
    "status": status.index,
    "currency": currency,
    "exchange": exchange,
    "sector": sector,
    "description": description,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "last_price_update": lastPriceUpdate?.toIso8601String(),
  };

  // Calculate total purchase value
  double get totalPurchaseValue {
    return quantity * purchasePrice;
  }

  // Calculate current market value
  double get currentMarketValue {
    return quantity * currentPrice;
  }

  // Calculate unrealized gain/loss
  double get unrealizedGainLoss {
    if (status != InvestmentStatus.active) return 0.0;
    return currentMarketValue - totalPurchaseValue;
  }

  // Calculate realized gain/loss (for sold investments)
  double get realizedGainLoss {
    if (status != InvestmentStatus.sold || salePrice == null) return 0.0;
    return (salePrice! * quantity) - totalPurchaseValue;
  }

  // Calculate total gain/loss
  double get totalGainLoss {
    return status == InvestmentStatus.sold ? realizedGainLoss : unrealizedGainLoss;
  }

  // Calculate gain/loss percentage
  double get gainLossPercentage {
    if (totalPurchaseValue <= 0) return 0.0;
    return (totalGainLoss / totalPurchaseValue) * 100;
  }

  // Calculate daily change
  double get dailyChange {
    // This would typically be calculated from previous day's price
    // For now, we'll return 0 as we don't have historical data
    return 0.0;
  }

  // Calculate daily change percentage
  double get dailyChangePercentage {
    if (currentPrice <= 0) return 0.0;
    return (dailyChange / currentPrice) * 100;
  }

  // Get investment type description
  String get typeDescription {
    switch (type) {
      case InvestmentType.stock:
        return 'Stock';
      case InvestmentType.bond:
        return 'Bond';
      case InvestmentType.mutualFund:
        return 'Mutual Fund';
      case InvestmentType.etf:
        return 'ETF';
      case InvestmentType.cryptocurrency:
        return 'Cryptocurrency';
      case InvestmentType.realEstate:
        return 'Real Estate';
      case InvestmentType.commodity:
        return 'Commodity';
      case InvestmentType.other:
        return 'Other';
    }
  }

  // Get status description
  String get statusDescription {
    switch (status) {
      case InvestmentStatus.active:
        return 'Active';
      case InvestmentStatus.sold:
        return 'Sold';
      case InvestmentStatus.suspended:
        return 'Suspended';
    }
  }

  // Get status color
  Color get statusColor {
    switch (status) {
      case InvestmentStatus.active:
        return Colors.green;
      case InvestmentStatus.sold:
        return Colors.grey;
      case InvestmentStatus.suspended:
        return Colors.orange;
    }
  }

  // Get gain/loss color
  Color get gainLossColor {
    if (totalGainLoss > 0) return Colors.green;
    if (totalGainLoss < 0) return Colors.red;
    return Colors.grey;
  }

  // Get investment type icon
  IconData get typeIcon {
    switch (type) {
      case InvestmentType.stock:
        return Icons.trending_up;
      case InvestmentType.bond:
        return Icons.account_balance;
      case InvestmentType.mutualFund:
        return Icons.pie_chart;
      case InvestmentType.etf:
        return Icons.bar_chart;
      case InvestmentType.cryptocurrency:
        return Icons.currency_bitcoin;
      case InvestmentType.realEstate:
        return Icons.home;
      case InvestmentType.commodity:
        return Icons.grain;
      case InvestmentType.other:
        return Icons.business;
    }
  }

  // Check if price data is stale
  bool get isPriceStale {
    if (lastPriceUpdate == null) return true;
    final now = DateTime.now();
    final difference = now.difference(lastPriceUpdate!);
    
    // Consider price stale if it's older than 1 hour during market hours
    // or 1 day outside market hours
    return difference.inHours > 1;
  }

  // Update current price
  void updatePrice(double newPrice) {
    currentPrice = newPrice;
    lastPriceUpdate = DateTime.now();
    updatedAt = DateTime.now();
  }

  // Sell investment
  void sell(double salePrice, DateTime saleDate) {
    this.salePrice = salePrice;
    this.saleDate = saleDate;
    status = InvestmentStatus.sold;
    updatedAt = DateTime.now();
  }

  // Suspend investment
  void suspend() {
    status = InvestmentStatus.suspended;
    updatedAt = DateTime.now();
  }

  // Reactivate investment
  void reactivate() {
    if (status == InvestmentStatus.suspended) {
      status = InvestmentStatus.active;
      updatedAt = DateTime.now();
    }
  }

  // Add more shares/units
  void addShares(double additionalQuantity, double additionalPrice) {
    final totalValue = totalPurchaseValue + (additionalQuantity * additionalPrice);
    final totalQuantity = quantity + additionalQuantity;
    
    quantity = totalQuantity;
    purchasePrice = totalValue / totalQuantity; // Average price
    updatedAt = DateTime.now();
  }

  // Sell partial shares/units
  void sellPartial(double quantityToSell, double salePrice) {
    if (quantityToSell >= quantity) {
      sell(salePrice, DateTime.now());
    } else {
      quantity -= quantityToSell;
      updatedAt = DateTime.now();
      
      // Note: This doesn't track the partial sale gain/loss
      // In a real app, you'd want to create a separate transaction record
    }
  }

  // Get holding period in days
  int get holdingPeriodDays {
    final endDate = saleDate ?? DateTime.now();
    return endDate.difference(purchaseDate).inDays;
  }

  // Check if it's a long-term investment (>1 year)
  bool get isLongTerm {
    return holdingPeriodDays > 365;
  }

  // Copy with new values
  Investment copyWith({
    int? id,
    String? symbol,
    String? name,
    InvestmentType? type,
    double? quantity,
    double? purchasePrice,
    double? currentPrice,
    DateTime? purchaseDate,
    DateTime? saleDate,
    double? salePrice,
    InvestmentStatus? status,
    String? currency,
    String? exchange,
    String? sector,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastPriceUpdate,
  }) {
    return Investment(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      saleDate: saleDate ?? this.saleDate,
      salePrice: salePrice ?? this.salePrice,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      exchange: exchange ?? this.exchange,
      sector: sector ?? this.sector,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastPriceUpdate: lastPriceUpdate ?? this.lastPriceUpdate,
    );
  }
}

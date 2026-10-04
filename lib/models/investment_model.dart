import 'package:flutter/material.dart';

enum InvestmentType {
  mutualFund,
  stocks,
  gold,
  silver,
  fixedDeposit,
  recurringDeposit,
  ppf,
  crypto,
  other,
}

extension InvestmentTypeExt on InvestmentType {
  String get label {
    switch (this) {
      case InvestmentType.mutualFund:
        return 'Mutual Fund';
      case InvestmentType.stocks:
        return 'Stocks';
      case InvestmentType.gold:
        return 'Gold';
      case InvestmentType.silver:
        return 'Silver';
      case InvestmentType.fixedDeposit:
        return 'Fixed Deposit';
      case InvestmentType.recurringDeposit:
        return 'Recurring Deposit';
      case InvestmentType.ppf:
        return 'PPF';
      case InvestmentType.crypto:
        return 'Crypto';
      case InvestmentType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case InvestmentType.mutualFund:
        return 'chart';
      case InvestmentType.stocks:
        return 'trending_up';
      case InvestmentType.gold:
        return 'award';
      case InvestmentType.silver:
        return 'award';
      case InvestmentType.fixedDeposit:
        return 'bank';
      case InvestmentType.recurringDeposit:
        return 'refresh';
      case InvestmentType.ppf:
        return 'bank';
      case InvestmentType.crypto:
        return 'crypto';
      case InvestmentType.other:
        return 'work';
    }
  }

  IconData get iconData {
    switch (this) {
      case InvestmentType.mutualFund:
        return Icons.bar_chart_rounded;
      case InvestmentType.stocks:
        return Icons.trending_up_rounded;
      case InvestmentType.gold:
        return Icons.emoji_events_rounded;
      case InvestmentType.silver:
        return Icons.emoji_events_rounded;
      case InvestmentType.fixedDeposit:
        return Icons.account_balance_rounded;
      case InvestmentType.recurringDeposit:
        return Icons.refresh_rounded;
      case InvestmentType.ppf:
        return Icons.account_balance_wallet_rounded;
      case InvestmentType.crypto:
        return Icons.currency_bitcoin_rounded;
      case InvestmentType.other:
        return Icons.work_rounded;
    }
  }

  int get color {
    switch (this) {
      case InvestmentType.mutualFund:
        return 0xFF654CFF;
      case InvestmentType.stocks:
        return 0xFF2ECC71;
      case InvestmentType.gold:
        return 0xFFF39C12;
      case InvestmentType.silver:
        return 0xFFBDC3C7;
      case InvestmentType.fixedDeposit:
        return 0xFF3498DB;
      case InvestmentType.recurringDeposit:
        return 0xFF1ABC9C;
      case InvestmentType.ppf:
        return 0xFF9B59B6;
      case InvestmentType.crypto:
        return 0xFFE91E63;
      case InvestmentType.other:
        return 0xFF95A5A6;
    }
  }

  String get key => name;

  static InvestmentType fromKey(String key) {
    return InvestmentType.values.firstWhere(
      (e) => e.name == key,
      orElse: () => InvestmentType.other,
    );
  }
}

class InvestmentModel {
  final String id;
  final String name;
  final InvestmentType type;
  final double investedAmount;
  final double currentValue;
  final double? units;
  final double? buyPrice; // per unit
  final double? currentPrice; // per unit
  final DateTime startDate;
  final String? note;
  final DateTime createdAt;

  const InvestmentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.investedAmount,
    required this.currentValue,
    this.units,
    this.buyPrice,
    this.currentPrice,
    required this.startDate,
    this.note,
    required this.createdAt,
  });

  double get returnAmount => currentValue - investedAmount;
  double get returnPercent =>
      investedAmount > 0 ? (returnAmount / investedAmount) * 100 : 0;
  bool get isProfit => returnAmount >= 0;

  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: InvestmentTypeExt.fromKey(map['type'] as String),
      investedAmount: (map['invested_amount'] as num).toDouble(),
      currentValue: (map['current_value'] as num).toDouble(),
      units: map['units'] != null ? (map['units'] as num).toDouble() : null,
      buyPrice: map['buy_price'] != null
          ? (map['buy_price'] as num).toDouble()
          : null,
      currentPrice: map['current_price'] != null
          ? (map['current_price'] as num).toDouble()
          : null,
      startDate: DateTime.parse(map['start_date'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.key,
      'invested_amount': investedAmount,
      'current_value': currentValue,
      'units': units,
      'buy_price': buyPrice,
      'current_price': currentPrice,
      'start_date': startDate.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  InvestmentModel copyWith({
    String? name,
    InvestmentType? type,
    double? investedAmount,
    double? currentValue,
    double? units,
    double? buyPrice,
    double? currentPrice,
    DateTime? startDate,
    String? note,
  }) {
    return InvestmentModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      investedAmount: investedAmount ?? this.investedAmount,
      currentValue: currentValue ?? this.currentValue,
      units: units ?? this.units,
      buyPrice: buyPrice ?? this.buyPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      startDate: startDate ?? this.startDate,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }
}

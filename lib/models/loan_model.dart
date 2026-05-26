import 'package:flutter/material.dart';

enum LoanType {
  overdraft,
  unsecured,
  secured,
  carLoan,
  goldLoan,
  homeLoan,
  educationLoan,
  other,
}

extension LoanTypeExt on LoanType {
  String get label {
    switch (this) {
      case LoanType.overdraft:
        return 'Overdraft (OD)';
      case LoanType.unsecured:
        return 'Unsecured Loan';
      case LoanType.secured:
        return 'Secured Loan';
      case LoanType.carLoan:
        return 'Car Loan';
      case LoanType.goldLoan:
        return 'Gold Loan';
      case LoanType.homeLoan:
        return 'Home Loan';
      case LoanType.educationLoan:
        return 'Education Loan';
      case LoanType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case LoanType.overdraft:
        return 'atm';
      case LoanType.unsecured:
        return 'assignment';
      case LoanType.secured:
        return 'lock';
      case LoanType.carLoan:
        return 'car';
      case LoanType.goldLoan:
        return 'award';
      case LoanType.homeLoan:
        return 'home';
      case LoanType.educationLoan:
        return 'school';
      case LoanType.other:
        return 'card';
    }
  }

  IconData get iconData {
    switch (this) {
      case LoanType.overdraft:
        return Icons.atm_rounded;
      case LoanType.unsecured:
        return Icons.assignment_rounded;
      case LoanType.secured:
        return Icons.lock_rounded;
      case LoanType.carLoan:
        return Icons.directions_car_rounded;
      case LoanType.goldLoan:
        return Icons.emoji_events_rounded;
      case LoanType.homeLoan:
        return Icons.home_rounded;
      case LoanType.educationLoan:
        return Icons.school_rounded;
      case LoanType.other:
        return Icons.credit_card_rounded;
    }
  }

  int get color {
    switch (this) {
      case LoanType.overdraft:
        return 0xFFE74C3C;
      case LoanType.unsecured:
        return 0xFFFF6B6B;
      case LoanType.secured:
        return 0xFF3498DB;
      case LoanType.carLoan:
        return 0xFF4ECDC4;
      case LoanType.goldLoan:
        return 0xFFF39C12;
      case LoanType.homeLoan:
        return 0xFF9B59B6;
      case LoanType.educationLoan:
        return 0xFFFF8C42;
      case LoanType.other:
        return 0xFF95A5A6;
    }
  }

  String get key => name;

  static LoanType fromKey(String key) {
    return LoanType.values.firstWhere(
      (e) => e.name == key,
      orElse: () => LoanType.other,
    );
  }
}

class LoanModel {
  final String id;
  final String name;
  final LoanType type;
  final double principalAmount;
  final double outstandingAmount;
  final double interestRate;
  final int tenureMonths;
  final double emiAmount;
  final int emiDay; // day of month EMI is due
  final DateTime startDate;
  final DateTime? endDate;
  final String? accountId; // linked account for auto-debit
  final bool autoEmi; // auto-add EMI as expense transaction
  final String? note;
  final DateTime createdAt;

  const LoanModel({
    required this.id,
    required this.name,
    required this.type,
    required this.principalAmount,
    required this.outstandingAmount,
    required this.interestRate,
    required this.tenureMonths,
    required this.emiAmount,
    required this.emiDay,
    required this.startDate,
    this.endDate,
    this.accountId,
    this.autoEmi = true,
    this.note,
    required this.createdAt,
  });

  double get totalPaid => principalAmount - outstandingAmount;
  double get progressPercent =>
      principalAmount > 0 ? (totalPaid / principalAmount).clamp(0.0, 1.0) : 0;
  int get remainingMonths {
    if (emiAmount <= 0) return 0;
    return (outstandingAmount / emiAmount).ceil();
  }

  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: LoanTypeExt.fromKey(map['type'] as String),
      principalAmount: (map['principal_amount'] as num).toDouble(),
      outstandingAmount: (map['outstanding_amount'] as num).toDouble(),
      interestRate: (map['interest_rate'] as num).toDouble(),
      tenureMonths: map['tenure_months'] as int,
      emiAmount: (map['emi_amount'] as num).toDouble(),
      emiDay: map['emi_day'] as int,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      accountId: map['account_id'] as String?,
      autoEmi: (map['auto_emi'] as int) == 1,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.key,
      'principal_amount': principalAmount,
      'outstanding_amount': outstandingAmount,
      'interest_rate': interestRate,
      'tenure_months': tenureMonths,
      'emi_amount': emiAmount,
      'emi_day': emiDay,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'account_id': accountId,
      'auto_emi': autoEmi ? 1 : 0,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LoanModel copyWith({
    String? name,
    LoanType? type,
    double? principalAmount,
    double? outstandingAmount,
    double? interestRate,
    int? tenureMonths,
    double? emiAmount,
    int? emiDay,
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
    bool? autoEmi,
    String? note,
  }) {
    return LoanModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      principalAmount: principalAmount ?? this.principalAmount,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      interestRate: interestRate ?? this.interestRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      emiAmount: emiAmount ?? this.emiAmount,
      emiDay: emiDay ?? this.emiDay,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      accountId: accountId ?? this.accountId,
      autoEmi: autoEmi ?? this.autoEmi,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }
}

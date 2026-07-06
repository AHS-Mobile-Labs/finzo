import 'dart:convert';

import 'transaction_split_model.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String type; // 'income', 'expense', or 'transfer'
  final String categoryId;
  final String accountId;
  final String? relatedAccountId;
  final DateTime date;
  final String? note;
  final String? paymentMethod;
  final List<String> tags;
  final String? receiptPath;
  final String trackingStatus; // 'normal', 'refund', or 'reimbursement'
  final List<TransactionSplitModel> splits;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    this.relatedAccountId,
    required this.date,
    this.note,
    this.paymentMethod,
    this.tags = const [],
    this.receiptPath,
    this.trackingStatus = 'normal',
    this.splits = const [],
    required this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      categoryId: map['category_id'] as String,
      accountId: map['account_id'] as String,
      relatedAccountId: map['related_account_id'] as String?,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      paymentMethod: map['payment_method'] as String?,
      tags: _decodeTags(map['tags']),
      receiptPath: map['receipt_path'] as String?,
      trackingStatus: (map['tracking_status'] as String?) ?? 'normal',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  TransactionModel withSplits(List<TransactionSplitModel> value) {
    return copyWith(splits: value);
  }

  bool get hasSplits => splits.isNotEmpty;

  double get splitTotal => splits.fold(0.0, (sum, split) => sum + split.amount);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'account_id': accountId,
      'related_account_id': relatedAccountId,
      'date': date.toIso8601String(),
      'note': note,
      'payment_method': paymentMethod,
      'tags': _encodeTags(tags),
      'receipt_path': receiptPath,
      'tracking_status': trackingStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static List<String> _decodeTags(dynamic value) {
    if (value == null) return const [];
    final raw = value.toString().trim();
    if (raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((tag) => tag.toString().trim())
            .where((tag) => tag.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // Older local builds may have comma-separated tags.
    }

    return raw
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  static String? _encodeTags(List<String> tags) {
    final cleaned = tags.map((tag) => tag.trim()).where((tag) {
      return tag.isNotEmpty;
    }).toList();
    return cleaned.isEmpty ? null : jsonEncode(cleaned);
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? type,
    String? categoryId,
    String? accountId,
    String? relatedAccountId,
    DateTime? date,
    String? note,
    String? paymentMethod,
    List<String>? tags,
    String? receiptPath,
    String? trackingStatus,
    List<TransactionSplitModel>? splits,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      relatedAccountId: relatedAccountId ?? this.relatedAccountId,
      date: date ?? this.date,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tags: tags ?? this.tags,
      receiptPath: receiptPath ?? this.receiptPath,
      trackingStatus: trackingStatus ?? this.trackingStatus,
      splits: splits ?? this.splits,
      createdAt: createdAt,
    );
  }
}

class TransactionPaymentMethod {
  static const cash = 'cash';
  static const upi = 'upi';
  static const card = 'card';
  static const bank = 'bank';

  static const values = [cash, upi, card, bank];

  static String label(String? value) {
    return switch (value) {
      upi => 'UPI',
      card => 'Card',
      bank => 'Bank',
      _ => 'Cash',
    };
  }
}

class TransactionTrackingStatus {
  static const normal = 'normal';
  static const refund = 'refund';
  static const reimbursement = 'reimbursement';

  static const values = [normal, refund, reimbursement];

  static String label(String value) {
    return switch (value) {
      refund => 'Refund',
      reimbursement => 'Reimbursement',
      _ => 'Normal',
    };
  }
}

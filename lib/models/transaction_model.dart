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
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

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
      'created_at': createdAt.toIso8601String(),
    };
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
      createdAt: createdAt,
    );
  }
}

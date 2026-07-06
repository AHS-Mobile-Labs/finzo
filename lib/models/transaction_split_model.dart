class TransactionSplitModel {
  final String id;
  final String transactionId;
  final String categoryId;
  final double amount;

  const TransactionSplitModel({
    required this.id,
    required this.transactionId,
    required this.categoryId,
    required this.amount,
  });

  factory TransactionSplitModel.fromMap(Map<String, dynamic> map) {
    return TransactionSplitModel(
      id: map['id'] as String,
      transactionId: map['transaction_id'] as String,
      categoryId: map['category_id'] as String,
      amount: (map['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'category_id': categoryId,
      'amount': amount,
    };
  }

  TransactionSplitModel copyWith({
    String? id,
    String? transactionId,
    String? categoryId,
    double? amount,
  }) {
    return TransactionSplitModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
    );
  }
}

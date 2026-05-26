class CreditCardModel {
  final String id;
  final String name;
  final String last4;
  final double creditLimit;
  final double usedAmount;
  final int billingDay;
  final int dueDay;
  final int color;
  final String icon;
  final String? note;
  final DateTime createdAt;

  const CreditCardModel({
    required this.id,
    required this.name,
    required this.last4,
    required this.creditLimit,
    required this.usedAmount,
    required this.billingDay,
    required this.dueDay,
    required this.color,
    this.icon = 'card',
    this.note,
    required this.createdAt,
  });

  double get availableLimit => creditLimit - usedAmount;
  double get usedPercent =>
      creditLimit > 0 ? (usedAmount / creditLimit).clamp(0.0, 1.0) : 0;
  bool get isHighUtilization => usedPercent > 0.7;

  factory CreditCardModel.fromMap(Map<String, dynamic> map) {
    return CreditCardModel(
      id: map['id'] as String,
      name: map['name'] as String,
      last4: map['card_number_last4'] as String,
      creditLimit: (map['credit_limit'] as num).toDouble(),
      usedAmount: (map['used_amount'] as num).toDouble(),
      billingDay: map['billing_day'] as int,
      dueDay: map['due_day'] as int,
      color: map['color'] as int,
      icon: (map['icon'] as String?) ?? 'card',
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'card_number_last4': last4,
      'credit_limit': creditLimit,
      'used_amount': usedAmount,
      'billing_day': billingDay,
      'due_day': dueDay,
      'color': color,
      'icon': icon,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CreditCardModel copyWith({
    String? name,
    String? last4,
    double? creditLimit,
    double? usedAmount,
    int? billingDay,
    int? dueDay,
    int? color,
    String? icon,
    String? note,
  }) {
    return CreditCardModel(
      id: id,
      name: name ?? this.name,
      last4: last4 ?? this.last4,
      creditLimit: creditLimit ?? this.creditLimit,
      usedAmount: usedAmount ?? this.usedAmount,
      billingDay: billingDay ?? this.billingDay,
      dueDay: dueDay ?? this.dueDay,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }
}

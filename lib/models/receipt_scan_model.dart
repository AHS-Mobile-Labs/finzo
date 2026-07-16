class ReceiptScanResult {
  final String receiptPath;
  final String rawText;
  final List<String> lines;
  final ParsedReceiptFields fields;

  const ReceiptScanResult({
    required this.receiptPath,
    required this.rawText,
    required this.lines,
    required this.fields,
  });
}

class ParsedReceiptFields {
  final String? merchantName;
  final double? totalAmount;
  final DateTime? purchasedAt;
  final double? taxAmount;
  final List<ReceiptLineItem> items;

  const ParsedReceiptFields({
    this.merchantName,
    this.totalAmount,
    this.purchasedAt,
    this.taxAmount,
    this.items = const [],
  });
}

class ReceiptLineItem {
  final String name;
  final double? amount;

  const ReceiptLineItem({required this.name, this.amount});
}

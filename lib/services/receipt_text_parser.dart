import 'package:intl/intl.dart';

import '../models/receipt_scan_model.dart';

class ReceiptTextParser {
  ParsedReceiptFields parse(String text) {
    final lines = normaliseLines(text);
    return ParsedReceiptFields(
      merchantName: _extractMerchant(lines),
      totalAmount: _extractTotal(lines),
      purchasedAt: _extractDateTime(lines),
      taxAmount: _extractTax(lines),
      items: _extractItems(lines),
    );
  }

  static List<String> normaliseLines(String text) {
    return text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String? _extractMerchant(List<String> lines) {
    for (final line in lines.take(8)) {
      final lower = line.toLowerCase();
      if (line.length < 2) continue;
      if (!RegExp(r'[a-zA-Z]').hasMatch(line)) continue;
      if (_hasDate(line) || _isContactOrIdLine(lower)) continue;
      if (_isTotalsLine(lower) || _isPaymentLine(lower)) continue;
      if (RegExp(r'^\W*\d+[\d\s.,-]*$').hasMatch(line)) continue;

      return _cleanMerchant(line);
    }
    return null;
  }

  String _cleanMerchant(String value) {
    return value
        .replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9&().,\- ]+$'), '')
        .trim();
  }

  double? _extractTotal(List<String> lines) {
    const labelWeights = {
      'grand total': 120,
      'amount payable': 115,
      'net payable': 115,
      'total amount': 110,
      'invoice total': 105,
      'bill amount': 100,
      'balance due': 100,
      'total': 90,
    };

    final candidates = <_AmountCandidate>[];
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final lower = line.toLowerCase();
      if (_isContactOrIdLine(lower)) continue;

      final amounts = _amountsInLine(line);
      if (amounts.isEmpty) continue;

      var weight = 0;
      for (final entry in labelWeights.entries) {
        if (lower.contains(entry.key)) {
          weight = entry.value;
          break;
        }
      }

      if (lower.contains('sub total') || lower.contains('subtotal')) {
        weight -= 60;
      }
      if (_isTaxLine(lower)) weight -= 35;
      if (_isPaymentLine(lower)) weight -= 20;

      for (final amount in amounts) {
        if (amount <= 0) continue;
        candidates.add(
          _AmountCandidate(
            amount: amount,
            score: weight - (index * 0.3) + (amount > 0 ? 1 : 0),
          ),
        );
      }
    }

    final labelled = candidates.where((c) => c.score >= 70).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    if (labelled.isNotEmpty) return labelled.first.amount;

    final fallback = candidates.where((c) => c.amount < 10000000).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return fallback.isEmpty ? null : fallback.first.amount;
  }

  DateTime? _extractDateTime(List<String> lines) {
    for (final line in lines) {
      final parsed = _dateFromNumeric(line) ?? _dateFromMonthName(line);
      if (parsed == null) continue;
      final time = _timeFromLine(line);
      if (time == null) return parsed;
      return DateTime(parsed.year, parsed.month, parsed.day, time.$1, time.$2);
    }
    return null;
  }

  DateTime? _dateFromNumeric(String line) {
    final patterns = [
      RegExp(r'\b(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})\b'),
      RegExp(r'\b(\d{4})[\/\-.](\d{1,2})[\/\-.](\d{1,2})\b'),
    ];

    for (final match in patterns) {
      final result = match.firstMatch(line);
      if (result == null) continue;

      final first = int.tryParse(result.group(1)!);
      final second = int.tryParse(result.group(2)!);
      final third = int.tryParse(result.group(3)!);
      if (first == null || second == null || third == null) continue;

      if (result.group(1)!.length == 4) {
        return _safeDate(first, second, third);
      }

      return _safeDate(_normaliseYear(third), second, first);
    }

    return null;
  }

  DateTime? _dateFromMonthName(String line) {
    const formats = [
      'd MMM yyyy',
      'dd MMM yyyy',
      'd MMM yy',
      'dd MMM yy',
      'd MMMM yyyy',
      'dd MMMM yyyy',
      'MMM d yyyy',
      'MMMM d yyyy',
    ];

    final match = RegExp(
      r'\b(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{2,4}|[A-Za-z]{3,9}\s+\d{1,2}\s+\d{2,4})\b',
    ).firstMatch(line);
    if (match == null) return null;

    final value = match.group(1)!;
    for (final format in formats) {
      try {
        return DateFormat(format, 'en_US').parseStrict(value);
      } catch (_) {
        // Try the next known receipt date shape.
      }
    }
    return null;
  }

  DateTime? _safeDate(int year, int month, int day) {
    try {
      final date = DateTime(year, month, day);
      if (date.year == year && date.month == month && date.day == day) {
        return date;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  int _normaliseYear(int year) {
    if (year >= 100) return year;
    return year >= 70 ? 1900 + year : 2000 + year;
  }

  (int, int)? _timeFromLine(String line) {
    final match = RegExp(
      r'\b(\d{1,2}):(\d{2})(?:\s*([AP]M))?\b',
      caseSensitive: false,
    ).firstMatch(line);
    if (match == null) return null;

    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || minute > 59) return null;

    final meridiem = match.group(3)?.toLowerCase();
    if (meridiem == 'pm' && hour < 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;
    if (hour > 23) return null;
    return (hour, minute);
  }

  double? _extractTax(List<String> lines) {
    final taxAmounts = <double>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!_isTaxLine(lower) || lower.contains('gstin')) continue;
      if (lower.contains('%') && !_hasCurrencyHint(lower)) continue;

      final amounts = _amountsInLine(line);
      if (amounts.isNotEmpty) taxAmounts.add(amounts.last);
    }

    if (taxAmounts.isEmpty) return null;
    final total = taxAmounts.fold(0.0, (sum, amount) => sum + amount);
    return double.parse(total.toStringAsFixed(2));
  }

  List<ReceiptLineItem> _extractItems(List<String> lines) {
    final items = <ReceiptLineItem>[];

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (items.length >= 30) break;
      if (line.length < 3 || !RegExp(r'[a-zA-Z]').hasMatch(line)) continue;
      if (_hasDate(line) || _isContactOrIdLine(lower)) continue;
      if (_isTotalsLine(lower) || _isTaxLine(lower) || _isPaymentLine(lower)) {
        continue;
      }
      if (lower.contains('receipt') ||
          lower.contains('invoice') ||
          lower.contains('cashier') ||
          lower.contains('thank')) {
        continue;
      }

      final amounts = _amountsInLine(line);
      final amount = amounts.isEmpty ? null : amounts.last;
      final name = _cleanItemName(line, amount);
      if (name.length < 2 || name.split(' ').length > 8) continue;
      if (name.toLowerCase() == _extractMerchant(lines)?.toLowerCase()) {
        continue;
      }

      items.add(ReceiptLineItem(name: name, amount: amount));
    }

    return items;
  }

  String _cleanItemName(String line, double? amount) {
    var value = line;
    if (amount != null) {
      final amountText = amount.toStringAsFixed(2);
      value = value.replaceFirst(RegExp('${RegExp.escape(amountText)}\$'), '');
      value = value.replaceFirst(
        RegExp('${RegExp.escape(amountText.replaceAll('.00', ''))}\$'),
        '',
      );
    }

    return value
        .replaceAll(
          RegExp(r'\b\d+\s*x\s*\d+(\.\d+)?\b', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'\bqty\b|\brate\b|\bamt\b', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'[^a-zA-Z0-9&().,\- ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _hasDate(String line) => _dateFromNumeric(line) != null;

  bool _isTaxLine(String lower) {
    return lower.contains('gst') ||
        lower.contains('cgst') ||
        lower.contains('sgst') ||
        lower.contains('igst') ||
        lower.contains('vat') ||
        lower.contains('tax');
  }

  bool _isTotalsLine(String lower) {
    return lower.contains('total') ||
        lower.contains('subtotal') ||
        lower.contains('sub total') ||
        lower.contains('amount payable') ||
        lower.contains('balance due') ||
        lower.contains('round off') ||
        lower.contains('change');
  }

  bool _isPaymentLine(String lower) {
    return lower.contains('paid') ||
        lower.contains('cash') ||
        lower.contains('card') ||
        lower.contains('upi') ||
        lower.contains('visa') ||
        lower.contains('mastercard');
  }

  bool _isContactOrIdLine(String lower) {
    return lower.contains('gstin') ||
        lower.contains('tin') ||
        lower.contains('fssai') ||
        lower.contains('phone') ||
        lower.contains('mobile') ||
        lower.contains('tel') ||
        lower.contains('email') ||
        lower.contains('www.') ||
        lower.contains('.com') ||
        RegExp(r'\b\d{10,}\b').hasMatch(lower);
  }

  bool _hasCurrencyHint(String lower) {
    return lower.contains('rs') ||
        lower.contains('inr') ||
        lower.contains('amount') ||
        lower.contains('tax') ||
        lower.contains('gst');
  }

  List<double> _amountsInLine(String line) {
    if (_hasDate(line)) return const [];
    final lower = line.toLowerCase();
    if (lower.contains('gstin')) return const [];

    final matches = RegExp(
      r'(^|[^A-Z0-9])((?:\d{1,3}(?:,\d{2,3})+|\d+)(?:\.\d{1,2})?)(?![A-Z0-9])',
      caseSensitive: false,
    ).allMatches(line);

    final amounts = <double>[];
    for (final match in matches) {
      final value = match.group(2);
      if (value == null) continue;

      final tail = line.substring(match.end).trimLeft();
      if (tail.startsWith('%')) continue;

      final compact = value.replaceAll(',', '');
      final digitsOnly = compact.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length > 8 && !compact.contains('.')) continue;

      final parsed = double.tryParse(compact);
      if (parsed == null || parsed <= 0) continue;
      amounts.add(parsed);
    }

    return amounts;
  }
}

class _AmountCandidate {
  final double amount;
  final double score;

  const _AmountCandidate({required this.amount, required this.score});
}

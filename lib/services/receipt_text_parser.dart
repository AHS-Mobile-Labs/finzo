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
        .map((line) {
          // Normalize spacing around decimals: e.g. "450 . 00" -> "450.00"
          var l = line.replaceAll(RegExp(r'(\d+)\s*\.\s*(\d{2})\b'), r'$1.$2');
          // Normalize spacing after currency symbols: e.g. "Rs. 450" -> "Rs.450"
          l = l.replaceAll(RegExp(r'\s+'), ' ').trim();
          return l;
        })
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// Extracts the business/store name while skipping receipt headers, invoice titles, addresses, and contacts.
  String? _extractMerchant(List<String> lines) {
    for (final line in lines.take(8)) {
      final lower = line.toLowerCase();
      if (line.length < 2) continue;
      if (!RegExp(r'[a-zA-Z]').hasMatch(line)) continue;

      // Skip dates, pure numbers, contact lines, tax IDs
      if (_hasDate(line) || _isContactOrIdLine(lower)) continue;
      if (_isTotalsLine(lower) || _isPaymentLine(lower)) continue;
      if (RegExp(r'^\W*\d+[\d\s.,-]*$').hasMatch(line)) continue;

      // Skip generic invoice document titles
      if (_isHeaderOrDocTitle(lower)) continue;

      // Skip address lines
      if (_isAddressLine(lower)) continue;

      final cleaned = _cleanMerchant(line);
      if (cleaned.length >= 2) return cleaned;
    }
    return null;
  }

  String _cleanMerchant(String value) {
    var cleaned = value
        .replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9&().,\- ]+$'), '')
        .trim();

    // If text is ALL CAPS, convert to Title Case for cleaner UI
    if (cleaned.length > 3 &&
        cleaned == cleaned.toUpperCase() &&
        RegExp(r'[A-Z]').hasMatch(cleaned)) {
      cleaned = cleaned
          .split(' ')
          .map((word) {
            if (word.isEmpty) return word;
            if (word.length == 1) return word.toUpperCase();
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          })
          .join(' ');
    }
    return cleaned;
  }

  /// Intelligent total extraction supporting single-line and two-line total receipts,
  /// with weighted scoring and penalty filtering.
  double? _extractTotal(List<String> lines) {
    const labelWeights = {
      'grand total': 150,
      'amount payable': 145,
      'net payable': 145,
      'final amount': 140,
      'total amount payable': 140,
      'total payable': 135,
      'total amount due': 135,
      'total amount': 130,
      'net amount': 125,
      'invoice total': 120,
      'bill amount': 120,
      'balance due': 115,
      'total due': 115,
      'total paid': 110,
      'paid amount': 110,
      'amount paid': 110,
      'total': 100,
      'tot.': 95,
      'bill total': 95,
    };

    final candidates = <_AmountCandidate>[];

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final lower = line.toLowerCase();
      if (_isContactOrIdLine(lower)) continue;

      // Check for label matches
      var baseWeight = 0;
      for (final entry in labelWeights.entries) {
        if (lower.contains(entry.key)) {
          baseWeight = entry.value;
          break;
        }
      }

      // Check line amounts
      var amounts = _amountsInLine(line);

      // CRITICAL ACCURACY FIX: Two-line totals
      // If the current line has a strong total keyword but NO amount, check the next line!
      if (baseWeight > 0 && amounts.isEmpty && index + 1 < lines.length) {
        final nextLine = lines[index + 1];
        final nextLower = nextLine.toLowerCase();
        if (!_isContactOrIdLine(nextLower) && !_isTaxLine(nextLower)) {
          final nextAmounts = _amountsInLine(nextLine);
          if (nextAmounts.isNotEmpty) {
            amounts = nextAmounts;
          }
        }
      }

      if (amounts.isEmpty) continue;

      // Apply penalties for deductions, tax components, subtotals, and cash tender
      var adjustedWeight = baseWeight;
      if (lower.contains('sub total') ||
          lower.contains('subtotal') ||
          lower.contains('sub-total')) {
        adjustedWeight -= 60;
      }
      if (_isTaxLine(lower)) adjustedWeight -= 50;
      if (lower.contains('discount') ||
          lower.contains('disc') ||
          lower.contains('coupon') ||
          lower.contains('savings')) {
        adjustedWeight -= 45;
      }
      if (lower.contains('change') ||
          lower.contains('tendered') ||
          lower.contains('cash given')) {
        adjustedWeight -= 40;
      }
      if (lower.contains('round off') || lower.contains('roundoff')) {
        adjustedWeight -= 35;
      }

      // Boost if line has explicit currency indication (₹, Rs, INR, $, etc.)
      if (_hasCurrencyHint(lower)) {
        adjustedWeight += 15;
      }

      // Boost if located in the bottom 45% of the receipt where totals naturally occur
      if (index >= lines.length * 0.5) {
        adjustedWeight += 10;
      }

      for (final amount in amounts) {
        if (amount <= 0 || amount > 10000000) continue;
        candidates.add(
          _AmountCandidate(
            amount: amount,
            score: adjustedWeight - (index * 0.1) + (amount > 0 ? 1 : 0),
          ),
        );
      }
    }

    // Return the highest-scoring candidate with a confident label
    final confident = candidates.where((c) => c.score >= 70).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    if (confident.isNotEmpty) return confident.first.amount;

    // Fallback: Pick the maximum sensible monetary amount on the receipt
    final fallback = candidates.where((c) => c.amount < 1000000).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return fallback.isEmpty ? null : fallback.first.amount;
  }

  /// Extracts transaction date and time with multi-format and priority support.
  DateTime? _extractDateTime(List<String> lines) {
    // Priority pass: Check lines containing date hints first
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('date') ||
          lower.contains('dt') ||
          lower.contains('dated') ||
          lower.contains('time')) {
        final parsed = _parseDateFromLine(line);
        if (parsed != null) return parsed;
      }
    }

    // Secondary pass: Check all lines
    for (final line in lines) {
      final parsed = _parseDateFromLine(line);
      if (parsed != null) return parsed;
    }
    return null;
  }

  DateTime? _parseDateFromLine(String line) {
    final parsed = _dateFromNumeric(line) ?? _dateFromMonthName(line);
    if (parsed == null) return null;
    final time = _timeFromLine(line);
    if (time == null) return parsed;
    return DateTime(parsed.year, parsed.month, parsed.day, time.$1, time.$2);
  }

  DateTime? _dateFromNumeric(String line) {
    final patterns = [
      // DD/MM/YYYY or MM/DD/YYYY or DD-MM-YYYY or DD.MM.YYYY
      RegExp(r'\b(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})\b'),
      // YYYY/MM/DD or YYYY-MM-DD or YYYY.MM.DD
      RegExp(r'\b(\d{4})[\/\-.](\d{1,2})[\/\-.](\d{1,2})\b'),
    ];

    for (final match in patterns) {
      final result = match.firstMatch(line);
      if (result == null) continue;

      final first = int.tryParse(result.group(1)!);
      final second = int.tryParse(result.group(2)!);
      final third = int.tryParse(result.group(3)!);
      if (first == null || second == null || third == null) continue;

      // Case: YYYY-MM-DD
      if (result.group(1)!.length == 4) {
        return _safeDate(first, second, third);
      }

      final year = _normaliseYear(third);

      // Intelligent Day vs Month disambiguation
      if (first > 12 && second <= 12) {
        // First is definitely Day -> DD/MM/YYYY
        return _safeDate(year, second, first);
      } else if (second > 12 && first <= 12) {
        // Second is definitely Day -> MM/DD/YYYY
        return _safeDate(year, first, second);
      }

      // Default receipt convention: DD/MM/YYYY
      return _safeDate(year, second, first);
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
      'MMM dd yyyy',
      'd-MMM-yyyy',
      'dd-MMM-yyyy',
      'd-MMM-yy',
      'dd-MMM-yy',
    ];

    final match = RegExp(
      r'\b(\d{1,2}[\s\-]+[A-Za-z]{3,9}[\s\-]+\d{2,4}|[A-Za-z]{3,9}[\s\-]+\d{1,2}[\s\-]+\d{2,4})\b',
    ).firstMatch(line);
    if (match == null) return null;

    final value = match.group(1)!;
    for (final format in formats) {
      try {
        final d = DateFormat(format, 'en_US').parseStrict(value);
        if (_isValidYear(d.year)) return d;
      } catch (_) {}
    }
    return null;
  }

  bool _isValidYear(int year) {
    final currentYear = DateTime.now().year;
    return year >= 2015 && year <= currentYear + 1;
  }

  DateTime? _safeDate(int year, int month, int day) {
    if (!_isValidYear(year)) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

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
      r'\b(\d{1,2}):(\d{2})(?::\d{2})?(?:\s*([AP]M))?\b',
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
      if (_isHeaderOrDocTitle(lower)) continue;
      if (lower.contains('cashier') ||
          lower.contains('thank') ||
          lower.contains('welcome')) {
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

  bool _isHeaderOrDocTitle(String lower) {
    const titles = [
      'tax invoice',
      'tax-invoice',
      'retail invoice',
      'tax bill',
      'cash memo',
      'cash bill',
      'bill of supply',
      'commercial invoice',
      'proforma invoice',
      'sales receipt',
      'sales invoice',
      'payment receipt',
      'customer receipt',
      'customer copy',
      'merchant copy',
      'store copy',
      'duplicate copy',
      'original copy',
      'original for recipient',
      'welcome',
      'thank you',
      'thanks for visiting',
      'visit again',
      'e-receipt',
      'order receipt',
      'estimate',
      'quotation',
    ];
    for (final title in titles) {
      if (lower.contains(title)) return true;
    }
    return false;
  }

  bool _isAddressLine(String lower) {
    const addressClues = [
      'road',
      ' rd',
      'street',
      ' st.',
      'lane',
      'avenue',
      ' ave',
      'sector',
      'floor',
      'flr',
      'block',
      'opp.',
      'opposite',
      'near',
      'nagar',
      'cross',
      'building',
      'bldg',
      'plot no',
      'shop no',
      'dist.',
      'pincode',
      'pin code',
      'postal',
      'zip code',
    ];
    for (final clue in addressClues) {
      if (lower.contains(clue)) return true;
    }
    return false;
  }

  bool _isTaxLine(String lower) {
    return lower.contains('gst') ||
        lower.contains('cgst') ||
        lower.contains('sgst') ||
        lower.contains('igst') ||
        lower.contains('vat') ||
        lower.contains('service tax') ||
        (lower.contains('tax') && !lower.contains('tax invoice'));
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
        lower.contains('cin:') ||
        lower.contains('tin:') ||
        lower.contains('fssai') ||
        lower.contains('pan:') ||
        lower.contains('phone') ||
        lower.contains('mobile') ||
        lower.contains('tel:') ||
        lower.contains('email') ||
        lower.contains('www.') ||
        lower.contains('.com') ||
        lower.contains('.org') ||
        lower.contains('.in') ||
        RegExp(r'\b\d{10,}\b').hasMatch(lower);
  }

  bool _hasCurrencyHint(String lower) {
    return lower.contains('₹') ||
        lower.contains('rs') ||
        lower.contains('inr') ||
        lower.contains('\$') ||
        lower.contains('€') ||
        lower.contains('£') ||
        lower.contains('amount') ||
        lower.contains('total') ||
        lower.contains('payable');
  }

  /// Extracts valid monetary amounts from a line while stripping currency symbols
  /// and correcting common OCR misreadings.
  List<double> _amountsInLine(String line) {
    if (_hasDate(line)) return const [];
    final lower = line.toLowerCase();
    if (lower.contains('gstin')) return const [];

    // Strip currency symbols
    var cleaned = line
        .replaceAll('₹', ' ')
        .replaceAll(
          RegExp(r'\b(?:rs\.?|inr|\$|€|£)\b', caseSensitive: false),
          ' ',
        );

    // Correct common OCR glitch where letter 'O' or 'o' is scanned in decimals: e.g. .OO -> .00
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\.(\d)?[Oo0]([Oo0])?\b'),
      (match) => '.${match.group(1) ?? '0'}0',
    );

    final matches = RegExp(
      r'(^|[^A-Z0-9])((?:\d{1,3}(?:,\d{2,3})+|\d+)(?:\.\d{1,2})?)(?![A-Z0-9])',
      caseSensitive: false,
    ).allMatches(cleaned);

    final amounts = <double>[];
    for (final match in matches) {
      final value = match.group(2);
      if (value == null) continue;

      final tail = cleaned.substring(match.end).trimLeft();
      if (tail.startsWith('%')) continue;

      final compact = value.replaceAll(',', '');
      final digitsOnly = compact.replaceAll(RegExp(r'\D'), '');
      // Exclude phone numbers / long serial numbers
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

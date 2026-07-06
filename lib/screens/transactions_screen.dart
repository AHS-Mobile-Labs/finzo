import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/add_transaction_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'all';
  String _search = '';
  String _period = 'all';
  DateTime _periodAnchor = DateTime.now();
  String? _accountFilter;
  String? _categoryFilter;
  String? _paymentFilter;
  String? _trackingFilter;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final all = provider.transactions;

    final searchLower = _search.toLowerCase();
    final filtered = all.where((tx) {
      final category = provider.getCategoryById(tx.categoryId);
      final account = provider.getAccountById(tx.accountId);
      final related = tx.relatedAccountId == null
          ? null
          : provider.getAccountById(tx.relatedAccountId!);
      final splitCategories = tx.splits
          .map((split) => provider.getCategoryById(split.categoryId))
          .where((category) => category != null)
          .toList();
      final matchType = _filter == 'all' || tx.type == _filter;
      final searchable = [
        tx.title,
        tx.note ?? '',
        provider.categoryDisplayName(category),
        ...splitCategories.map((cat) => provider.categoryDisplayName(cat)),
        account?.name ?? '',
        related?.name ?? '',
        TransactionPaymentMethod.label(tx.paymentMethod),
        TransactionTrackingStatus.label(tx.trackingStatus),
        ...tx.tags,
      ].join(' ').toLowerCase();
      final matchSearch = _search.isEmpty || searchable.contains(searchLower);
      final matchPeriod = _matchesPeriod(tx.date);
      final matchAccount =
          _accountFilter == null ||
          tx.accountId == _accountFilter ||
          tx.relatedAccountId == _accountFilter;
      final matchCategory =
          _categoryFilter == null ||
          tx.categoryId == _categoryFilter ||
          tx.splits.any((split) => split.categoryId == _categoryFilter);
      final matchPayment =
          _paymentFilter == null || tx.paymentMethod == _paymentFilter;
      final matchTracking =
          _trackingFilter == null || tx.trackingStatus == _trackingFilter;
      return matchType &&
          matchSearch &&
          matchPeriod &&
          matchAccount &&
          matchCategory &&
          matchPayment &&
          matchTracking;
    }).toList();

    // Group by date
    final grouped = <String, List<TransactionModel>>{};
    for (final tx in filtered) {
      final key = Formatters.dateFull(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(
              _hasAdvancedFilters
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_outlined,
            ),
            onPressed: () => _showFilters(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAdd(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.white38,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Expense',
                        selected: _filter == 'expense',
                        onTap: () => setState(() => _filter = 'expense'),
                        activeColor: AppTheme.expenseColor,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Income',
                        selected: _filter == 'income',
                        onTap: () => setState(() => _filter = 'income'),
                        activeColor: AppTheme.incomeColor,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Transfer',
                        selected: _filter == 'transfer',
                        onTap: () => setState(() => _filter = 'transfer'),
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final period in [
                        'all',
                        'day',
                        'week',
                        'month',
                        'year',
                      ]) ...[
                        _FilterChip(
                          label: _periodLabelShort(period),
                          selected: _period == period,
                          onTap: () => setState(() => _period = period),
                          activeColor: AppTheme.infoColor,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                if (_period != 'all') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous period',
                        onPressed: () => setState(() {
                          _periodAnchor = _movePeriod(_periodAnchor, -1);
                        }),
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white54,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _periodLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next period',
                        onPressed: () => setState(() {
                          _periodAnchor = _movePeriod(_periodAnchor, 1);
                        }),
                        icon: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_rounded, color: Colors.white24, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'No transactions found',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: grouped.entries.length,
                itemBuilder: (_, i) {
                  final entry = grouped.entries.elementAt(i);
                  final dayTotal = entry.value.fold<double>(
                    0,
                    (sum, tx) =>
                        sum +
                        (tx.type == 'transfer'
                            ? 0
                            : tx.type == 'income'
                            ? tx.amount
                            : -tx.amount),
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${dayTotal >= 0 ? '+' : ''}${Formatters.currency(dayTotal)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: dayTotal >= 0
                                    ? AppTheme.incomeColor
                                    : AppTheme.expenseColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...entry.value.map(
                        (tx) =>
                            TransactionTile(
                                  transaction: tx,
                                  category: provider.getCategoryById(
                                    tx.categoryId,
                                  ),
                                  account: provider.getAccountById(
                                    tx.accountId,
                                  ),
                                  relatedAccount: tx.relatedAccountId == null
                                      ? null
                                      : provider.getAccountById(
                                          tx.relatedAccountId!,
                                        ),
                                  onTap: () => _showEdit(context, tx),
                                  onDelete: () =>
                                      provider.removeTransaction(tx),
                                )
                                .animate()
                                .fadeIn(duration: 180.ms)
                                .slideX(begin: .03, end: 0),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      requestFocus: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  void _showEdit(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      requestFocus: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(existing: tx),
    );
  }

  bool get _hasAdvancedFilters =>
      _accountFilter != null ||
      _categoryFilter != null ||
      _paymentFilter != null ||
      _trackingFilter != null;

  String _periodLabelShort(String period) {
    return switch (period) {
      'day' => 'Day',
      'week' => 'Week',
      'month' => 'Month',
      'year' => 'Year',
      _ => 'All time',
    };
  }

  bool _matchesPeriod(DateTime date) {
    if (_period == 'all') return true;
    final start = _periodStart(_periodAnchor);
    final end = _movePeriod(start, 1);
    return !date.isBefore(start) && date.isBefore(end);
  }

  DateTime _periodStart(DateTime date) {
    return switch (_period) {
      'day' => DateTime(date.year, date.month, date.day),
      'week' => DateTime(
        date.year,
        date.month,
        date.day - (date.weekday - DateTime.monday),
      ),
      'month' => DateTime(date.year, date.month),
      'year' => DateTime(date.year),
      _ => DateTime(1970),
    };
  }

  DateTime _movePeriod(DateTime date, int delta) {
    return switch (_period) {
      'day' => date.add(Duration(days: delta)),
      'week' => date.add(Duration(days: 7 * delta)),
      'month' => DateTime(date.year, date.month + delta, 1),
      'year' => DateTime(date.year + delta, 1, 1),
      _ => date,
    };
  }

  String get _periodLabel {
    final start = _periodStart(_periodAnchor);
    return switch (_period) {
      'day' => Formatters.dateFull(start),
      'week' =>
        '${Formatters.dateShort(start)} - ${Formatters.dateShort(start.add(const Duration(days: 6)))}',
      'month' => Formatters.monthYear(start),
      'year' => start.year.toString(),
      _ => 'All time',
    };
  }

  void _showFilters(BuildContext context) {
    final provider = context.read<FinanceProvider>();
    var accountId = _accountFilter;
    var categoryId = _categoryFilter;
    var paymentMethod = _paymentFilter;
    var trackingStatus = _trackingFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: accountId,
                  dropdownColor: AppTheme.cardColor,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All accounts'),
                    ),
                    ...provider.accounts.map(
                      (account) => DropdownMenuItem<String?>(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setSheetState(() => accountId = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: categoryId,
                  dropdownColor: AppTheme.cardColor,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All categories'),
                    ),
                    ...provider.categories.map(
                      (category) => DropdownMenuItem<String?>(
                        value: category.id,
                        child: Text(provider.categoryDisplayName(category)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setSheetState(() => categoryId = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: paymentMethod,
                  dropdownColor: AppTheme.cardColor,
                  decoration: const InputDecoration(
                    labelText: 'Payment method',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All methods'),
                    ),
                    ...TransactionPaymentMethod.values.map(
                      (method) => DropdownMenuItem<String?>(
                        value: method,
                        child: Text(TransactionPaymentMethod.label(method)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setSheetState(() => paymentMethod = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: trackingStatus,
                  dropdownColor: AppTheme.cardColor,
                  decoration: const InputDecoration(labelText: 'Tracking'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    ...TransactionTrackingStatus.values.map(
                      (status) => DropdownMenuItem<String?>(
                        value: status,
                        child: Text(TransactionTrackingStatus.label(status)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setSheetState(() => trackingStatus = value);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setSheetState(() {
                            accountId = null;
                            categoryId = null;
                            paymentMethod = null;
                            trackingStatus = null;
                          });
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _accountFilter = accountId;
                            _categoryFilter = categoryId;
                            _paymentFilter = paymentMethod;
                            _trackingFilter = trackingStatus;
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? activeColor;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(51) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.white54,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

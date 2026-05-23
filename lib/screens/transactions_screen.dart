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
      final matchType = _filter == 'all' || tx.type == _filter;
      final searchable = [
        tx.title,
        tx.note ?? '',
        category?.name ?? '',
        account?.name ?? '',
        related?.name ?? '',
      ].join(' ').toLowerCase();
      final matchSearch = _search.isEmpty || searchable.contains(searchLower);
      return matchType && matchSearch;
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
                Row(
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

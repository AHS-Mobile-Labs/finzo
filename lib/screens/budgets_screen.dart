import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/finance_provider.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../utils/app_theme.dart';
import '../utils/emoji_to_icon.dart';
import '../utils/formatters.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final budgets = provider.budgets;
    final now = provider.selectedMonth;

    final totalBudget = budgets.fold<double>(0, (s, b) => s + b.amount);
    final totalSpent = budgets.fold<double>(0, (s, b) => s + b.spent);

    return Scaffold(
      appBar: AppBar(
        title: Text('Budgets · ${Formatters.monthYear(now)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () =>
                provider.setSelectedMonth(DateTime(now.year, now.month - 1)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () =>
                provider.setSelectedMonth(DateTime(now.year, now.month + 1)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          _OverviewCard(totalBudget: totalBudget, totalSpent: totalSpent),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Budget Categories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddBudget(context, provider),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (budgets.isEmpty)
            _EmptyBudgets(onAdd: () => _showAddBudget(context, provider))
          else
            ...budgets.map((b) {
              final cat = provider.getCategoryById(b.categoryId);
              return _BudgetCard(
                budget: b,
                category: cat,
                onDelete: () => provider.removeBudget(b.id),
                onEdit: () => _showEditBudget(context, provider, b, cat),
              ).animate().fadeIn(duration: 220.ms).slideY(begin: .04, end: 0);
            }),
        ],
      ),
    );
  }

  void _showAddBudget(BuildContext context, FinanceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const _BudgetSheet(),
      ),
    );
  }

  void _showEditBudget(
    BuildContext context,
    FinanceProvider provider,
    BudgetModel b,
    CategoryModel? cat,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _BudgetSheet(existing: b, preselectedCategory: cat),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;

  const _OverviewCard({required this.totalBudget, required this.totalSpent});

  @override
  Widget build(BuildContext context) {
    final pct = totalBudget > 0
        ? (totalSpent / totalBudget).clamp(0.0, 1.0)
        : 0.0;
    final isOver = totalSpent > totalBudget && totalBudget > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOver
              ? [AppTheme.expenseColor.withAlpha(204), const Color(0xFF8B0000)]
              : [const Color(0xFF6C63FF), const Color(0xFF5A52D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOver ? AppTheme.expenseColor : AppTheme.primaryColor)
                .withAlpha(77),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Budget',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOver
                          ? Icons.warning_rounded
                          : Icons.check_circle_rounded,
                      color: isOver ? Colors.orange : Colors.green,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOver ? 'Over Budget' : 'On Track',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(totalSpent),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '/ ${Formatters.currency(totalBudget)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? Colors.orange : Colors.white,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(pct * 100).toStringAsFixed(1)}% of budget used',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final CategoryModel? category;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _BudgetCard({
    required this.budget,
    this.category,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(category?.color ?? 0xFF6C63FF);
    final isOver = budget.isOverBudget;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOver
                ? AppTheme.expenseColor.withAlpha(77)
                : Colors.white.withAlpha(15),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(38),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      EmojiToIcon.getIcon(category?.icon ?? 'box'),
                      color: color,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.name ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.currency(budget.spent)} / ${Formatters.currency(budget.amount)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOver
                          ? '${Formatters.currency(budget.spent - budget.amount)} over'
                          : '${Formatters.currency(budget.remaining)} left',
                      style: TextStyle(
                        color: isOver
                            ? AppTheme.expenseColor
                            : AppTheme.incomeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white38,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: budget.percentage,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOver ? AppTheme.expenseColor : color,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBudgets extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyBudgets({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.track_changes_rounded, size: 48, color: Colors.white54),
          const SizedBox(height: 12),
          const Text(
            'No budgets set',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Set budgets to track your spending',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Budget'),
          ),
        ],
      ),
    );
  }
}

class _BudgetSheet extends StatefulWidget {
  final BudgetModel? existing;
  final CategoryModel? preselectedCategory;

  const _BudgetSheet({this.existing, this.preselectedCategory});

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  final _amountCtrl = TextEditingController();
  CategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _amountCtrl.text = widget.existing!.amount.toString();
      _selectedCategory = widget.preselectedCategory;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final kbHeight = MediaQuery.of(context).viewInsets.bottom;
    final categories = provider.getCategoriesForType('expense');

    return Container(
      padding: EdgeInsets.only(bottom: kbHeight),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            Text(
              widget.existing != null ? 'Edit Budget' : 'New Budget',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<CategoryModel>(
              initialValue: _selectedCategory,
              dropdownColor: AppTheme.cardColor,
              decoration: const InputDecoration(labelText: 'Category'),
              style: const TextStyle(color: Colors.white),
              items: categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(
                        EmojiToIcon.getIcon(cat.icon),
                        color: Color(cat.color),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(cat.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Budget Amount',
                prefixText: '₹  ',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: Text(
                widget.existing != null ? 'Save Changes' : 'Create Budget',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) return;
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    final provider = context.read<FinanceProvider>();
    final now = provider.selectedMonth;

    if (widget.existing != null) {
      await provider.editBudget(
        BudgetModel(
          id: widget.existing!.id,
          categoryId: _selectedCategory!.id,
          amount: amount,
          spent: widget.existing!.spent,
          month: now.month,
          year: now.year,
        ),
      );
    } else {
      await provider.addBudget(
        BudgetModel(
          id: const Uuid().v4(),
          categoryId: _selectedCategory!.id,
          amount: amount,
          month: now.month,
          year: now.year,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }
}

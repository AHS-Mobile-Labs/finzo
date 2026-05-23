import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/account_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/emoji_to_icon.dart';
import '../utils/formatters.dart';

class AddTransactionSheet extends StatefulWidget {
  final TransactionModel? existing;

  const AddTransactionSheet({super.key, this.existing});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _amountFocusNode = FocusNode();
  DateTime _selectedDate = DateTime.now();
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  AccountModel? _destinationAccount;
  bool _submitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (_isEditing) {
      final tx = widget.existing!;
      _titleCtrl.text = tx.title;
      _amountCtrl.text = tx.amount.toString();
      _noteCtrl.text = tx.note ?? '';
      _selectedDate = tx.date;
      _tabController.index = switch (tx.type) {
        'income' => 1,
        'transfer' => 2,
        _ => 0,
      };
      final p = context.read<FinanceProvider>();
      _selectedCategory = p.getCategoryById(tx.categoryId);
      _selectedAccount = p.getAccountById(tx.accountId);
      if (tx.relatedAccountId != null) {
        _destinationAccount = p.getAccountById(tx.relatedAccountId!);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  String get _type => switch (_tabController.index) {
    1 => 'income',
    2 => 'transfer',
    _ => 'expense',
  };

  bool get _isTransfer => _type == 'transfer';

  Future<void> _submit() async {
    if (_submitting) return;
    if (_titleCtrl.text.trim().isEmpty || _amountCtrl.text.isEmpty) return;
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    if (_selectedAccount == null) return;
    if (_isTransfer &&
        (_destinationAccount == null ||
            _destinationAccount!.id == _selectedAccount!.id)) {
      return;
    }
    if (!_isTransfer && _selectedCategory == null) return;

    setState(() => _submitting = true);

    try {
      final provider = context.read<FinanceProvider>();
      final tx = TransactionModel(
        id: widget.existing?.id ?? const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        amount: amount,
        type: _type,
        categoryId: _isTransfer ? 'cat_transfer' : _selectedCategory!.id,
        accountId: _selectedAccount!.id,
        relatedAccountId: _isTransfer ? _destinationAccount!.id : null,
        date: _selectedDate,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await provider.editTransaction(widget.existing!, tx);
      } else {
        await provider.addTransaction(tx);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
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
              _isEditing ? 'Edit Transaction' : 'New Transaction',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Type Tab
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (_) => setState(() {
                  _selectedCategory = null;
                  if (!_isTransfer) _destinationAccount = null;
                }),
                indicator: BoxDecoration(
                  color: _type == 'expense'
                      ? AppTheme.expenseColor.withAlpha(51)
                      : AppTheme.incomeColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: _type == 'expense'
                    ? AppTheme.expenseColor
                    : AppTheme.incomeColor,
                unselectedLabelColor: Colors.white38,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_down_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Expense'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Income'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horiz_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Transfer'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountCtrl,
              focusNode: _amountFocusNode,
              onTap: () => _amountFocusNode.requestFocus(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final isValidAmount = RegExp(
                    r'^\d*\.?\d{0,2}$',
                  ).hasMatch(newValue.text);
                  return isValidAmount ? newValue : oldValue;
                }),
              ],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                prefixText: '₹  ',
                prefixStyle: TextStyle(color: Colors.white54, fontSize: 28),
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 28),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title_rounded, color: Colors.white38),
              ),
            ),
            const SizedBox(height: 12),

            if (!_isTransfer) ...[
              _buildDropdown<CategoryModel>(
                label: 'Category',
                icon: _selectedCategory?.icon,
                fallbackIcon: Icons.category_rounded,
                value: _selectedCategory?.name ?? 'Select category',
                items: provider.getCategoriesForType(_type),
                onTap: () =>
                    _pickCategory(provider.getCategoriesForType(_type)),
              ),
              const SizedBox(height: 12),
            ],

            // Account selector
            _buildDropdown<AccountModel>(
              label: _isTransfer ? 'From account' : 'Account',
              icon: _selectedAccount?.icon,
              fallbackIcon: Icons.account_balance_rounded,
              value:
                  _selectedAccount?.name ??
                  (_isTransfer ? 'Select source account' : 'Select account'),
              items: provider.accounts,
              onTap: () =>
                  _pickAccount(provider.accounts, isDestination: false),
            ),
            const SizedBox(height: 12),
            if (_isTransfer) ...[
              _buildDropdown<AccountModel>(
                label: 'To account',
                icon: _destinationAccount?.icon,
                fallbackIcon: Icons.account_balance_wallet_rounded,
                value:
                    _destinationAccount?.name ?? 'Select destination account',
                items: provider.accounts
                    .where((acc) => acc.id != _selectedAccount?.id)
                    .toList(),
                onTap: () => _pickAccount(
                  provider.accounts
                      .where((acc) => acc.id != _selectedAccount?.id)
                      .toList(),
                  isDestination: true,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Date
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Formatters.dateFull(_selectedDate),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Note
            TextField(
              controller: _noteCtrl,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes_rounded, color: Colors.white38),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String? icon,
    required IconData fallbackIcon,
    required String value,
    required List<T> items,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            icon != null
                ? Icon(
                    EmojiToIcon.getIcon(icon),
                    color: Colors.white54,
                    size: 20,
                  )
                : Icon(fallbackIcon, color: Colors.white54, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: value.startsWith('Select')
                      ? Colors.white38
                      : Colors.white70,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCategory(List<CategoryModel> categories) async {
    final result = await showModalBottomSheet<CategoryModel>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PickerSheet<CategoryModel>(
        title: 'Select Category',
        items: categories,
        builder: (cat) => _PickerItem(
          icon: cat.icon,
          label: cat.name,
          color: Color(cat.color),
        ),
      ),
    );
    if (result != null) setState(() => _selectedCategory = result);
  }

  Future<void> _pickAccount(
    List<AccountModel> accounts, {
    required bool isDestination,
  }) async {
    final result = await showModalBottomSheet<AccountModel>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PickerSheet<AccountModel>(
        title: 'Select Account',
        items: accounts,
        builder: (acc) => _PickerItem(
          icon: acc.icon,
          label: acc.name,
          color: Color(acc.color),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        if (isDestination) {
          _destinationAccount = result;
        } else {
          _selectedAccount = result;
          if (_destinationAccount?.id == result.id) {
            _destinationAccount = null;
          }
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
}

class _PickerSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final Widget Function(T) builder;

  const _PickerSheet({
    required this.title,
    required this.items,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: items
                .map(
                  (item) => GestureDetector(
                    onTap: () => Navigator.pop(context, item),
                    child: builder(item),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PickerItem extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _PickerItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(64)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(EmojiToIcon.getIcon(icon), color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/account_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/emoji_to_icon.dart';

class QuickAddTransactionSheet extends StatefulWidget {
  final Future<void> Function()? onScanReceipt;

  const QuickAddTransactionSheet({super.key, this.onScanReceipt});

  @override
  State<QuickAddTransactionSheet> createState() =>
      _QuickAddTransactionSheetState();
}

class _QuickAddTransactionSheetState extends State<QuickAddTransactionSheet> {
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _amountFocusNode = FocusNode();
  DateTime _selectedDate = DateTime.now();
  String _type = 'expense';
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  AccountModel? _destinationAccount;
  bool _submitting = false;
  bool _showCalculator = false;

  bool get _isTransfer => _type == 'transfer';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<FinanceProvider>();
        if (_selectedAccount == null && provider.accounts.isNotEmpty) {
          setState(() => _selectedAccount = provider.accounts.first);
        }
      }
    });
    _amountCtrl.addListener(_refreshForm);
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_refreshForm);
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _refreshForm() {
    if (mounted) setState(() {});
  }

  void _addToAmount(String digit) {
    if (digit == '.' && _amountCtrl.text.contains('.')) {
      return; // Prevent multiple decimal points
    }
    if (_amountCtrl.text.length < 10) {
      setState(() {
        if (digit == 'C') {
          _amountCtrl.clear();
        } else if (digit == '←') {
          if (_amountCtrl.text.isNotEmpty) {
            _amountCtrl.text = _amountCtrl.text.substring(
              0,
              _amountCtrl.text.length - 1,
            );
          }
        } else {
          _amountCtrl.text += digit;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_amountCtrl.text.isEmpty || _titleCtrl.text.trim().isEmpty) return;

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

    final provider = context.read<FinanceProvider>();
    final tx = TransactionModel(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      amount: amount,
      type: _type,
      categoryId: _isTransfer ? 'cat_transfer' : _selectedCategory!.id,
      accountId: _selectedAccount!.id,
      relatedAccountId: _isTransfer ? _destinationAccount!.id : null,
      date: _selectedDate,
      note: null,
      createdAt: DateTime.now(),
    );

    await provider.addTransaction(tx);
    if (mounted) Navigator.pop(context);
  }

  void _toggleType(String newType) {
    setState(() {
      _type = newType;
      _selectedCategory = null; // Reset category when switching types
      if (!_isTransfer) _destinationAccount = null;
    });
  }

  void _handleSwipe(DragEndDetails details) {
    const swipeThreshold = 50.0;
    final velocity = details.velocity.pixelsPerSecond.dx.abs();
    if (velocity > swipeThreshold) {
      if (details.velocity.pixelsPerSecond.dx > 0) {
        // Swipe right = income
        _toggleType('income');
      } else {
        // Swipe left = expense
        _toggleType('expense');
      }
    }
  }

  void _openReceiptScanner() {
    final scanner = widget.onScanReceipt;
    if (scanner == null) return;

    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scanner();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final recentCategories = _isTransfer
        ? <CategoryModel>[]
        : provider.getRecentCategories(_type);

    return GestureDetector(
      onHorizontalDragEnd: _handleSwipe,
      child: Container(
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
              // Drag handle
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
              const SizedBox(height: 8),
              // Swipe hint
              Center(
                child: Text(
                  '← Swipe to toggle →',
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header with type toggle
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quick Add',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        _TypeButton(
                          label: 'Expense',
                          isSelected: _type == 'expense',
                          onTap: () => _toggleType('expense'),
                        ),
                        _TypeButton(
                          label: 'Income',
                          isSelected: _type == 'income',
                          onTap: () => _toggleType('income'),
                        ),
                        _TypeButton(
                          label: 'Transfer',
                          isSelected: _type == 'transfer',
                          onTap: () => _toggleType('transfer'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (widget.onScanReceipt != null) ...[
                _ReceiptScanShortcut(onTap: _openReceiptScanner),
                const SizedBox(height: 18),
              ],

              // Amount input (large)
              TextField(
                controller: _amountCtrl,
                focusNode: _amountFocusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
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
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: '₹  ',
                  prefixStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 36,
                  ),
                  hintText: 'Tap to enter',
                  hintStyle: const TextStyle(
                    color: Colors.white24,
                    fontSize: 24,
                  ),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    tooltip: 'Calculator',
                    onPressed: () {
                      _amountFocusNode.unfocus();
                      setState(() => _showCalculator = !_showCalculator);
                    },
                    icon: Icon(
                      _showCalculator
                          ? Icons.keyboard_rounded
                          : Icons.calculate_rounded,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Quick calculator (optional)
              if (_showCalculator) ...[
                _buildCalculator(),
                const SizedBox(height: 16),
              ],

              // Title input
              TextField(
                controller: _titleCtrl,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Title (e.g., "Lunch")',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
              const SizedBox(height: 16),

              // Recent categories (quick chips)
              if (recentCategories.isNotEmpty) ...[
                const Text(
                  'Quick pick:',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...recentCategories.take(3).map((cat) {
                      final isSelected = _selectedCategory?.id == cat.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(cat.color).withAlpha(100)
                                : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Color(cat.color)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                EmojiToIcon.getIcon(cat.icon),
                                color: Color(cat.color),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    // Browse all categories
                    GestureDetector(
                      onTap: () =>
                          _pickCategory(provider.getCategoriesForType(_type)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: Colors.white54,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'More',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Account selector (inline)
              if (provider.accounts.isNotEmpty) ...[
                Text(
                  _isTransfer ? 'From account:' : 'Account:',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: provider.accounts.map((acc) {
                      final isSelected = _selectedAccount?.id == acc.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedAccount = acc),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(acc.color).withAlpha(100)
                                  : AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Color(acc.color)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  EmojiToIcon.getIcon(acc.icon),
                                  color: Color(acc.color),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  acc.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_isTransfer && provider.accounts.isNotEmpty) ...[
                const Text(
                  'To account:',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: provider.accounts
                        .where((acc) => acc.id != _selectedAccount?.id)
                        .map((acc) {
                          final isSelected = _destinationAccount?.id == acc.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _destinationAccount = acc),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Color(acc.color).withAlpha(100)
                                      : AppTheme.cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Color(acc.color)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      EmojiToIcon.getIcon(acc.icon),
                                      color: Color(acc.color),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      acc.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Date selector (quick)
              GestureDetector(
                onTap: () => _pickDate(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Formatters.dateShort(_selectedDate),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed:
                    (_submitting ||
                        (!_isTransfer && _selectedCategory == null) ||
                        (_isTransfer && _destinationAccount == null) ||
                        _amountCtrl.text.isEmpty ||
                        _titleCtrl.text.isEmpty)
                    ? null
                    : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isTransfer ? 'Transfer Money' : 'Add Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculator() {
    const buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '←'],
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ...buttons.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: row.map((btn) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: MaterialButton(
                        onPressed: () => _addToAmount(btn),
                        color: Colors.white10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          btn,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: MaterialButton(
                  onPressed: () => _addToAmount('C'),
                  color: AppTheme.expenseColor.withAlpha(80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MaterialButton(
                  onPressed: () => setState(() => _showCalculator = false),
                  color: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
      builder: (_) => _AllCategoriesPicker(categories: categories),
    );
    if (result != null) setState(() => _selectedCategory = result);
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

class _ReceiptScanShortcut extends StatelessWidget {
  final VoidCallback onTap;

  const _ReceiptScanShortcut({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withAlpha(70)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(44),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: AppTheme.primaryColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan receipt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Create an expense from camera or gallery',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
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
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: switch (label) {
                  'Expense' => AppTheme.expenseColor.withAlpha(100),
                  'Income' => AppTheme.incomeColor.withAlpha(100),
                  _ => AppTheme.primaryColor.withAlpha(100),
                },
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AllCategoriesPicker extends StatelessWidget {
  final List<CategoryModel> categories;

  const _AllCategoriesPicker({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Select Category',
          style: TextStyle(
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
            children: categories.map((cat) {
              return GestureDetector(
                onTap: () => Navigator.pop(context, cat),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(cat.color).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(cat.color).withAlpha(100),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        EmojiToIcon.getIcon(cat.icon),
                        color: Color(cat.color),
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

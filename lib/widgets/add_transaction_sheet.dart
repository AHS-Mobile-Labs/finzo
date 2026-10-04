import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/account_model.dart';
import '../providers/finance_provider.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/emoji_to_icon.dart';
import '../utils/formatters.dart';
import 'category_picker_sheet.dart';

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
  final _tagsCtrl = TextEditingController();
  final _amountFocusNode = FocusNode();
  DateTime _selectedDate = DateTime.now();
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  AccountModel? _destinationAccount;
  String _paymentMethod = TransactionPaymentMethod.cash;
  String? _receiptPath;
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
      _tagsCtrl.text = tx.tags.join(', ');
      _selectedDate = tx.date;
      _paymentMethod = tx.paymentMethod ?? TransactionPaymentMethod.cash;
      _receiptPath = tx.receiptPath;
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
    _tagsCtrl.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  String get _type => switch (_tabController.index) {
    1 => 'income',
    2 => 'transfer',
    _ => 'expense',
  };

  bool get _isTransfer => _type == 'transfer';

  List<String> get _parsedTags => _tagsCtrl.text
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .toList();

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_titleCtrl.text.trim().isEmpty || _amountCtrl.text.isEmpty) {
      _showError('Please enter a title and amount.');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount.');
      return;
    }
    if (_selectedAccount == null) {
      _showError('Please select an account.');
      return;
    }
    if (_isTransfer &&
        (_destinationAccount == null ||
            _destinationAccount!.id == _selectedAccount!.id)) {
      _showError('Please choose a different destination account.');
      return;
    }
    if (!_isTransfer && _selectedCategory == null) {
      _showError('Please select a category.');
      return;
    }

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
        paymentMethod: _isTransfer ? null : _paymentMethod,
        tags: _isTransfer ? const [] : _parsedTags,
        receiptPath: _isTransfer ? null : _receiptPath,
        trackingStatus:
            widget.existing?.trackingStatus ?? TransactionTrackingStatus.normal,
        splits: widget.existing?.splits ?? const [],
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await provider.editTransaction(widget.existing!, tx);
      } else {
        await provider.addTransaction(tx);
      }

      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      }
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
                onTap: (_) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedCategory = null;
                    if (!_isTransfer) _destinationAccount = null;
                  });
                },
                indicator: BoxDecoration(
                  color: switch (_type) {
                    'expense' => AppTheme.expenseColor.withAlpha(51),
                    'income' => AppTheme.incomeColor.withAlpha(51),
                    _ => AppTheme.primaryColor.withAlpha(51),
                  },
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: switch (_type) {
                  'expense' => AppTheme.expenseColor,
                  'income' => AppTheme.incomeColor,
                  _ => AppTheme.primaryColor,
                },
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
                value: _selectedCategory == null
                    ? 'Select category'
                    : provider.categoryDisplayName(_selectedCategory),
                items: provider.getCategoriesForType(_type),
                onTap: () => _pickCategory(
                  provider.getCategoriesForType(_type),
                  onSelected: (cat) => setState(() => _selectedCategory = cat),
                ),
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

            if (!_isTransfer) ...[
              _buildPaymentMethodPicker(),
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

            if (!_isTransfer) ...[
              TextField(
                controller: _tagsCtrl,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  prefixIcon: Icon(Icons.sell_rounded, color: Colors.white38),
                ),
              ),
              const SizedBox(height: 12),
              _buildReceiptPicker(),
              const SizedBox(height: 12),
            ],

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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
                shadowColor: AppTheme.primaryColor.withAlpha(80),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Save Changes' : 'Add Transaction',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodPicker() {
    return _OptionPicker(
      label: 'Payment method',
      icon: Icons.payments_rounded,
      options: TransactionPaymentMethod.values,
      selected: _paymentMethod,
      labelFor: TransactionPaymentMethod.label,
      onSelected: (value) => setState(() => _paymentMethod = value),
    );
  }

  Widget _buildReceiptPicker() {
    final hasReceipt = _receiptPath != null && _receiptPath!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: Colors.white54,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasReceipt ? _receiptPath!.split('/').last : 'Attach receipt',
              style: TextStyle(
                color: hasReceipt ? Colors.white70 : Colors.white38,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasReceipt)
            IconButton(
              tooltip: 'Remove receipt',
              onPressed: () => setState(() => _receiptPath = null),
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white38,
                size: 18,
              ),
            ),
          IconButton(
            tooltip: hasReceipt ? 'Replace receipt' : 'Attach receipt',
            onPressed: _pickReceipt,
            icon: const Icon(
              Icons.attach_file_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickReceipt() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.single.path == null) return;
      final storedPath = await DatabaseService.saveReceiptImage(
        result.files.single.path!,
      );
      if (mounted) setState(() => _receiptPath = storedPath);
    } catch (e) {
      _showError('Receipt attach failed: $e');
    }
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

  Future<void> _pickCategory(
    List<CategoryModel> categories, {
    required ValueChanged<CategoryModel> onSelected,
  }) async {
    final result = await showModalBottomSheet<CategoryModel>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CategoryPickerSheet(type: _type, categories: categories),
    );
    if (result != null) onSelected(result);
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
      builder: (_) => ItemPickerSheet<AccountModel>(
        title: 'Select Account',
        items: accounts,
        builder: (acc) => PickerItem(
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

class _OptionPicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> options;
  final String selected;
  final String Function(String) labelFor;
  final ValueChanged<String> onSelected;

  const _OptionPicker({
    required this.label,
    required this.icon,
    required this.options,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: options.map((option) {
                  final isSelected = option == selected;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(labelFor(option)),
                      onSelected: (_) => onSelected(option),
                      selectedColor: AppTheme.primaryColor.withAlpha(64),
                      backgroundColor: AppTheme.elevatedSurfaceColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

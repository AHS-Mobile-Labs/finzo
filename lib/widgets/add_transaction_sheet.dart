import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/transaction_split_model.dart';
import '../models/category_model.dart';
import '../models/account_model.dart';
import '../providers/finance_provider.dart';
import '../services/database_service.dart';
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
  final _tagsCtrl = TextEditingController();
  final _amountFocusNode = FocusNode();
  DateTime _selectedDate = DateTime.now();
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  AccountModel? _destinationAccount;
  String _paymentMethod = TransactionPaymentMethod.cash;
  String _trackingStatus = TransactionTrackingStatus.normal;
  String? _receiptPath;
  final List<_SplitEntry> _splits = [];
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
      _trackingStatus = tx.trackingStatus;
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
      _splits.addAll(
        tx.splits.map(
          (split) => _SplitEntry(
            category: p.getCategoryById(split.categoryId),
            amount: split.amount,
          ),
        ),
      );
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
    for (final split in _splits) {
      split.dispose();
    }
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

  List<TransactionSplitModel>? _validatedSplits(double totalAmount) {
    if (_isTransfer || _splits.isEmpty) return const [];

    final splits = <TransactionSplitModel>[];
    var total = 0.0;
    for (final entry in _splits) {
      final amount = double.tryParse(entry.amountCtrl.text);
      if (entry.category == null || amount == null || amount <= 0) {
        _showError('Each split needs a category and amount.');
        return null;
      }
      total += amount;
      splits.add(
        TransactionSplitModel(
          id: entry.id,
          transactionId: widget.existing?.id ?? '',
          categoryId: entry.category!.id,
          amount: amount,
        ),
      );
    }

    if ((total - totalAmount).abs() > 0.01) {
      _showError('Split total must match the transaction amount.');
      return null;
    }
    return splits;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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
    if (!_isTransfer && _selectedCategory == null && _splits.isEmpty) return;

    final splits = _validatedSplits(amount);
    if (splits == null) return;

    setState(() => _submitting = true);

    try {
      final provider = context.read<FinanceProvider>();
      final tx = TransactionModel(
        id: widget.existing?.id ?? const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        amount: amount,
        type: _type,
        categoryId: _isTransfer
            ? 'cat_transfer'
            : splits.isNotEmpty
            ? splits.first.categoryId
            : _selectedCategory!.id,
        accountId: _selectedAccount!.id,
        relatedAccountId: _isTransfer ? _destinationAccount!.id : null,
        date: _selectedDate,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        paymentMethod: _isTransfer ? null : _paymentMethod,
        tags: _isTransfer ? const [] : _parsedTags,
        receiptPath: _isTransfer ? null : _receiptPath,
        trackingStatus: _isTransfer
            ? TransactionTrackingStatus.normal
            : _trackingStatus,
        splits: splits,
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
              _buildSplitSection(provider),
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
              _buildTrackingStatusPicker(),
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

  Widget _buildTrackingStatusPicker() {
    return _OptionPicker(
      label: 'Tracking',
      icon: Icons.assignment_turned_in_rounded,
      options: TransactionTrackingStatus.values,
      selected: _trackingStatus,
      labelFor: TransactionTrackingStatus.label,
      onSelected: (value) => setState(() => _trackingStatus = value),
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

  Widget _buildSplitSection(FinanceProvider provider) {
    final categories = provider.getCategoriesForType(_type);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.call_split_rounded,
                color: Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Split categories',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _addSplit(categories),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          if (_splits.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 2),
              child: Text(
                'Use this when one payment belongs to more than one category.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            ..._splits.map((entry) {
              final index = _splits.indexOf(entry);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () => _pickCategory(
                          categories,
                          onSelected: (cat) {
                            setState(() => entry.category = cat);
                          },
                        ),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.elevatedSurfaceColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                EmojiToIcon.getIcon(
                                  entry.category?.icon ?? 'box',
                                ),
                                color: entry.category == null
                                    ? Colors.white38
                                    : Color(entry.category!.color),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.category == null
                                      ? 'Category'
                                      : provider.categoryDisplayName(
                                          entry.category,
                                        ),
                                  style: TextStyle(
                                    color: entry.category == null
                                        ? Colors.white38
                                        : Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: entry.amountCtrl,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Amount',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove split',
                      onPressed: () => _removeSplit(index),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              );
            }),
            Text(
              'Split total: ${Formatters.currency(_splitDraftTotal)}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }

  double get _splitDraftTotal {
    return _splits.fold(0.0, (sum, entry) {
      return sum + (double.tryParse(entry.amountCtrl.text) ?? 0);
    });
  }

  void _addSplit(List<CategoryModel> categories) {
    setState(() {
      _splits.add(
        _SplitEntry(
          category:
              _selectedCategory ??
              (categories.isEmpty ? null : categories.first),
        ),
      );
    });
  }

  void _removeSplit(int index) {
    setState(() {
      final removed = _splits.removeAt(index);
      removed.dispose();
    });
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
      builder: (_) => _CategoryPickerSheet(type: _type, categories: categories),
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

class _SplitEntry {
  final String id;
  CategoryModel? category;
  final TextEditingController amountCtrl;

  _SplitEntry({this.category, double? amount})
    : id = const Uuid().v4(),
      amountCtrl = TextEditingController(
        text: amount == null ? '' : amount.toStringAsFixed(2),
      );

  void dispose() => amountCtrl.dispose();
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

class _CategoryPickerSheet extends StatefulWidget {
  final String type;
  final List<CategoryModel> categories;

  const _CategoryPickerSheet({required this.type, required this.categories});

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  String _query = '';
  late List<CategoryModel> _categories;

  @override
  void initState() {
    super.initState();
    _categories = [...widget.categories];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final query = _query.toLowerCase();
    final filtered = _categories.where((cat) {
      final name = provider.categoryDisplayName(cat).toLowerCase();
      return query.isEmpty || name.contains(query);
    }).toList();

    return FractionallySizedBox(
      heightFactor: .82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Category',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showCreateCategoryDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search categories',
                prefixIcon: Icon(Icons.search_rounded, color: Colors.white38),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.02,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: filtered.map((cat) {
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, cat),
                    child: _PickerItem(
                      icon: cat.icon,
                      label: provider.categoryDisplayName(cat),
                      color: Color(cat.color),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateCategoryDialog() async {
    final provider = context.read<FinanceProvider>();
    final nameCtrl = TextEditingController();
    var icon = widget.type == 'income' ? 'cash' : 'box';
    var color = widget.type == 'income' ? 0xFF4DDB6A : 0xFF654CFF;
    CategoryModel? parent;
    final parentOptions = provider.categories
        .where(
          (cat) =>
              cat.parentCategoryId == null &&
              (cat.type == widget.type || cat.type == 'both'),
        )
        .toList();

    final created = await showDialog<CategoryModel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: const Text('New Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CategoryModel?>(
                      initialValue: parent,
                      dropdownColor: AppTheme.cardColor,
                      decoration: const InputDecoration(
                        labelText: 'Parent category',
                      ),
                      items: [
                        const DropdownMenuItem<CategoryModel?>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...parentOptions.map(
                          (cat) => DropdownMenuItem<CategoryModel?>(
                            value: cat,
                            child: Text(provider.categoryDisplayName(cat)),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() => parent = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppConstants.categoryIcons.take(12).map((
                          iconName,
                        ) {
                          final isSelected = iconName == icon;
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setDialogState(() => icon = iconName);
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor.withAlpha(64)
                                    : AppTheme.elevatedSurfaceColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.white10,
                                ),
                              ),
                              child: Icon(
                                EmojiToIcon.getIcon(iconName),
                                size: 18,
                                color: Colors.white70,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        children: AppConstants.colorOptions.map((option) {
                          final isSelected = option == color;
                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              setDialogState(() => color = option);
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Color(option),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final category = CategoryModel(
                      id: const Uuid().v4(),
                      name: name,
                      icon: icon,
                      color: color,
                      type: widget.type,
                      parentCategoryId: parent?.id,
                    );
                    await provider.addCategory(category);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, category);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    if (created == null) return;
    setState(() => _categories.add(created));
    if (mounted) Navigator.pop(context, created);
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

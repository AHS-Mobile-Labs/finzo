import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/receipt_scan_model.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/emoji_to_icon.dart';
import '../utils/formatters.dart';

class ReceiptReviewScreen extends StatefulWidget {
  final ReceiptScanResult result;

  const ReceiptReviewScreen({super.key, required this.result});

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  final _merchantCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _itemsCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  String _paymentMethod = TransactionPaymentMethod.cash;
  bool _initialisedProviderFields = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final fields = widget.result.fields;
    _merchantCtrl.text = fields.merchantName ?? '';
    _amountCtrl.text = fields.totalAmount == null
        ? ''
        : fields.totalAmount!.toStringAsFixed(2);
    _taxCtrl.text = fields.taxAmount == null
        ? ''
        : fields.taxAmount!.toStringAsFixed(2);
    _itemsCtrl.text = fields.items
        .map((item) {
          final amount = item.amount == null
              ? ''
              : ' - ${item.amount!.toStringAsFixed(2)}';
          return '${item.name}$amount';
        })
        .join('\n');
    _selectedDate = fields.purchasedAt ?? DateTime.now();
    _paymentMethod = _guessPaymentMethod(widget.result.rawText);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialisedProviderFields) return;
    final provider = context.read<FinanceProvider>();
    if (provider.accounts.isNotEmpty) {
      _selectedAccount = provider.accounts.first;
    }
    _selectedCategory = provider.guessReceiptCategory(_merchantCtrl.text);
    _initialisedProviderFields = true;
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    _taxCtrl.dispose();
    _itemsCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final amount = double.tryParse(_amountCtrl.text);
    final duplicates = amount == null
        ? <TransactionModel>[]
        : provider.findPotentialDuplicateExpense(
            merchantName: _merchantCtrl.text,
            amount: amount,
            date: _selectedDate,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Review receipt')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReceiptImagePreview(path: widget.result.receiptPath),
              const SizedBox(height: 16),
              if (widget.result.rawText.isEmpty)
                const _ScannerNotice(
                  icon: Icons.text_fields_rounded,
                  text:
                      'No readable text was found. You can still save it manually.',
                ),
              if (duplicates.isNotEmpty) ...[
                _DuplicateNotice(duplicates: duplicates),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _merchantCtrl,
                onChanged: (_) => setState(() {
                  _selectedCategory = provider.guessReceiptCategory(
                    _merchantCtrl.text,
                  );
                }),
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Merchant',
                  prefixIcon: Icon(
                    Icons.storefront_rounded,
                    color: Colors.white38,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final valid = RegExp(
                      r'^\d*\.?\d{0,2}$',
                    ).hasMatch(newValue.text);
                    return valid ? newValue : oldValue;
                  }),
                ],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Total amount',
                  prefixIcon: Icon(
                    Icons.payments_rounded,
                    color: Colors.white38,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _DateTile(date: _selectedDate, onTap: _pickDate),
              const SizedBox(height: 12),
              _CategoryDropdown(
                provider: provider,
                selected: _selectedCategory,
                onChanged: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
              const SizedBox(height: 12),
              _AccountDropdown(
                accounts: provider.accounts,
                selected: _selectedAccount,
                onChanged: (account) {
                  setState(() => _selectedAccount = account);
                },
              ),
              const SizedBox(height: 12),
              _PaymentMethodPicker(
                selected: _paymentMethod,
                onSelected: (method) => setState(() => _paymentMethod = method),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taxCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final valid = RegExp(
                      r'^\d*\.?\d{0,2}$',
                    ).hasMatch(newValue.text);
                    return valid ? newValue : oldValue;
                  }),
                ],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'GST / tax',
                  prefixIcon: Icon(
                    Icons.receipt_rounded,
                    color: Colors.white38,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _itemsCtrl,
                minLines: 3,
                maxLines: 8,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Purchased items',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(
                    Icons.list_alt_rounded,
                    color: Colors.white38,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                minLines: 2,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded, color: Colors.white38),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saving ? null : () => _save(provider, duplicates),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Saving...' : 'Save Expense'),
              ),
            ],
          ),
        ),
      ),
    );
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
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _save(
    FinanceProvider provider,
    List<TransactionModel> duplicates,
  ) async {
    if (_saving) return;

    final title = _merchantCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text);
    if (title.isEmpty) {
      _showError('Merchant is required.');
      return;
    }
    if (amount == null || amount <= 0) {
      _showError('Enter a valid total amount.');
      return;
    }
    if (_selectedAccount == null) {
      _showError('Choose an account.');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Choose a category.');
      return;
    }

    var duplicateAction = _DuplicateAction.keepBoth;
    if (duplicates.isNotEmpty) {
      final action = await _askDuplicateAction(duplicates.first);
      if (action == null) return;
      duplicateAction = action;
    }

    if (duplicateAction == _DuplicateAction.ignore) {
      if (mounted) Navigator.pop(context, false);
      return;
    }

    setState(() => _saving = true);
    try {
      if (duplicateAction == _DuplicateAction.replace) {
        final existing = duplicates.first;
        await provider.editTransaction(
          existing,
          _buildTransaction(
            id: existing.id,
            createdAt: existing.createdAt,
            amount: amount,
          ),
        );
      } else {
        await provider.addTransaction(
          _buildTransaction(
            id: const Uuid().v4(),
            createdAt: DateTime.now(),
            amount: amount,
          ),
        );
      }

      await provider.rememberReceiptCategory(title, _selectedCategory!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Could not save receipt: $e');
    }
  }

  TransactionModel _buildTransaction({
    required String id,
    required DateTime createdAt,
    required double amount,
  }) {
    return TransactionModel(
      id: id,
      title: _merchantCtrl.text.trim(),
      amount: amount,
      type: 'expense',
      categoryId: _selectedCategory!.id,
      accountId: _selectedAccount!.id,
      date: _selectedDate,
      note: _buildNote(),
      paymentMethod: _paymentMethod,
      tags: const ['receipt'],
      receiptPath: widget.result.receiptPath,
      createdAt: createdAt,
    );
  }

  String? _buildNote() {
    final sections = <String>[];
    final tax = double.tryParse(_taxCtrl.text);
    if (tax != null && tax > 0) {
      sections.add('GST/Tax: ${tax.toStringAsFixed(2)}');
    }

    final items = _itemsCtrl.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (items.isNotEmpty) {
      sections.add('Items:\n${items.map((item) => '- $item').join('\n')}');
    }

    final note = _noteCtrl.text.trim();
    if (note.isNotEmpty) sections.add(note);

    return sections.isEmpty ? null : sections.join('\n\n');
  }

  Future<_DuplicateAction?> _askDuplicateAction(TransactionModel duplicate) {
    return showDialog<_DuplicateAction>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Possible duplicate found'),
        content: Text(
          '${duplicate.title}\n'
          '${Formatters.currency(duplicate.amount)} on '
          '${Formatters.dateFull(duplicate.date)}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _DuplicateAction.ignore),
            child: const Text('Ignore'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _DuplicateAction.keepBoth),
            child: const Text('Keep both'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _DuplicateAction.replace),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _guessPaymentMethod(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('upi')) return TransactionPaymentMethod.upi;
    if (lower.contains('card') ||
        lower.contains('visa') ||
        lower.contains('mastercard')) {
      return TransactionPaymentMethod.card;
    }
    if (lower.contains('bank')) return TransactionPaymentMethod.bank;
    return TransactionPaymentMethod.cash;
  }
}

enum _DuplicateAction { keepBoth, replace, ignore }

class _ReceiptImagePreview extends StatelessWidget {
  final String path;

  const _ReceiptImagePreview({required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.file(File(path), fit: BoxFit.contain),
    );
  }
}

class _ScannerNotice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ScannerNotice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withAlpha(28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warningColor.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.warningColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DuplicateNotice extends StatelessWidget {
  final List<TransactionModel> duplicates;

  const _DuplicateNotice({required this.duplicates});

  @override
  Widget build(BuildContext context) {
    final first = duplicates.first;
    return _ScannerNotice(
      icon: Icons.content_copy_rounded,
      text:
          'Possible duplicate: ${first.title}, '
          '${Formatters.currency(first.amount)} on '
          '${Formatters.dateFull(first.date)}',
    );
  }
}

class _DateTile extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateTile({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _SelectorContainer(
      icon: Icons.calendar_today_rounded,
      label: Formatters.dateFull(date),
      onTap: onTap,
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final FinanceProvider provider;
  final CategoryModel? selected;
  final ValueChanged<CategoryModel?> onChanged;

  const _CategoryDropdown({
    required this.provider,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = provider.getCategoriesForType('expense');
    return DropdownButtonFormField<String>(
      initialValue: selected?.id,
      dropdownColor: AppTheme.cardColor,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_rounded, color: Colors.white38),
      ),
      items: categories.map((category) {
        return DropdownMenuItem(
          value: category.id,
          child: Row(
            children: [
              Icon(
                EmojiToIcon.getIcon(category.icon),
                color: Color(category.color),
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(provider.categoryDisplayName(category))),
            ],
          ),
        );
      }).toList(),
      onChanged: (id) {
        onChanged(id == null ? null : provider.getCategoryById(id));
      },
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final List<AccountModel> accounts;
  final AccountModel? selected;
  final ValueChanged<AccountModel?> onChanged;

  const _AccountDropdown({
    required this.accounts,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selected?.id,
      dropdownColor: AppTheme.cardColor,
      decoration: const InputDecoration(
        labelText: 'Account',
        prefixIcon: Icon(
          Icons.account_balance_wallet_rounded,
          color: Colors.white38,
        ),
      ),
      items: accounts.map((account) {
        return DropdownMenuItem(
          value: account.id,
          child: Row(
            children: [
              Icon(
                EmojiToIcon.getIcon(account.icon),
                color: Color(account.color),
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(account.name)),
            ],
          ),
        );
      }).toList(),
      onChanged: (id) {
        final matches = accounts.where((account) => account.id == id);
        onChanged(matches.isEmpty ? null : matches.first);
      },
    );
  }
}

class _PaymentMethodPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _PaymentMethodPicker({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_rounded, color: Colors.white54, size: 18),
          const SizedBox(width: 10),
          const Text(
            'Payment',
            style: TextStyle(
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
                children: TransactionPaymentMethod.values.map((method) {
                  final isSelected = selected == method;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(TransactionPaymentMethod.label(method)),
                      onSelected: (_) => onSelected(method),
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

class _SelectorContainer extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SelectorContainer({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white70)),
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
}

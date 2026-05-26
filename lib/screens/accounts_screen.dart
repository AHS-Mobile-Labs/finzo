import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/account_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/emoji_to_icon.dart';
import '../utils/formatters.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final accounts = provider.accounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddSheet(context, provider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total balance
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Net Worth',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.currency(provider.totalBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${accounts.length} account${accounts.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'My Accounts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (accounts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No accounts yet',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            )
          else
            ...accounts.map(
              (acc) => _AccountCard(
                account: acc,
                onTap: () => _showEditSheet(context, provider, acc),
                onDelete: accounts.length > 1
                    ? () => _confirmDelete(context, provider, acc)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, FinanceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const _AccountSheet(),
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    FinanceProvider provider,
    AccountModel acc,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _AccountSheet(existing: acc),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FinanceProvider provider,
    AccountModel acc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete "${acc.name}"? This will not delete associated transactions.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await provider.removeAccount(acc.id);
  }
}

class _AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _AccountCard({required this.account, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = Color(account.color);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withAlpha(38),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  EmojiToIcon.getIcon(account.icon),
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Tap to edit',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(account.balance),
                  style: TextStyle(
                    color: account.balance >= 0
                        ? AppTheme.incomeColor
                        : AppTheme.expenseColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white24,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSheet extends StatefulWidget {
  final AccountModel? existing;
  const _AccountSheet({this.existing});

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  String _selectedIcon = 'cash';
  int _selectedColor = 0xFF6C63FF;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameCtrl.text = widget.existing!.name;
      _balanceCtrl.text = widget.existing!.balance.toString();
      _selectedIcon = widget.existing!.icon;
      _selectedColor = widget.existing!.color;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kbHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: kbHeight),
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
              _isEditing ? 'Edit Account' : 'New Account',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Icon preview
            Center(
              child: GestureDetector(
                onTap: _pickIcon,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Color(_selectedColor).withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(_selectedColor).withAlpha(102),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      EmojiToIcon.getIcon(_selectedIcon),
                      color: Color(_selectedColor),
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Color picker
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AppConstants.colorOptions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = AppConstants.colorOptions[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: _selectedColor == c
                            ? Border.all(color: Colors.white, width: 2.5)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                prefixIcon: Icon(Icons.label_rounded, color: Colors.white38),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balanceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Current Balance',
                prefixText:
                    '${context.read<FinanceProvider>().currency.symbol}  ',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isEditing ? 'Save Changes' : 'Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickIcon() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Pick an Icon',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: AppConstants.accountIcons
                .map(
                  (icon) => GestureDetector(
                    onTap: () => Navigator.pop(context, icon),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          EmojiToIcon.getIcon(icon),
                          color: AppTheme.primaryColor,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
    if (result != null) setState(() => _selectedIcon = result);
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final balance = double.tryParse(_balanceCtrl.text) ?? 0.0;
    final provider = context.read<FinanceProvider>();

    if (_isEditing) {
      await provider.editAccount(
        widget.existing!.copyWith(
          name: _nameCtrl.text.trim(),
          balance: balance,
          color: _selectedColor,
          icon: _selectedIcon,
        ),
      );
    } else {
      await provider.addAccount(
        AccountModel(
          id: const Uuid().v4(),
          name: _nameCtrl.text.trim(),
          balance: balance,
          color: _selectedColor,
          icon: _selectedIcon,
          createdAt: DateTime.now(),
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }
}

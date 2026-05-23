import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/credit_card_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/emoji_to_icon.dart';
import '../utils/formatters.dart';

class CreditCardsScreen extends StatelessWidget {
  const CreditCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final cards = provider.creditCards;

    return Scaffold(
      appBar: AppBar(title: const Text('Credit Cards')),
      body: cards.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_rounded,
                    size: 64,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Add your first credit card',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Start with card name and limit.',
                    style: TextStyle(
                      color: AppTheme.mutedTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(cards: cards),
                const SizedBox(height: 20),
                ...cards.map((c) => _CreditCardTile(card: c)),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCard(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Card'),
      ),
    );
  }

  void _showAddCard(BuildContext context, {CreditCardModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      requestFocus: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCardSheet(existing: existing),
    );
  }
}

// ─── Summary Card ──────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final List<CreditCardModel> cards;
  const _SummaryCard({required this.cards});

  @override
  Widget build(BuildContext context) {
    final totalLimit = cards.fold(0.0, (s, c) => s + c.creditLimit);
    final totalUsed = cards.fold(0.0, (s, c) => s + c.usedAmount);
    final totalAvailable = totalLimit - totalUsed;
    final utilization = totalLimit > 0 ? totalUsed / totalLimit : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B47F2), AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Credit',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(totalLimit),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: utilization.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(
                utilization > 0.7 ? Colors.redAccent : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryItem(
                label: 'Used',
                value: Formatters.currency(totalUsed),
                color: utilization > 0.7 ? Colors.redAccent : Colors.white70,
              ),
              const SizedBox(width: 24),
              _SummaryItem(
                label: 'Available',
                value: Formatters.currency(totalAvailable),
                color: AppTheme.incomeColor,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Card Tile ─────────────────────────────────────────────────────────────

class _CreditCardTile extends StatelessWidget {
  final CreditCardModel card;
  const _CreditCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final cardColor = Color(card.color);
    final statusColor = card.isHighUtilization
        ? AppTheme.expenseColor
        : card.usedPercent > .4
        ? AppTheme.warningColor
        : AppTheme.incomeColor;
    final statusText = card.isHighUtilization
        ? 'High usage'
        : card.usedPercent > .4
        ? 'In use'
        : 'Healthy';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCardActions(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cardColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      EmojiToIcon.getIcon(card.icon),
                      color: cardColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '•••• ${card.last4}',
                          style: const TextStyle(
                            color: Colors.white38,
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
                        Formatters.currency(card.usedAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: card.isHighUtilization
                              ? AppTheme.expenseColor
                              : AppTheme.primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'of ${Formatters.currency(card.creditLimit)}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: card.usedPercent,
                  minHeight: 4,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(28),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: 'Bill: ${card.billingDay}',
                  ),
                  _InfoChip(
                    icon: Icons.event_rounded,
                    label: 'Due: ${card.dueDay}',
                  ),
                  Text(
                    'Available: ${Formatters.currency(card.availableLimit)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  void _showCardActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.edit_rounded,
                color: AppTheme.primaryColor,
              ),
              title: const Text('Edit Card'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  requestFocus: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _AddCardSheet(existing: card),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_rounded,
                color: AppTheme.expenseColor,
              ),
              title: const Text('Delete Card'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Delete Card?'),
        content: Text('Remove "${card.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FinanceProvider>().removeCreditCard(card.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.expenseColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white38),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}

// ─── Add / Edit Card Sheet ─────────────────────────────────────────────────

class _AddCardSheet extends StatefulWidget {
  final CreditCardModel? existing;
  const _AddCardSheet({this.existing});

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _last4Ctrl;
  late final TextEditingController _limitCtrl;
  late final TextEditingController _usedCtrl;
  late final TextEditingController _billingCtrl;
  late final TextEditingController _dueCtrl;
  late final TextEditingController _noteCtrl;
  late int _selectedColor;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _last4Ctrl = TextEditingController(text: e?.last4 ?? '');
    _limitCtrl = TextEditingController(
      text: e != null ? e.creditLimit.toStringAsFixed(0) : '',
    );
    _usedCtrl = TextEditingController(
      text: e != null ? e.usedAmount.toStringAsFixed(0) : '',
    );
    _billingCtrl = TextEditingController(
      text: e != null ? e.billingDay.toString() : '1',
    );
    _dueCtrl = TextEditingController(
      text: e != null ? e.dueDay.toString() : '15',
    );
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _selectedColor = e?.color ?? AppConstants.colorOptions.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _last4Ctrl.dispose();
    _limitCtrl.dispose();
    _usedCtrl.dispose();
    _billingCtrl.dispose();
    _dueCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final limit = double.parse(_limitCtrl.text.trim());
    final used = double.tryParse(_usedCtrl.text.trim()) ?? 0;

    final card = CreditCardModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      last4: _last4Ctrl.text.trim().isEmpty ? '0000' : _last4Ctrl.text.trim(),
      creditLimit: limit,
      usedAmount: used.clamp(0, limit).toDouble(),
      billingDay: int.tryParse(_billingCtrl.text.trim()) ?? 1,
      dueDay: int.tryParse(_dueCtrl.text.trim()) ?? 15,
      color: _selectedColor,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<FinanceProvider>();
    if (_isEditing) {
      provider.editCreditCard(card);
    } else {
      provider.addCreditCard(card);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
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
              _isEditing ? 'Edit Credit Card' : 'Add Credit Card',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Only card name and limit are required.',
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Card Name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _last4Ctrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Last 4 Digits (optional)',
                hintText: '1234',
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (v.trim().length != 4 || int.tryParse(v.trim()) == null) {
                  return 'Enter valid 4 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _limitCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Credit Limit'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final value = double.tryParse(v.trim());
                if (value == null || value <= 0) return 'Enter valid limit';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usedCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Used Amount (optional)',
                hintText: '0',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final value = double.tryParse(v.trim());
                if (value == null || value < 0) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _billingCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Billing Day'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final d = int.tryParse(v.trim());
                      if (d == null || d < 1 || d > 31) return '1-31';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dueCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Due Day'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final d = int.tryParse(v.trim());
                      if (d == null || d < 1 || d > 31) return '1-31';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Card Color',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.colorOptions.map((c) {
                final isSelected = c == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isEditing ? 'Save Changes' : 'Add Card'),
            ),
          ],
        ),
      ),
    );
  }
}

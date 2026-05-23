import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/investment_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final investments = provider.investments;

    return Scaffold(
      appBar: AppBar(title: const Text('Investments')),
      body: investments.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 64,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Track your first investment',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Add a name and invested amount to start.',
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
                _InvestmentSummaryCard(investments: investments),
                const SizedBox(height: 20),
                ...investments.map((inv) => _InvestmentTile(investment: inv)),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddInvestment(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Investment'),
      ),
    );
  }

  void _showAddInvestment(BuildContext context, {InvestmentModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      requestFocus: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddInvestmentSheet(existing: existing),
    );
  }
}

class _InvestmentSummaryCard extends StatelessWidget {
  final List<InvestmentModel> investments;
  const _InvestmentSummaryCard({required this.investments});

  @override
  Widget build(BuildContext context) {
    final totalInvested = investments.fold(0.0, (s, i) => s + i.investedAmount);
    final totalCurrent = investments.fold(0.0, (s, i) => s + i.currentValue);
    final totalReturn = totalCurrent - totalInvested;
    final returnPct = totalInvested > 0
        ? (totalReturn / totalInvested) * 100
        : 0;
    final isProfit = totalReturn >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [AppTheme.incomeColor, const Color(0xFF5FE39A)]
              : [AppTheme.expenseColor, const Color(0xFFFF8E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? AppTheme.incomeColor : AppTheme.expenseColor)
                .withAlpha(62),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portfolio Value',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(totalCurrent),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invested',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Text(
                      Formatters.compact(totalInvested),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Returns',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Text(
                      '${isProfit ? '+' : ''}${Formatters.compact(totalReturn)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Return %',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Text(
                      '${isProfit ? '+' : ''}${returnPct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _InvestmentTile extends StatelessWidget {
  final InvestmentModel investment;
  const _InvestmentTile({required this.investment});

  @override
  Widget build(BuildContext context) {
    final color = Color(investment.type.color);
    final isProfit = investment.isProfit;

    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(investment.type.iconData, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investment.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      investment.type.label,
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Invested: ${Formatters.compact(investment.investedAmount)}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(investment.currentValue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (isProfit
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseColor)
                              .withAlpha(38),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${isProfit ? '+' : ''}${investment.returnPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isProfit
                            ? AppTheme.incomeColor
                            : AppTheme.expenseColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final provider = context.read<FinanceProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 20),
            Text(
              investment.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              investment.type.label,
              style: TextStyle(color: Color(investment.type.color)),
            ),
            const Divider(height: 24),
            _row('Invested', Formatters.currency(investment.investedAmount)),
            _row('Current Value', Formatters.currency(investment.currentValue)),
            _row(
              'Returns',
              '${investment.isProfit ? '+' : ''}${Formatters.currency(investment.returnAmount)} (${investment.returnPercent.toStringAsFixed(1)}%)',
            ),
            if (investment.units != null)
              _row('Units', investment.units!.toStringAsFixed(4)),
            if (investment.buyPrice != null)
              _row('Buy Price', Formatters.currency(investment.buyPrice!)),
            if (investment.currentPrice != null)
              _row(
                'Current Price',
                Formatters.currency(investment.currentPrice!),
              ),
            _row('Start Date', Formatters.dateFull(investment.startDate)),
            if (investment.note != null && investment.note!.isNotEmpty)
              _row('Note', investment.note!),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        requestFocus: true,
                        builder: (_) =>
                            _AddInvestmentSheet(existing: investment),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      provider.removeInvestment(investment.id);
                    },
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.expenseColor,
                      side: const BorderSide(color: AppTheme.expenseColor),
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ADD/EDIT INVESTMENT SHEET ──────────────────────────────────────────────

class _AddInvestmentSheet extends StatefulWidget {
  final InvestmentModel? existing;
  const _AddInvestmentSheet({this.existing});

  @override
  State<_AddInvestmentSheet> createState() => _AddInvestmentSheetState();
}

class _AddInvestmentSheetState extends State<_AddInvestmentSheet> {
  final _nameCtrl = TextEditingController();
  final _investedCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController();
  final _buyPriceCtrl = TextEditingController();
  final _currentPriceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  InvestmentType _type = InvestmentType.mutualFund;
  DateTime _startDate = DateTime.now();
  bool _showAdvanced = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final i = widget.existing!;
      _nameCtrl.text = i.name;
      _investedCtrl.text = i.investedAmount.toStringAsFixed(0);
      _currentCtrl.text = i.currentValue.toStringAsFixed(0);
      _unitsCtrl.text = i.units?.toString() ?? '';
      _buyPriceCtrl.text = i.buyPrice?.toString() ?? '';
      _currentPriceCtrl.text = i.currentPrice?.toString() ?? '';
      _noteCtrl.text = i.note ?? '';
      _type = i.type;
      _startDate = i.startDate;
      _showAdvanced =
          i.units != null ||
          i.buyPrice != null ||
          i.currentPrice != null ||
          (i.note?.isNotEmpty ?? false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _investedCtrl.dispose();
    _currentCtrl.dispose();
    _unitsCtrl.dispose();
    _buyPriceCtrl.dispose();
    _currentPriceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final invested = double.tryParse(_investedCtrl.text) ?? 0;
    final current = double.tryParse(_currentCtrl.text) ?? 0;

    if (name.isEmpty || invested <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill in required fields')));
      return;
    }

    final provider = context.read<FinanceProvider>();
    final now = DateTime.now();

    final units = double.tryParse(_unitsCtrl.text);
    final buyPrice = double.tryParse(_buyPriceCtrl.text);
    final currentPrice = double.tryParse(_currentPriceCtrl.text);

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        name: name,
        type: _type,
        investedAmount: invested,
        currentValue: current > 0 ? current : invested,
        units: units,
        buyPrice: buyPrice,
        currentPrice: currentPrice,
        startDate: _startDate,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      provider.editInvestment(updated);
    } else {
      final inv = InvestmentModel(
        id: const Uuid().v4(),
        name: name,
        type: _type,
        investedAmount: invested,
        currentValue: current > 0 ? current : invested,
        units: units,
        buyPrice: buyPrice,
        currentPrice: currentPrice,
        startDate: _startDate,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        createdAt: now,
      );
      provider.addInvestment(inv);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              _isEditing ? 'Edit Investment' : 'Add Investment',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Type selector
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: InvestmentType.values.map((t) {
                  final selected = t == _type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(
                        t.iconData,
                        color: selected ? Colors.white : Colors.white54,
                        size: 16,
                      ),
                      label: Text(
                        t.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : Colors.white54,
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) => setState(() => _type = t),
                      selectedColor: Color(t.color).withAlpha(77),
                      backgroundColor: AppTheme.cardColor,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'SIP, stock, gold, FD...',
                prefixIcon: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white38,
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _investedCtrl,
              decoration: const InputDecoration(
                labelText: 'Invested Amount',
                prefixText: '₹  ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _currentCtrl,
              decoration: const InputDecoration(
                labelText: 'Current Value (optional)',
                hintText: 'Leave empty to use invested amount',
                prefixText: '₹  ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),

            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  prefixIcon: Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white38,
                  ),
                ),
                child: Text(
                  Formatters.dateShort(_startDate),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),

            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _showAdvanced,
              activeThumbColor: AppTheme.primaryColor,
              title: const Text(
                'Add units, prices, or note',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              onChanged: (value) => setState(() => _showAdvanced = value),
            ),

            if (_showAdvanced) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _unitsCtrl,
                      decoration: const InputDecoration(labelText: 'Units'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _buyPriceCtrl,
                      decoration: const InputDecoration(labelText: 'Buy Price'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _currentPriceCtrl,
                decoration: const InputDecoration(labelText: 'Current Price'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  prefixIcon: Icon(Icons.notes_rounded, color: Colors.white38),
                ),
                maxLines: 2,
              ),
            ] else ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.warningColor,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tip: current value can be updated anytime from edit.',
                        style: TextStyle(
                          color: AppTheme.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(
                  _isEditing ? 'Update Investment' : 'Add Investment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

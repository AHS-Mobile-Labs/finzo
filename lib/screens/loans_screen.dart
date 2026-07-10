import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/loan_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/emoji_to_icon.dart';
import '../utils/formatters.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final loans = provider.loans;

    return Scaffold(
      appBar: AppBar(title: const Text('Loans')),
      body: loans.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_rounded,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No loans added yet',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _LoanSummaryCard(loans: loans),
                const SizedBox(height: 20),
                ...loans.map((loan) => _LoanTile(loan: loan)),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLoan(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Loan'),
      ),
    );
  }

  void _showAddLoan(BuildContext context, {LoanModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddLoanSheet(existing: existing),
    );
  }
}

class _LoanSummaryCard extends StatelessWidget {
  final List<LoanModel> loans;
  const _LoanSummaryCard({required this.loans});

  @override
  Widget build(BuildContext context) {
    final totalPrincipal = loans.fold(0.0, (s, l) => s + l.principalAmount);
    final totalOutstanding = loans.fold(0.0, (s, l) => s + l.outstandingAmount);
    final totalEmi = loans.fold(0.0, (s, l) => s + l.emiAmount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.expenseColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.expenseColor.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Outstanding',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(totalOutstanding),
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
                      'Principal',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Text(
                      Formatters.compact(totalPrincipal),
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
                      'Monthly EMI',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Text(
                      Formatters.compact(totalEmi),
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
                      'Active Loans',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Text(
                      '${loans.length}',
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

class _LoanTile extends StatelessWidget {
  final LoanModel loan;
  const _LoanTile({required this.loan});

  @override
  Widget build(BuildContext context) {
    final color = Color(loan.type.color);

    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLoanDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withAlpha(38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(loan.type.iconData, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loan.type.label,
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.currency(loan.outstandingAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'EMI: ${Formatters.compact(loan.emiAmount)}',
                        style: const TextStyle(
                          color: Colors.white54,
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
                  value: loan.progressPercent,
                  backgroundColor: Colors.white.withAlpha(25),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(loan.progressPercent * 100).toStringAsFixed(1)}% paid',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    '${loan.interestRate}% p.a.',
                    style: TextStyle(color: color, fontSize: 11),
                  ),
                  if (loan.autoEmi)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.incomeColor.withAlpha(38),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Auto EMI',
                        style: TextStyle(
                          color: AppTheme.incomeColor,
                          fontSize: 9,
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

  void _showLoanDetail(BuildContext context) {
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
              loan.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              loan.type.label,
              style: TextStyle(color: Color(loan.type.color)),
            ),
            const Divider(height: 24),
            _detailRow('Principal', Formatters.currency(loan.principalAmount)),
            _detailRow(
              'Outstanding',
              Formatters.currency(loan.outstandingAmount),
            ),
            _detailRow('EMI Amount', Formatters.currency(loan.emiAmount)),
            _detailRow('Interest Rate', '${loan.interestRate}% p.a.'),
            _detailRow('Tenure', '${loan.tenureMonths} months'),
            _detailRow('EMI Day', '${loan.emiDay} of each month'),
            _detailRow('Start Date', Formatters.dateFull(loan.startDate)),
            _detailRow('Auto EMI', loan.autoEmi ? 'Enabled' : 'Disabled'),
            if (loan.note != null && loan.note!.isNotEmpty)
              _detailRow('Note', loan.note!),
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
                        builder: (_) => _AddLoanSheet(existing: loan),
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
                      provider.removeLoan(loan.id);
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ADD/EDIT LOAN SHEET ────────────────────────────────────────────────────

class _AddLoanSheet extends StatefulWidget {
  final LoanModel? existing;
  const _AddLoanSheet({this.existing});

  @override
  State<_AddLoanSheet> createState() => _AddLoanSheetState();
}

class _AddLoanSheetState extends State<_AddLoanSheet> {
  final _nameCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _tenureCtrl = TextEditingController();
  final _emiCtrl = TextEditingController();
  final _emiDayCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  LoanType _type = LoanType.unsecured;
  DateTime _startDate = DateTime.now();
  String? _accountId;
  bool _autoEmi = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final l = widget.existing!;
      _nameCtrl.text = l.name;
      _principalCtrl.text = l.principalAmount.toStringAsFixed(0);
      _rateCtrl.text = l.interestRate.toString();
      _tenureCtrl.text = l.tenureMonths.toString();
      _emiCtrl.text = l.emiAmount.toStringAsFixed(0);
      _emiDayCtrl.text = l.emiDay.toString();
      _noteCtrl.text = l.note ?? '';
      _type = l.type;
      _startDate = l.startDate;
      _accountId = l.accountId;
      _autoEmi = l.autoEmi;
    } else {
      _emiDayCtrl.text = '1';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _tenureCtrl.dispose();
    _emiCtrl.dispose();
    _emiDayCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _calcEmi() {
    final p = double.tryParse(_principalCtrl.text) ?? 0;
    final r = (double.tryParse(_rateCtrl.text) ?? 0) / 12 / 100;
    final n = int.tryParse(_tenureCtrl.text) ?? 0;
    if (p > 0 && r > 0 && n > 0) {
      final emi = p * r * _pow(1 + r, n) / (_pow(1 + r, n) - 1);
      _emiCtrl.text = emi.toStringAsFixed(0);
    }
  }

  double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final principal = double.tryParse(_principalCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    final tenure = int.tryParse(_tenureCtrl.text) ?? 0;
    final emi = double.tryParse(_emiCtrl.text) ?? 0;
    final emiDay = int.tryParse(_emiDayCtrl.text) ?? 1;

    if (name.isEmpty || principal <= 0 || emi <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill in required fields')));
      return;
    }

    final provider = context.read<FinanceProvider>();
    final now = DateTime.now();

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        name: name,
        type: _type,
        principalAmount: principal,
        outstandingAmount:
            widget.existing!.outstandingAmount, // keep as-is on edit
        interestRate: rate,
        tenureMonths: tenure,
        emiAmount: emi,
        emiDay: emiDay.clamp(1, 28),
        startDate: _startDate,
        accountId: _accountId,
        autoEmi: _autoEmi,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      provider.editLoan(updated);
    } else {
      final loan = LoanModel(
        id: const Uuid().v4(),
        name: name,
        type: _type,
        principalAmount: principal,
        outstandingAmount: principal,
        interestRate: rate,
        tenureMonths: tenure,
        emiAmount: emi,
        emiDay: emiDay.clamp(1, 28),
        startDate: _startDate,
        accountId: _accountId,
        autoEmi: _autoEmi,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        createdAt: now,
      );
      provider.addLoan(loan);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.read<FinanceProvider>().accounts;
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
              _isEditing ? 'Edit Loan' : 'Add Loan',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Loan type selector
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: LoanType.values.map((t) {
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
              decoration: const InputDecoration(labelText: 'Loan Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _principalCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Principal Amount',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calcEmi(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _rateCtrl,
                    decoration: const InputDecoration(labelText: 'Interest %'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => _calcEmi(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tenureCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tenure (months)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calcEmi(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _emiCtrl,
                    decoration: const InputDecoration(labelText: 'EMI Amount'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emiDayCtrl,
                    decoration: const InputDecoration(
                      labelText: 'EMI Day (1-28)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
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
                      ),
                      child: Text(
                        Formatters.dateShort(_startDate),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Account selector for auto EMI
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: const InputDecoration(
                labelText: 'Account (for Auto EMI)',
              ),
              dropdownColor: AppTheme.cardColor,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('None', style: TextStyle(color: Colors.white54)),
                ),
                ...accounts.map(
                  (a) => DropdownMenuItem(
                    value: a.id,
                    child: Row(
                      children: [
                        Icon(
                          EmojiToIcon.getIcon(a.icon),
                          color: Color(a.color),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(a.name),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Auto EMI', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Automatically add EMI as expense each month',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              value: _autoEmi,
              onChanged: (v) => setState(() => _autoEmi = v),
              activeTrackColor: AppTheme.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Update Loan' : 'Add Loan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

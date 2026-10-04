import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/emoji_to_icon.dart';
import '../utils/formatters.dart';
import '../widgets/animated_amount.dart';
import '../widgets/pressable_card.dart';
import '../widgets/transaction_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static String _greeting(String name) {
    final hour = DateTime.now().hour;
    final suffix = name.isNotEmpty ? ', $name' : '';
    if (hour < 12) return 'Good morning$suffix';
    if (hour < 17) return 'Good afternoon$suffix';
    return 'Good evening$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 92,
          backgroundColor: AppTheme.backgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
            title: Text(
              _greeting(provider.userName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _NetWorthHero(provider: provider),
              const SizedBox(height: 14),
              _InsightStrip(provider: provider),
              if (provider.smartFinancialInsights.isNotEmpty) ...[
                const SizedBox(height: 14),
                _SmartInsightBanner(
                  insight: provider.smartFinancialInsights.first,
                ),
              ],
              const SizedBox(height: 14),
              _CashflowChart(provider: provider),
              const SizedBox(height: 14),
              _BudgetAndCategory(provider: provider),
              const SizedBox(height: 14),
              _AccountsSnapshot(provider: provider),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'Recent activity'),
              const SizedBox(height: 8),
              if (provider.recentTransactions.isEmpty)
                const _EmptyTransactions()
              else
                ...provider.recentTransactions
                    .take(8)
                    .map(
                      (tx) =>
                          TransactionTile(
                                transaction: tx,
                                category: provider.getCategoryById(
                                  tx.categoryId,
                                ),
                                account: provider.getAccountById(tx.accountId),
                                relatedAccount: tx.relatedAccountId == null
                                    ? null
                                    : provider.getAccountById(
                                        tx.relatedAccountId!,
                                      ),
                              )
                              .animate()
                              .fadeIn(duration: 220.ms)
                              .slideY(begin: .08, end: 0),
                    ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _NetWorthHero extends StatelessWidget {
  final FinanceProvider provider;
  const _NetWorthHero({required this.provider});

  @override
  Widget build(BuildContext context) {
    final savings = provider.monthlySavings;
    final momentum = provider.cashflowMomentum;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(25)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(65),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      height: 3.5,
                      width: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: AppTheme.brandGradient,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Net Worth',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
              _Pill(
                icon: momentum >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                label:
                    '${momentum >= 0 ? '+' : ''}${momentum.toStringAsFixed(0)}%',
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedAmount(
              value: provider.netWorth,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 35,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Balance',
                  value: Formatters.compact(provider.totalBalance),
                  amount: provider.totalBalance,
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  label: 'Invested',
                  value: Formatters.compact(provider.totalInvestmentValue),
                  amount: provider.totalInvestmentValue,
                  icon: Icons.show_chart_rounded,
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  label: savings >= 0 ? 'Saved' : 'Gap',
                  value: Formatters.compact(savings.abs()),
                  amount: savings.abs(),
                  icon: savings >= 0
                      ? Icons.savings_rounded
                      : Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 360.ms).slideY(begin: .08, end: 0);
  }
}

class _InsightStrip extends StatelessWidget {
  final FinanceProvider provider;
  const _InsightStrip({required this.provider});

  @override
  Widget build(BuildContext context) {
    final healthScore = provider.calculatedHealthScore;
    final healthColor = healthScore >= 75
        ? AppTheme.incomeColor
        : healthScore >= 50
        ? const Color(0xFFFFB800)
        : AppTheme.expenseColor;

    return Row(
      children: [
        Expanded(
          child: _InsightCard(
            title: 'Savings rate',
            value: '${provider.savingsRate.toStringAsFixed(0)}%',
            icon: Icons.speed_rounded,
            color: provider.savingsRate >= 20
                ? AppTheme.incomeColor
                : const Color(0xFFFFB800),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InsightCard(
            title: 'Health score',
            value: '$healthScore/100',
            icon: Icons.shield_rounded,
            color: healthColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InsightCard(
            title: 'Daily pace',
            value: provider.remainingDailyBudgetLimit > 0
                ? '${Formatters.compact(provider.remainingDailyBudgetLimit)}/d'
                : Formatters.compact(provider.averageDailyExpense),
            icon: Icons.timeline_rounded,
            color: AppTheme.infoColor,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 80.ms, duration: 320.ms);
  }
}

class _SmartInsightBanner extends StatelessWidget {
  final FinancialInsight insight;
  const _SmartInsightBanner({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: insight.color.withAlpha(55)),
        boxShadow: [
          BoxShadow(
            color: insight.color.withAlpha(20),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: insight.color.withAlpha(35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                EmojiToIcon.getIcon(insight.icon),
                color: insight.color,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        insight.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: insight.color.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        insight.badge,
                        style: TextStyle(
                          color: insight.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 320.ms).slideY(begin: .04);
  }
}

class _CashflowChart extends StatelessWidget {
  final FinanceProvider provider;
  const _CashflowChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = provider.last6Months;
    final maxVal = data.fold<double>(0, (max, d) {
      final income = d['income'] as double;
      final expense = d['expense'] as double;
      return [max, income, expense].reduce((a, b) => a > b ? a : b);
    });

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Cashflow pulse'),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: data.isEmpty
                ? const Center(
                    child: Text(
                      'No cashflow data yet',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxVal <= 0 ? 10 : maxVal * 1.2,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            const FlLine(color: Colors.white10, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, _) {
                              final i = value.toInt();
                              if (i < 0 || i >= data.length) {
                                return const SizedBox();
                              }
                              final date = DateTime(
                                data[i]['year'] as int,
                                data[i]['month'] as int,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  Formatters.month(date),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        _line(data, 'income', AppTheme.incomeColor),
                        _line(data, 'expense', AppTheme.expenseColor),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _Legend(color: AppTheme.incomeColor, label: 'Income'),
              SizedBox(width: 18),
              _Legend(color: AppTheme.expenseColor, label: 'Expense'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 140.ms, duration: 340.ms).slideY(begin: .05);
  }

  LineChartBarData _line(
    List<Map<String, dynamic>> data,
    String key,
    Color color,
  ) {
    return LineChartBarData(
      spots: List.generate(
        data.length,
        (i) => FlSpot(i.toDouble(), data[i][key] as double),
      ),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withAlpha(20)),
    );
  }
}

class _BudgetAndCategory extends StatelessWidget {
  final FinanceProvider provider;
  const _BudgetAndCategory({required this.provider});

  @override
  Widget build(BuildContext context) {
    final top = provider.topSpendingCategory;
    final topName = top == null ? 'No spending yet' : top['name'] as String;
    final topIcon = top == null ? 'box' : top['icon'] as String;
    final topAmount = top == null
        ? Formatters.currency(0)
        : Formatters.currency((top['total'] as num).toDouble());

    return Row(
      children: [
        Expanded(
          child: _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: 'Budget health'),
                const SizedBox(height: 14),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: provider.budgetUsage),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 9,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        provider.overBudgetCount > 0
                            ? AppTheme.expenseColor
                            : AppTheme.incomeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${Formatters.compact(provider.totalBudgetSpent)} of ${Formatters.compact(provider.totalBudget)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.overBudgetCount > 0
                      ? '${provider.overBudgetCount} category over budget'
                      : 'Categories are on track',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: 'Top spend'),
                const SizedBox(height: 12),
                Icon(
                  EmojiToIcon.getIcon(topIcon),
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  topName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topAmount,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 340.ms);
  }
}

class _AccountsSnapshot extends StatelessWidget {
  final FinanceProvider provider;
  const _AccountsSnapshot({required this.provider});

  @override
  Widget build(BuildContext context) {
    final accounts = provider.accountDistribution.take(4).toList();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Account mix'),
          const SizedBox(height: 12),
          if (accounts.isEmpty)
            const Text(
              'Positive account balances will appear here.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            )
          else
            ...accounts.map((account) {
              final color = Color(account['color'] as int);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Icon(
                        EmojiToIcon.getIcon(account['icon'] as String),
                        color: Color(account['color'] as int),
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  account['name'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                Formatters.compact(
                                  account['balance'] as double,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: account['percentage'] as double,
                              minHeight: 5,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    ).animate().fadeIn(delay: 260.ms, duration: 340.ms).slideY(begin: .04);
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: child,
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final double? amount;
  final IconData icon;

  const _HeroMetric({
    required this.label,
    required this.value,
    this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
              if (amount != null)
                AnimatedAmount(
                  value: amount!,
                  mode: AmountDisplayMode.compact,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                )
              else
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_rounded, color: Colors.white30, size: 44),
          SizedBox(height: 10),
          Text(
            'No transactions yet',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          SizedBox(height: 3),
          Text(
            'Use the add button to record your first entry.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

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

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Health'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _OverviewTab(),
          _CategoriesTab(
            touchedIndex: _touchedIndex,
            onTouch: (i) => setState(() => _touchedIndex = i),
          ),
          const _HealthTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final data = provider.last6Months;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      children: [
        _MetricGrid(provider: provider),
        const SizedBox(height: 14),
        _Rule503020Card(provider: provider),
        const SizedBox(height: 14),
        _EmergencyRunwayCard(provider: provider),
        const SizedBox(height: 14),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Six month trend'),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: data.isEmpty
                    ? const _EmptyState(text: 'No report data yet')
                    : BarChart(_barData(data)),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  _Legend(color: AppTheme.incomeColor, label: 'Income'),
                  SizedBox(width: 18),
                  _Legend(color: AppTheme.expenseColor, label: 'Expense'),
                  SizedBox(width: 18),
                  _Legend(color: Color(0xFF21C7A8), label: 'Savings'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _MonthlyBreakdown(),
      ],
    );
  }

  BarChartData _barData(List<Map<String, dynamic>> data) {
    final maxVal = data.fold<double>(0, (max, d) {
      final income = d['income'] as double;
      final expense = d['expense'] as double;
      return [max, income, expense].reduce((a, b) => a > b ? a : b);
    });

    return BarChartData(
      maxY: maxVal <= 0 ? 10 : maxVal * 1.25,
      barTouchData: BarTouchData(enabled: true),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: Colors.white10, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (value, _) => Text(
              Formatters.compact(value),
              style: const TextStyle(color: Colors.white38, fontSize: 9),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, _) {
              final i = value.toInt();
              if (i < 0 || i >= data.length) return const SizedBox();
              final month = DateTime(
                data[i]['year'] as int,
                data[i]['month'] as int,
              );
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  Formatters.month(month),
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barGroups: List.generate(data.length, (i) {
        final income = data[i]['income'] as double;
        final expense = data[i]['expense'] as double;
        final savings = income - expense;
        return BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: income,
              color: AppTheme.incomeColor,
              width: 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: expense,
              color: AppTheme.expenseColor,
              width: 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: savings > 0 ? savings : 0,
              color: const Color(0xFF21C7A8),
              width: 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final FinanceProvider provider;
  const _MetricGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.55,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricCard(
          title: 'Monthly income',
          value: Formatters.compact(provider.monthlyIncome),
          icon: Icons.arrow_downward_rounded,
          color: AppTheme.incomeColor,
        ),
        _MetricCard(
          title: 'Monthly expense',
          value: Formatters.compact(provider.monthlyExpense),
          icon: Icons.arrow_upward_rounded,
          color: AppTheme.expenseColor,
        ),
        _MetricCard(
          title: 'Savings rate',
          value: '${provider.savingsRate.toStringAsFixed(1)}%',
          icon: Icons.savings_rounded,
          color: provider.savingsRate >= 0
              ? const Color(0xFF21C7A8)
              : AppTheme.expenseColor,
        ),
        _MetricCard(
          title: 'Projection',
          value: Formatters.compact(provider.projectedMonthlyExpense),
          icon: Icons.auto_graph_rounded,
          color: AppTheme.primaryColor,
        ),
      ],
    ).animate().fadeIn(duration: 280.ms).slideY(begin: .04);
  }
}

class _CategoriesTab extends StatelessWidget {
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _CategoriesTab({required this.touchedIndex, required this.onTouch});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final spending = provider.categorySpending;
    final total = spending.fold<double>(
      0,
      (sum, d) => sum + (d['total'] as num).toDouble(),
    );

    if (spending.isEmpty || total <= 0) {
      return const _EmptyState(text: 'No expense data this month');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _Panel(
              child: Column(
                children: [
                  SizedBox(
                    height: 238,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 54,
                        sectionsSpace: 3,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            final index =
                                response?.touchedSection?.touchedSectionIndex ??
                                -1;
                            onTouch(index);
                          },
                        ),
                        sections: spending.asMap().entries.map((entry) {
                          final i = entry.key;
                          final d = entry.value;
                          final amount = (d['total'] as num).toDouble();
                          final pct = amount / total;
                          final isTouched = touchedIndex == i;
                          return PieChartSectionData(
                            color: Color(d['color'] as int),
                            value: amount,
                            title: isTouched
                                ? '${(pct * 100).toStringAsFixed(1)}%'
                                : '',
                            radius: isTouched ? 82 : 66,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            badgeWidget: isTouched
                                ? Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Color(d['color'] as int),
                                      shape: BoxShape.circle,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black54,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      EmojiToIcon.getIcon(d['icon'] as String),
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                            badgePositionPercentageOffset: 1.25,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Text(
                    Formatters.currency(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Total category spend',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(.98, .98)),
        const SizedBox(height: 14),
        const _SectionTitle('Category drilldown'),
        const SizedBox(height: 10),
        ...spending.asMap().entries.map((entry) {
          final d = entry.value;
          final amount = (d['total'] as num).toDouble();
          final pct = amount / total;
          final color = Color(d['color'] as int);
          return _CategoryRow(
            icon: d['icon'] as String,
            name: d['name'] as String,
            amount: amount,
            percent: pct,
            color: color,
            selected: touchedIndex == entry.key,
          );
        }),
      ],
    );
  }
}

class _HealthTab extends StatelessWidget {
  const _HealthTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final budgetStatus = provider.totalBudget == 0
        ? 'Create budgets to unlock stronger spend control.'
        : provider.overBudgetCount > 0
        ? '${provider.overBudgetCount} budget categories need attention.'
        : 'Budget usage is healthy this month.';

    final savingsStatus = provider.savingsRate >= 20
        ? 'Savings rate is strong (${provider.savingsRate.toStringAsFixed(0)}%).'
        : provider.savingsRate >= 0
        ? 'Savings are positive, but there is room to improve.'
        : 'Expenses are higher than income this month.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _HealthScore(provider: provider),
        const SizedBox(height: 14),
        _PillarBreakdownCard(provider: provider),
        if (provider.smartFinancialInsights.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SmartInsightsList(insights: provider.smartFinancialInsights),
        ],
        const SizedBox(height: 14),
        const _SectionTitle('Actionable Recommendations'),
        const SizedBox(height: 10),
        _Recommendation(
          icon: Icons.savings_rounded,
          title: 'Savings Pace',
          body: savingsStatus,
          color: provider.savingsRate >= 0
              ? AppTheme.incomeColor
              : AppTheme.expenseColor,
        ),
        _Recommendation(
          icon: Icons.donut_large_rounded,
          title: 'Budget Discipline',
          body: budgetStatus,
          color: provider.overBudgetCount > 0
              ? AppTheme.expenseColor
              : AppTheme.primaryColor,
        ),
        _Recommendation(
          icon: Icons.calendar_month_rounded,
          title: 'Emergency Cushion',
          body:
              'Current liquid funds cover ${provider.emergencyFundMonths.toStringAsFixed(1)} months of living expenses (${provider.emergencyRunwayStatus}).',
          color: const Color(0xFF38BDF8),
        ),
        _Recommendation(
          icon: Icons.account_balance_rounded,
          title: 'Net Worth Standing',
          body:
              'Assets minus loans currently stands at ${Formatters.currency(provider.netWorth)}.',
          color: const Color(0xFFFFB800),
        ),
      ],
    );
  }
}

class _HealthScore extends StatelessWidget {
  final FinanceProvider provider;
  const _HealthScore({required this.provider});

  @override
  Widget build(BuildContext context) {
    final score = provider.calculatedHealthScore;
    final color = score >= 80
        ? AppTheme.incomeColor
        : score >= 60
        ? const Color(0xFF38BDF8)
        : score >= 40
        ? const Color(0xFFFFB800)
        : AppTheme.expenseColor;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle('Financial Health Score'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  score >= 80
                      ? 'Exceptional'
                      : score >= 60
                      ? 'Strong'
                      : score >= 40
                      ? 'Moderate'
                      : 'Needs Attention',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: score / 100),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: value,
                          strokeWidth: 10,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                        Center(
                          child: Text(
                            '$score',
                            style: TextStyle(
                              color: color,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score >= 80
                          ? 'Exceptional Stability'
                          : score >= 60
                          ? 'Strong Position'
                          : score >= 40
                          ? 'Moderate, Watch Trends'
                          : 'Action Needed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Evaluated across 4 key pillars: Savings Rate, Budget Discipline, Emergency Runway, and Cost Balance.',
                      style: TextStyle(
                        color: Colors.white.withAlpha(140),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: .05);
  }
}

class _MonthlyBreakdown extends StatelessWidget {
  const _MonthlyBreakdown();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FinanceProvider>().last6Months.reversed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Monthly breakdown'),
        const SizedBox(height: 10),
        ...data.map((d) {
          final income = d['income'] as double;
          final expense = d['expense'] as double;
          final savings = income - expense;
          final month = DateTime(d['year'] as int, d['month'] as int);
          return _Panel(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    Formatters.monthYear(month),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _AmountColumn(
                  label: 'In',
                  amount: income,
                  color: AppTheme.incomeColor,
                ),
                const SizedBox(width: 14),
                _AmountColumn(
                  label: 'Out',
                  amount: expense,
                  color: AppTheme.expenseColor,
                ),
                const SizedBox(width: 14),
                _AmountColumn(
                  label: 'Saved',
                  amount: savings,
                  color: savings >= 0
                      ? const Color(0xFF21C7A8)
                      : AppTheme.expenseColor,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String icon;
  final String name;
  final double amount;
  final double percent;
  final Color color;
  final bool selected;

  const _CategoryRow({
    required this.icon,
    required this.name,
    required this.amount,
    required this.percent,
    required this.color,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? color.withAlpha(36) : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? color : Colors.white.withAlpha(14),
        ),
      ),
      child: Row(
        children: [
          Icon(EmojiToIcon.getIcon(icon), color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${(percent * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0).toDouble(),
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Formatters.compact(amount),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Recommendation extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _Recommendation({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Panel(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(34),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 260.ms).slideX(begin: .04);
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AmountColumn({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        AnimatedAmount(
          value: amount,
          mode: AmountDisplayMode.compact,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
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
            borderRadius: BorderRadius.circular(3),
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

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insights_rounded, color: Colors.white30, size: 48),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _Rule503020Card extends StatelessWidget {
  final FinanceProvider provider;
  const _Rule503020Card({required this.provider});

  @override
  Widget build(BuildContext context) {
    final needs = provider.needsSpending;
    final wants = provider.wantsSpending;
    final savings = provider.monthlySavings > 0 ? provider.monthlySavings : 0.0;
    final total = needs + wants + savings;

    final needsPct = total > 0 ? (needs / total) * 100 : 0.0;
    final wantsPct = total > 0 ? (wants / total) * 100 : 0.0;
    final savingsPct = total > 0 ? (savings / total) * 100 : 0.0;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle('50/30/20 Rule Analysis'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Golden Rule',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Target: 50% Needs, 30% Wants, 20% Savings',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: total <= 0
                  ? Container(color: Colors.white12)
                  : Row(
                      children: [
                        if (needsPct > 0)
                          Expanded(
                            flex: (needsPct * 10).round().clamp(1, 1000),
                            child: Container(color: const Color(0xFF38BDF8)),
                          ),
                        if (wantsPct > 0)
                          Expanded(
                            flex: (wantsPct * 10).round().clamp(1, 1000),
                            child: Container(color: const Color(0xFFFFB800)),
                          ),
                        if (savingsPct > 0)
                          Expanded(
                            flex: (savingsPct * 10).round().clamp(1, 1000),
                            child: Container(color: AppTheme.incomeColor),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          _AllocationRow(
            label: 'Needs (Essentials)',
            target: 'Target 50%',
            actualPct: needsPct,
            amount: needs,
            color: const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 8),
          _AllocationRow(
            label: 'Wants (Lifestyle)',
            target: 'Target 30%',
            actualPct: wantsPct,
            amount: wants,
            color: const Color(0xFFFFB800),
          ),
          const SizedBox(height: 8),
          _AllocationRow(
            label: 'Savings & Growth',
            target: 'Target 20%',
            actualPct: savingsPct,
            amount: savings,
            color: AppTheme.incomeColor,
          ),
        ],
      ),
    );
  }
}

class _AllocationRow extends StatelessWidget {
  final String label;
  final String target;
  final double actualPct;
  final double amount;
  final Color color;

  const _AllocationRow({
    required this.label,
    required this.target,
    required this.actualPct,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                target,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${actualPct.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              Formatters.compact(amount),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmergencyRunwayCard extends StatelessWidget {
  final FinanceProvider provider;
  const _EmergencyRunwayCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final runway = provider.emergencyFundMonths;
    final status = provider.emergencyRunwayStatus;
    final burn = provider.averageHistoricalMonthlyExpense;

    final color = runway >= 6.0
        ? AppTheme.incomeColor
        : runway >= 3.0
        ? const Color(0xFF38BDF8)
        : runway >= 1.0
        ? const Color(0xFFFFB800)
        : AppTheme.expenseColor;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Emergency Runway'),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withAlpha(60)),
                ),
                child: Text(
                  '${runway.toStringAsFixed(1)} mo',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (runway / 6.0).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Liquid Cash: ${Formatters.compact(provider.totalBalance)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Monthly Burn: ${Formatters.compact(burn)}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillarBreakdownCard extends StatelessWidget {
  final FinanceProvider provider;
  const _PillarBreakdownCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final savingsScore = (provider.savingsRate.clamp(0.0, 30.0) / 30.0) * 30.0;
    double budgetScore = 20.0;
    if (provider.totalBudget > 0) {
      budgetScore = (1.0 - provider.budgetUsage).clamp(0.0, 1.0) * 30.0;
      if (provider.overBudgetCount > 0) {
        budgetScore = (budgetScore - (provider.overBudgetCount * 5.0)).clamp(
          0.0,
          30.0,
        );
      }
    }
    double safetyScore = provider.emergencyFundMonths >= 6.0
        ? 15.0
        : provider.emergencyFundMonths >= 3.0
        ? 12.0
        : provider.emergencyFundMonths >= 1.0
        ? 8.0
        : 3.0;
    if (provider.totalLoanOutstanding <= 0) {
      safetyScore += 10.0;
    } else if (provider.netWorth > provider.totalLoanOutstanding * 1.5) {
      safetyScore += 7.0;
    } else if (provider.netWorth > 0) {
      safetyScore += 4.0;
    }
    double livingScore = 10.0;
    if (provider.monthlyExpense > 0) {
      if (provider.wantsExpensePercentage <= 35.0) {
        livingScore = 15.0;
      } else if (provider.wantsExpensePercentage <= 50.0) {
        livingScore = 10.0;
      } else {
        livingScore = 5.0;
      }
    }

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('4-Pillar Health Breakdown'),
          const SizedBox(height: 14),
          _PillarRow(
            label: 'Savings Rate Score',
            score: savingsScore.round(),
            maxScore: 30,
            metric: '${provider.savingsRate.toStringAsFixed(0)}% (Goal: >20%)',
            color: AppTheme.incomeColor,
          ),
          const SizedBox(height: 12),
          _PillarRow(
            label: 'Budget Discipline',
            score: budgetScore.round(),
            maxScore: 30,
            metric: provider.totalBudget > 0
                ? '${(provider.budgetUsage * 100).toStringAsFixed(0)}% used'
                : 'No budget set',
            color: const Color(0xFF635BFF),
          ),
          const SizedBox(height: 12),
          _PillarRow(
            label: 'Emergency & Debt Safety',
            score: safetyScore.round(),
            maxScore: 25,
            metric:
                '${provider.emergencyFundMonths.toStringAsFixed(1)} mo runway',
            color: const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 12),
          _PillarRow(
            label: 'Living Cost Balance',
            score: livingScore.round(),
            maxScore: 15,
            metric:
                '${provider.wantsExpensePercentage.toStringAsFixed(0)}% discretionary',
            color: const Color(0xFFFFB800),
          ),
        ],
      ),
    );
  }
}

class _PillarRow extends StatelessWidget {
  final String label;
  final int score;
  final int maxScore;
  final String metric;
  final Color color;

  const _PillarRow({
    required this.label,
    required this.score,
    required this.maxScore,
    required this.metric,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (score / maxScore).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$score / $maxScore pts',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: color.withAlpha(35),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          metric,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SmartInsightsList extends StatelessWidget {
  final List<FinancialInsight> insights;
  const _SmartInsightsList({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Smart Financial Insights'),
        const SizedBox(height: 10),
        ...insights.map((insight) {
          return PressableCard(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: insight.color.withAlpha(50)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: insight.color.withAlpha(35),
                      borderRadius: BorderRadius.circular(10),
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
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
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
            ),
          );
        }),
      ],
    );
  }
}

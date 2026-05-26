import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/emoji_to_icon.dart';
import '../utils/formatters.dart';

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
                                ? Text(
                                    d['icon'] as String,
                                    style: const TextStyle(fontSize: 18),
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
        ? 'Savings rate is strong.'
        : provider.savingsRate >= 0
        ? 'Savings are positive, but there is room to improve.'
        : 'Expenses are higher than income this month.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _HealthScore(provider: provider),
        const SizedBox(height: 14),
        _Recommendation(
          icon: Icons.savings_rounded,
          title: 'Savings',
          body: savingsStatus,
          color: provider.savingsRate >= 0
              ? AppTheme.incomeColor
              : AppTheme.expenseColor,
        ),
        _Recommendation(
          icon: Icons.donut_large_rounded,
          title: 'Budgets',
          body: budgetStatus,
          color: provider.overBudgetCount > 0
              ? AppTheme.expenseColor
              : AppTheme.primaryColor,
        ),
        _Recommendation(
          icon: Icons.calendar_month_rounded,
          title: 'Daily pace',
          body:
              'Average daily expense is ${Formatters.compact(provider.averageDailyExpense)}; projected month end is ${Formatters.compact(provider.projectedMonthlyExpense)}.',
          color: const Color(0xFF21C7A8),
        ),
        _Recommendation(
          icon: Icons.account_balance_rounded,
          title: 'Net worth',
          body:
              'Assets minus loans currently stands at ${Formatters.currency(provider.netWorth)}.',
          color: const Color(0xFFFFB020),
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
    final savingsPoints =
        ((provider.savingsRate.clamp(0, 30).toDouble() / 30) * 40);
    final budgetPoints = provider.totalBudget == 0
        ? 15
        : ((1 - provider.budgetUsage).clamp(0, 1).toDouble() * 35);
    final debtPoints = provider.totalLoanOutstanding <= 0
        ? 25
        : ((provider.netWorth > 0 ? .7 : .25) * 25);
    final score = (savingsPoints + budgetPoints + debtPoints).round();
    final color = score >= 75
        ? AppTheme.incomeColor
        : score >= 50
        ? const Color(0xFFFFB020)
        : AppTheme.expenseColor;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Financial health score'),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 11,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Center(
                      child: Text(
                        '$score',
                        style: TextStyle(
                          color: color,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score >= 75
                          ? 'Strong position'
                          : score >= 50
                          ? 'Stable, watch trends'
                          : 'Needs attention',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Based on savings rate, budget usage, and debt pressure.',
                      style: TextStyle(
                        color: Colors.white.withAlpha(125),
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
        Text(
          Formatters.compact(amount),
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

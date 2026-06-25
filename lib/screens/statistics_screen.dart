import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrow_lend.dart';
import '../models/shared_entry_model.dart';
import '../providers/shared_entry_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SharedEntryProvider>();
    final entries = provider.activeEntries;
    final userId = provider.currentUserId;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: entries.isEmpty
          ? Center(
              child: Text(
                'Add some entries to see statistics.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(
                  theme: theme,
                  title: 'Monthly Totals',
                  child: SizedBox(
                    height: 220,
                    child: _MonthlyBarChart(entries: entries, userId: userId),
                  ),
                ),
                const SizedBox(height: 16),
                _Section(
                  theme: theme,
                  title: 'Payment Status',
                  child: SizedBox(
                    height: 220,
                    child: _PaidPieChart(entries: entries),
                  ),
                ),
                const SizedBox(height: 16),
                _Section(
                  theme: theme,
                  title: 'Debt History',
                  child: SizedBox(
                    height: 220,
                    child: _DebtLineChart(entries: entries, userId: userId),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final Widget child;

  const _Section({
    required this.theme,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<SharedEntry> entries;
  final String userId;

  const _MonthlyBarChart({required this.entries, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelColor = colorScheme.onSurface;

    final primaryCurrency = AppConstants.defaultCurrency;

    final monthMap = <String, _MonthTotal>{};
    for (final entry in entries) {
      final key = '${entry.createdAt.year}-'
          '${entry.createdAt.month.toString().padLeft(2, '0')}';
      final total = monthMap.putIfAbsent(
        key,
        () => _MonthTotal(
          year: entry.createdAt.year,
          month: entry.createdAt.month,
        ),
      );
      if (entry.entryTypeFor(userId) == EntryType.borrow) {
        total.borrowed += entry.amount;
      } else {
        total.lent += entry.amount;
      }
    }

    final sorted = monthMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final totals = <_MonthTotal>[];
    for (int i = 0; i < sorted.length; i++) {
      sorted[i].value.index = i;
      totals.add(sorted[i].value);
    }

    if (totals.isEmpty) {
      return const Center(child: Text('No monthly data'));
    }

    final maxAmount = totals.fold<double>(
      0,
      (prev, t) => [prev, t.borrowed, t.lent].reduce(
        (a, b) => a > b ? a : b,
      ),
    );

    if (maxAmount == 0) {
      return const Center(child: Text('No monthly data'));
    }

    final labelInterval = totals.length > 8
        ? (totals.length / 6).ceil()
        : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: maxAmount * 1.25,
              minY: 0,
              barGroups: totals.map((t) {
                return BarChartGroupData(
                  x: t.index,
                  barRods: [
                    BarChartRodData(
                      toY: t.borrowed,
                      color: AppColors.chartBorrow,
                      width: 10,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: t.lent,
                      color: AppColors.chartLend,
                      width: 10,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= totals.length) {
                        return const SizedBox();
                      }
                      if (labelInterval > 1 && idx % labelInterval != 0) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _monthAbbr(totals[idx].month),
                          style: TextStyle(
                            fontSize: 10,
                            color: labelColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: maxAmount / 2,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox();
                      return Text(
                        '${value.toInt()} $primaryCurrency',
                        style: TextStyle(
                          fontSize: 10,
                          color: labelColor,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxAmount / 2,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  strokeWidth: 0.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: AppColors.chartBorrow, label: 'Borrowed'),
            const SizedBox(width: 20),
            _LegendDot(color: AppColors.chartLend, label: 'Lent'),
          ],
        ),
      ],
    );
  }
}

class _PaidPieChart extends StatelessWidget {
  final List<SharedEntry> entries;

  const _PaidPieChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final primaryCurrency = AppConstants.defaultCurrency;

    double paid = 0, unpaid = 0;
    for (final entry in entries) {
      if (entry.status == EntryStatus.paid) {
        paid += entry.amount;
      } else {
        unpaid += entry.amount;
      }
    }

    final total = paid + unpaid;
    if (total == 0) {
      return const Center(child: Text('No payment data'));
    }

    final paidPct = (paid / total * 100).toStringAsFixed(1);
    final unpaidPct = (unpaid / total * 100).toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: paid,
                  color: AppColors.chartPaid,
                  title: '$paidPct%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: unpaid,
                  color: AppColors.chartUnpaid,
                  title: '$unpaidPct%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendDot(
              color: AppColors.chartPaid,
              label: 'Paid ($primaryCurrency ${paid.toStringAsFixed(3)})',
            ),
            const SizedBox(height: 10),
            _LegendDot(
              color: AppColors.chartUnpaid,
              label: 'Unpaid ($primaryCurrency ${unpaid.toStringAsFixed(3)})',
            ),
          ],
        ),
      ],
    );
  }
}

class _DebtLineChart extends StatelessWidget {
  final List<SharedEntry> entries;
  final String userId;

  const _DebtLineChart({required this.entries, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelColor = colorScheme.onSurface;

    final primaryCurrency = AppConstants.defaultCurrency;

    final sorted = List<SharedEntry>.from(entries)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    double cumulative = 0;
    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      if (entry.entryTypeFor(userId) == EntryType.borrow) {
        cumulative += entry.amount;
      } else {
        cumulative -= entry.amount;
      }
      spots.add(FlSpot(i.toDouble(), cumulative));
    }

    if (spots.isEmpty) {
      return const Center(child: Text('No debt history'));
    }

    if (spots.length == 1) {
      final y = spots.first.y;
      spots.add(FlSpot(1, y));
    }

    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs();
    final padding = range > 0 ? range * 0.15 : 100;

    final yRange = maxY - minY;
    final yInterval = yRange > 0 ? yRange / 2 : 1.0;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppColors.chartLine,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.chartLine.withValues(alpha: 0.1),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox();
                }
                return Text(
                  '${value.toInt()} $primaryCurrency',
                  style: TextStyle(
                    fontSize: 10,
                    color: labelColor,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 0.5,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _MonthTotal {
  final int year;
  final int month;
  double borrowed = 0;
  double lent = 0;
  int index = 0;

  _MonthTotal({required this.year, required this.month});
}

const _monthNames = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _monthAbbr(int month) => month >= 1 && month <= 12
    ? _monthNames[month]
    : '';

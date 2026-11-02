import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/practice_models.dart';
import '../utils/date_utils.dart';

/// Biểu đồ cột: số phút học mỗi ngày, có đường mục tiêu.
class StudyMinutesChart extends StatelessWidget {
  const StudyMinutesChart({super.key, required this.days, required this.goalMinutes, this.height = 180});

  final List<DailyProgress> days;
  final int goalMinutes;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxMinutes = days.fold<double>(goalMinutes.toDouble(), (m, d) => math.max(m, d.studyMinutes));
    final maxY = (maxMinutes * 1.25).ceilToDouble().clamp(5.0, 600.0);
    final showEvery = days.length > 10 ? 5 : 1;
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant.withValues(alpha: 0.4), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: goalMinutes.toDouble(),
              color: scheme.tertiary,
              strokeWidth: 1.5,
              dashArray: const [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(color: scheme.tertiary, fontSize: 11),
                labelResolver: (_) => 'Mục tiêu $goalMinutes′',
              ),
            ),
          ]),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: maxY / 4,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(v.round().toString(), style: const TextStyle(fontSize: 10)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= days.length || (days.length - 1 - i) % showEvery != 0) return const SizedBox.shrink();
                  final d = parseDateKey(days[i].date);
                  final label = days.length > 10 ? '${d.day}/${d.month}' : weekdayShort(d);
                  return SideTitleWidget(meta: meta, child: Text(label, style: const TextStyle(fontSize: 10)));
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)} phút',
                TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w600),
              ),
              getTooltipColor: (_) => scheme.inverseSurface,
            ),
          ),
          barGroups: [
            for (var i = 0; i < days.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: days[i].studyMinutes,
                  width: days.length > 10 ? 6 : 16,
                  borderRadius: BorderRadius.circular(4),
                  color: days[i].goalMet ? const Color(0xFF16A34A) : scheme.primary,
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

/// Biểu đồ đường: điểm phát âm trung bình mỗi ngày.
class ScoreTrendChart extends StatelessWidget {
  const ScoreTrendChart({super.key, required this.days, this.height = 170});

  final List<DailyProgress> days;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spots = <FlSpot>[
      for (var i = 0; i < days.length; i++)
        if (days[i].averageScore != null) FlSpot(i.toDouble(), days[i].averageScore!),
    ];
    if (spots.isEmpty) {
      return SizedBox(height: height, child: const Center(child: Text('Chưa có dữ liệu điểm')));
    }
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          minX: 0,
          maxX: (days.length - 1).toDouble(),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant.withValues(alpha: 0.4), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 25,
                getTitlesWidget: (v, meta) =>
                    SideTitleWidget(meta: meta, child: Text(v.round().toString(), style: const TextStyle(fontSize: 10))),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  final every = days.length > 10 ? 5 : 1;
                  if (i < 0 || i >= days.length || (days.length - 1 - i) % every != 0) return const SizedBox.shrink();
                  final d = parseDateKey(days[i].date);
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(days.length > 10 ? '${d.day}/${d.month}' : weekdayShort(d), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: scheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: scheme.primary.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lịch luyện tập dạng ô màu (giống GitHub): đậm = học nhiều / đạt mục tiêu.
class PracticeCalendar extends StatelessWidget {
  const PracticeCalendar({super.key, required this.days});

  /// Các ngày liên tục, ngày cuối là hôm nay.
  final List<DailyProgress> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (days.isEmpty) return const SizedBox.shrink();
    final first = parseDateKey(days.first.date);
    final leading = first.weekday - 1; // căn cột theo thứ 2
    final cells = <Widget>[
      for (final w in const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'])
        Center(child: Text(w, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (final d in days)
        Tooltip(
          message: '${d.date}: ${d.studyMinutes.toStringAsFixed(1)} phút, ${d.attemptCount} lượt',
          child: Container(
            decoration: BoxDecoration(
              color: !d.practiced
                  ? scheme.surfaceContainerHighest
                  : d.goalMet
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF16A34A).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              '${parseDateKey(d.date).day}',
              style: TextStyle(fontSize: 10, color: d.goalMet ? Colors.white : scheme.onSurfaceVariant),
            ),
          ),
        ),
    ];
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }
}

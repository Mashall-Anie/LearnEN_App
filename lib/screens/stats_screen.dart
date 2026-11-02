import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/practice_models.dart';
import '../pronunciation/phoneme_inventory.dart';
import '../services/streak_calculator.dart';
import '../state/app_state.dart';
import '../utils/date_utils.dart';
import '../widgets/progress_charts.dart';

class _StatsData {
  const _StatsData({
    required this.days,
    required this.calendar,
    required this.phonemes,
    required this.confusions,
    required this.totals,
    required this.streak,
  });

  final List<DailyProgress> days;
  final List<DailyProgress> calendar;
  final List<PhonemeStat> phonemes;
  final List<(String, String?, String, int)> confusions;
  final StudyTotals totals;
  final StreakInfo streak;
}

/// Thống kê tiến độ học tập: thời gian, điểm, lịch luyện tập, độ chính xác từng âm.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _range = 7;
  Object? _version;
  int? _loadedRange;
  Future<_StatsData>? _future;

  Future<_StatsData> _load(AppState s) async {
    final user = s.currentUser!;
    final now = s.clock();
    final repo = s.database.progress;
    final days = await repo.getRange(user.id!, addDays(now, -(_range - 1)), now, goalMinutes: user.dailyGoalMinutes);
    final calendar = await repo.getRange(user.id!, addDays(now, -34), now, goalMinutes: user.dailyGoalMinutes);
    final phonemes = (await repo.getPhonemeStats(user.id!)).where((p) => p.totalCount >= 2).toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return _StatsData(
      days: days,
      calendar: calendar,
      phonemes: phonemes,
      confusions: await repo.getTopConfusions(user.id!),
      totals: await repo.getTotals(user.id!),
      streak: StreakCalculator.compute(await repo.getPracticeDays(user.id!), now),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final version = context.select<AppState, Object?>((s) => s.dashboard);
    if (_future == null || !identical(version, _version) || _loadedRange != _range) {
      _version = version;
      _loadedRange = _range;
      _future = _load(state);
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê tiến độ')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final d = snap.data!;
          final rangeSeconds = d.days.fold<int>(0, (s, e) => s + e.studySeconds);
          final rangeAttempts = d.days.fold<int>(0, (s, e) => s + e.attemptCount);
          final goalDays = d.days.where((e) => e.goalMet).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 ngày')),
                  ButtonSegment(value: 30, label: Text('30 ngày')),
                ],
                selected: {_range},
                onSelectionChanged: (s) => setState(() => _range = s.first),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: [
                  _Tile(icon: Icons.timer_outlined, label: 'Thời gian học', value: formatDuration(rangeSeconds)),
                  _Tile(icon: Icons.mic_none, label: 'Lượt luyện', value: '$rangeAttempts'),
                  _Tile(icon: Icons.flag_outlined, label: 'Ngày đạt mục tiêu', value: '$goalDays/$_range'),
                  _Tile(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Streak / kỷ lục',
                    value: '${d.streak.current} / ${d.streak.longest}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Thời gian học mỗi ngày (phút)',
                child: StudyMinutesChart(days: d.days, goalMinutes: state.currentUser!.dailyGoalMinutes),
              ),
              _Section(title: 'Điểm phát âm trung bình', child: ScoreTrendChart(days: d.days)),
              _Section(
                title: 'Lịch luyện tập 5 tuần',
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  _Legend(color: const Color(0xFF16A34A).withValues(alpha: 0.4), text: 'Có học'),
                  const SizedBox(width: 8),
                  const _Legend(color: Color(0xFF16A34A), text: 'Đạt mục tiêu'),
                ]),
                child: PracticeCalendar(days: d.calendar),
              ),
              _Section(
                title: 'Độ chính xác theo âm',
                child: d.phonemes.isEmpty
                    ? Text('Chưa đủ dữ liệu.', style: TextStyle(color: theme.hintColor))
                    : Column(
                        children: [
                          for (final p in d.phonemes.take(12))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  SizedBox(width: 48, child: Text('/${ipaOf(p.phoneme)}/', style: const TextStyle(fontWeight: FontWeight.w600))),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: p.accuracy,
                                        minHeight: 10,
                                        color: scoreColor(context, p.accuracy * 100),
                                        backgroundColor: scoreColor(context, p.accuracy * 100).withValues(alpha: 0.15),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 70,
                                    child: Text('${(p.accuracy * 100).round()}% (${p.totalCount})',
                                        textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              if (d.confusions.isNotEmpty)
                _Section(
                  title: 'Lỗi hay gặp nhất',
                  child: Column(
                    children: [
                      for (final (exp, act, type, n) in d.confusions)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.error_outline),
                          title: Text(type == 'deletion'
                              ? 'Bỏ sót âm /${ipaOf(exp)}/'
                              : 'Đọc /${ipaOf(exp)}/ thành /${act == null ? '?' : ipaOf(act)}/'),
                          trailing: Text('$n lần'),
                        ),
                    ],
                  ),
                ),
              _Section(
                title: 'Tổng kết từ khi bắt đầu',
                child: Text(
                  'Đã học ${formatDuration(d.totals.totalSeconds)} trong ${d.totals.practiceDays} ngày, '
                  '${d.totals.totalAttempts} lượt nói. Điểm trung bình ${d.totals.averageScore?.round() ?? '–'}, '
                  'cao nhất ${d.totals.bestScore?.round() ?? '–'}.',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                  Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor), maxLines: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
                ?trailing,
              ]),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 11)),
    ]);
  }
}

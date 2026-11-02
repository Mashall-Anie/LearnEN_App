import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/lesson_catalog.dart';
import '../pronunciation/phoneme_inventory.dart';
import '../state/app_state.dart';
import '../utils/date_utils.dart';
import '../widgets/progress_charts.dart';
import '../widgets/score_ring.dart';
import 'lessons_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenLessons});

  final VoidCallback onOpenLessons;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser!;
    final d = state.dashboard;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chào ${user.name} ${user.avatar}'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: () => state.refreshDashboard(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: d == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: state.refreshDashboard,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Row(
                    children: [
                      Expanded(child: _StreakCard(data: d)),
                      const SizedBox(width: 12),
                      Expanded(child: _GoalCard(data: d)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _QuickActions(data: d, onOpenLessons: onOpenLessons),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Text('Thời gian học 7 ngày qua (phút)', style: theme.textTheme.titleSmall),
                          ),
                          StudyMinutesChart(days: d.last7Days, goalMinutes: user.dailyGoalMinutes),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WeakPhonemesCard(data: d),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat(label: 'Tổng thời gian', value: formatDuration(d.totals.totalSeconds)),
                          _Stat(label: 'Lượt luyện', value: '${d.totals.totalAttempts}'),
                          _Stat(label: 'Ngày đã học', value: '${d.totals.practiceDays}'),
                          _Stat(
                            label: 'Điểm TB',
                            value: d.totals.averageScore == null ? '–' : d.totals.averageScore!.round().toString(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final s = data.streak;
    final theme = Theme.of(context);
    final active = s.practicedToday;
    return Card(
      color: active ? const Color(0xFFFFEDD5) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chuỗi ngày', style: theme.textTheme.labelLarge?.copyWith(color: active ? Colors.black87 : null)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(active ? '🔥' : '🕯️', style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 6),
                Text('${s.current}',
                    style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800, color: active ? const Color(0xFFEA580C) : null)),
              ],
            ),
            Text('Kỷ lục: ${s.longest} ngày', style: TextStyle(color: active ? Colors.black54 : theme.hintColor)),
            const SizedBox(height: 4),
            Text(
              active
                  ? 'Hôm nay đã luyện ✓'
                  : s.atRisk
                      ? 'Luyện ngay để giữ chuỗi!'
                      : 'Bắt đầu chuỗi mới hôm nay',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: active ? const Color(0xFF16A34A) : (s.atRisk ? theme.colorScheme.error : theme.hintColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = data.today;
    final theme = Theme.of(context);
    final minutes = (t.studySeconds / 60).floor();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mục tiêu hôm nay', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: data.goalProgress,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      color: t.goalMet ? const Color(0xFF16A34A) : theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                    Center(
                      child: Text(t.goalMet ? '✓' : '$minutes/${t.goalMinutes}′',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('${t.attemptCount} lượt · TB ${t.averageScore?.round() ?? '–'} điểm',
                style: TextStyle(color: theme.hintColor)),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.data, required this.onOpenLessons});

  final DashboardData data;
  final VoidCallback onOpenLessons;

  @override
  Widget build(BuildContext context) {
    // Gợi ý bài học: ưu tiên âm yếu nhất, nếu chưa có dữ liệu thì bài đầu tiên.
    int lessonId = LessonIds.th;
    for (final w in data.weakPhonemes) {
      final id = lessonIdForPhoneme(w.phoneme);
      if (id != null) {
        lessonId = id;
        break;
      }
    }
    final lesson = lessonSeedById(lessonId)!;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.weakPhonemes.isEmpty ? 'Bắt đầu học' : 'Gợi ý cho bạn',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text('${lesson.icon}  ${lesson.title}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(lesson.description),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => openLessonPractice(context, lessonId),
                  icon: const Icon(Icons.mic),
                  label: const Text('Luyện ngay'),
                ),
                OutlinedButton.icon(
                  onPressed: () => openFreePractice(context),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Tự luyện câu bất kỳ'),
                ),
                TextButton(onPressed: onOpenLessons, child: const Text('Tất cả bài học')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeakPhonemesCard extends StatelessWidget {
  const _WeakPhonemesCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Âm cần cải thiện', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (data.weakPhonemes.isEmpty)
              Text('Luyện thêm vài câu để AI tìm ra các âm bạn hay phát âm sai.', style: TextStyle(color: theme.hintColor))
            else
              for (final w in data.weakPhonemes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('/${ipaOf(w.phoneme)}/', style: const TextStyle(fontSize: 13))),
                  title: Text('Đúng ${(w.accuracy * 100).round()}%  ·  sai ${w.errorCount}/${w.totalCount} lần'),
                  subtitle: Text('Ví dụ: ${phonemeInfo(w.phoneme)?.example ?? ''}'),
                  trailing: lessonIdForPhoneme(w.phoneme) == null
                      ? null
                      : TextButton(
                          onPressed: () => openLessonPractice(context, lessonIdForPhoneme(w.phoneme)!),
                          child: const Text('Luyện'),
                        ),
                ),
            if (data.weakPhonemes.isNotEmpty) ...[
              const SizedBox(height: 4),
              SubScoreBar(label: 'Âm yếu nhất', value: data.weakPhonemes.first.accuracy * 100),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
      ],
    );
  }
}

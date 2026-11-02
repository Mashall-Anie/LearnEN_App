import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/lesson.dart';
import '../pronunciation/phoneme_inventory.dart';
import '../state/app_state.dart';
import 'practice_screen.dart';

/// Mở màn hình luyện tập cho một bài học.
Future<void> openLessonPractice(BuildContext context, int lessonId, {int startIndex = 0}) async {
  final db = context.read<AppState>().database;
  final lesson = await db.lessons.getLesson(lessonId);
  final items = await db.lessons.getItems(lessonId);
  if (lesson == null || !context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => PracticeScreen(title: lesson.title, items: items, lessonId: lesson.id, startIndex: startIndex),
  ));
}

/// Tự luyện: người học nhập câu bất kỳ.
Future<void> openFreePractice(BuildContext context) async {
  final ctrl = TextEditingController();
  final text = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Tự luyện câu bất kỳ'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLines: 3,
        minLines: 1,
        decoration: const InputDecoration(hintText: 'Ví dụ: I love learning English', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Luyện')),
      ],
    ),
  );
  if (text == null || text.isEmpty || !context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => PracticeScreen(title: 'Tự luyện', items: [LessonItem(text: text, meaning: '')]),
  ));
}

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  Object? _version;
  Future<(List<Lesson>, Map<int, LessonProgress>)>? _future;

  Future<(List<Lesson>, Map<int, LessonProgress>)> _load(AppState s) async {
    final lessons = await s.database.lessons.getLessons();
    final progress = await s.database.lessons.getProgress(s.currentUser!.id!);
    return (lessons, progress);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final version = context.select<AppState, Object?>((s) => s.dashboard);
    if (_future == null || !identical(version, _version)) {
      _version = version;
      _future = _load(state);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Bài học')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final (lessons, progress) = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.edit_note, size: 32),
                  title: const Text('Tự luyện câu bất kỳ', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Nhập câu bạn muốn luyện, AI sẽ chấm điểm từng âm'),
                  onTap: () => openFreePractice(context),
                ),
              ),
              const SizedBox(height: 12),
              for (final l in lessons) ...[
                _LessonCard(lesson: l, progress: progress[l.id]),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, this.progress});

  final Lesson lesson;
  final LessonProgress? progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonDetailScreen(lesson: lesson))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Text(lesson.icon, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(lesson.description, style: TextStyle(color: theme.hintColor, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Tag(text: lesson.level),
                        for (final ph in lesson.focusPhonemes.take(3)) _Tag(text: '/${ipaOf(ph)}/'),
                      ],
                    ),
                    if (p != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: p.completion, minHeight: 6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${p.practicedItems}/${p.itemCount}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (p?.bestAverage != null) ...[
                const SizedBox(width: 8),
                Column(
                  children: [
                    Text(p!.bestAverage!.round().toString(),
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: scoreColor(context, p.bestAverage!))),
                    const Text('điểm', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  late Future<(List<LessonItem>, Map<int, double>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<LessonItem>, Map<int, double>)> _load() async {
    final s = context.read<AppState>();
    final items = await s.database.lessons.getItems(widget.lesson.id);
    final best = await s.database.lessons.getBestScores(s.currentUser!.id!, widget.lesson.id);
    return (items, best);
  }

  Future<void> _practice(int index) async {
    await openLessonPractice(context, widget.lesson.id, startIndex: index);
    if (mounted) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final l = widget.lesson;
    return Scaffold(
      appBar: AppBar(title: Text(l.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _practice(0),
        icon: const Icon(Icons.mic),
        label: const Text('Bắt đầu luyện'),
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final (items, best) = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Text(l.description),
              if (l.focusPhonemes.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final ph in l.focusPhonemes)
                  if (phonemeInfo(ph) != null)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('/${ipaOf(ph)}/', style: const TextStyle(fontSize: 13))),
                        title: Text('Âm /${ipaOf(ph)}/ – ví dụ "${phonemeInfo(ph)!.example}"'),
                        subtitle: Text(phonemeInfo(ph)!.tip),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () => state.tts.speak(phonemeInfo(ph)!.example, rate: state.currentUser!.speechRate),
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: 12),
              Text('Nội dung luyện tập', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (var i = 0; i < items.length; i++)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(items[i].text, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${state.scorer.ipaFor(items[i].text)}\n${items[i].meaning}'),
                    isThreeLine: true,
                    onTap: () => _practice(i),
                    trailing: best[items[i].id] == null
                        ? const Icon(Icons.mic_none)
                        : Text(best[items[i].id]!.round().toString(),
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 18, color: scoreColor(context, best[items[i].id]!))),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

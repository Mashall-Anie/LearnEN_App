import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/practice_models.dart';
import '../state/app_state.dart';
import '../utils/date_utils.dart';
import '../widgets/pronunciation_feedback_view.dart';

/// Lịch sử luyện tập: mọi lượt phát âm kèm kết quả phân tích đã lưu.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Object? _version;
  Future<List<AttemptRecord>>? _future;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final version = context.select<AppState, Object?>((s) => s.dashboard);
    if (_future == null || !identical(version, _version)) {
      _version = version;
      _future = state.database.practice.getRecentAttempts(state.currentUser!.id!, limit: 200);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử luyện tập')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final attempts = snap.data!;
          if (attempts.isEmpty) {
            return const Center(child: Text('Chưa có lượt luyện nào.\nHãy bắt đầu một bài học!', textAlign: TextAlign.center));
          }
          final rows = <Widget>[];
          String? lastDay;
          for (final a in attempts) {
            final day = dateKey(a.createdAt);
            if (day != lastDay) {
              lastDay = day;
              final d = a.createdAt;
              rows.add(Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                child: Text('${weekdayShort(d)}, ${d.day}/${d.month}/${d.year}',
                    style: Theme.of(context).textTheme.titleSmall),
              ));
            }
            rows.add(Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: scoreColor(context, a.overallScore).withValues(alpha: 0.15),
                  child: Text(a.overallScore.round().toString(),
                      style: TextStyle(color: scoreColor(context, a.overallScore), fontWeight: FontWeight.w800)),
                ),
                title: Text(a.targetText, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${a.inputMethod == 'text' ? '⌨️ ' : '🎤 '}“${a.recognizedText}”',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  '${a.createdAt.hour.toString().padLeft(2, '0')}:${a.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => AttemptDetailScreen(attempt: a))),
              ),
            ));
          }
          return ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 24), children: rows);
        },
      ),
    );
  }
}

class AttemptDetailScreen extends StatelessWidget {
  const AttemptDetailScreen({super.key, required this.attempt});

  final AttemptRecord attempt;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(formatDateTime(attempt.createdAt))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(attempt.targetText, style: Theme.of(context).textTheme.headlineSmall),
          Text(state.scorer.ipaFor(attempt.targetText), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 12),
          PronunciationFeedbackView(
            result: attempt.result,
            onSpeak: (t) => state.tts.speak(t, rate: state.currentUser!.speechRate),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../app.dart';
import '../pronunciation/phoneme_inventory.dart';
import '../pronunciation/pronunciation_result.dart';
import 'score_ring.dart';

/// Hiển thị kết quả phân tích phát âm: điểm, từ/âm sai, gợi ý và bài tập.
class PronunciationFeedbackView extends StatelessWidget {
  const PronunciationFeedbackView({
    super.key,
    required this.result,
    this.onSpeak,
    this.onPracticeExercise,
    this.onOpenLesson,
  });

  final PronunciationResult result;
  final void Function(String text)? onSpeak;
  final void Function(ExerciseSuggestion exercise)? onPracticeExercise;
  final void Function(int lessonId)? onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  children: [
                    ScoreRing(score: result.overall, size: 92, label: 'điểm'),
                    const SizedBox(height: 6),
                    Text(result.grade,
                        style: TextStyle(fontWeight: FontWeight.w700, color: scoreColor(context, result.overall))),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      SubScoreBar(label: 'Chính xác', value: result.accuracy, icon: Icons.graphic_eq),
                      SubScoreBar(label: 'Đầy đủ', value: result.completeness, icon: Icons.checklist),
                      SubScoreBar(label: 'Trôi chảy', value: result.fluency, icon: Icons.speed),
                      SubScoreBar(
                        label: 'AI tin cậy',
                        value: result.confidence == null ? null : result.confidence! * 100,
                        icon: Icons.psychology_alt,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phân tích từng từ', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('Chạm vào từ để xem chi tiết từng âm. Âm màu đỏ là âm phát âm sai.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final w in result.words) _WordChip(word: w, onSpeak: onSpeak)],
                ),
                const Divider(height: 24),
                _LabeledText(label: 'AI nghe được', text: result.recognizedText.isEmpty ? '(không có)' : result.recognizedText),
                if (result.alternatives.isNotEmpty)
                  _LabeledText(label: 'Khả năng khác', text: result.alternatives.take(3).join(' · ')),
              ],
            ),
          ),
        ),
        if (result.tips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Gợi ý cải thiện', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final t in result.tips) _TipCard(tip: t),
        ],
        if (result.exercises.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Bài tập đề xuất', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final e in result.exercises)
            _ExerciseCard(
              exercise: e,
              onSpeak: onSpeak,
              onPractice: onPracticeExercise,
              onOpenLesson: onOpenLesson,
            ),
        ],
      ],
    );
  }
}

class _LabeledText extends StatelessWidget {
  const _LabeledText({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(text: '$label: ', style: TextStyle(color: Theme.of(context).hintColor)),
            TextSpan(text: text, style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

Color _wordColor(BuildContext context, WordStatus s) {
  switch (s) {
    case WordStatus.correct:
      return const Color(0xFF16A34A);
    case WordStatus.partial:
      return const Color(0xFFF59E0B);
    case WordStatus.wrong:
      return Theme.of(context).colorScheme.error;
    case WordStatus.missing:
      return Theme.of(context).disabledColor;
  }
}

Color _phonemeColor(BuildContext context, PhonemeStatus s) {
  switch (s) {
    case PhonemeStatus.correct:
      return const Color(0xFF16A34A);
    case PhonemeStatus.near:
      return const Color(0xFFF59E0B);
    case PhonemeStatus.wrong:
    case PhonemeStatus.missing:
      return Theme.of(context).colorScheme.error;
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, this.onSpeak});

  final WordResult word;
  final void Function(String)? onSpeak;

  @override
  Widget build(BuildContext context) {
    final color = _wordColor(context, word.status);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word.word,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: color,
                decoration: word.status == WordStatus.missing ? TextDecoration.lineThrough : null,
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  const TextSpan(text: '/', style: TextStyle(color: Colors.grey)),
                  for (final p in word.phonemes)
                    TextSpan(
                      text: p.expectedIpa,
                      style: TextStyle(
                        color: _phonemeColor(context, p.status),
                        fontWeight: p.isError ? FontWeight.w800 : FontWeight.w400,
                        decoration: p.status == PhonemeStatus.missing ? TextDecoration.underline : null,
                      ),
                    ),
                  const TextSpan(text: '/', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(word.word, style: Theme.of(ctx).textTheme.headlineSmall),
                  const SizedBox(width: 8),
                  Text('/${word.expectedIpa}/', style: Theme.of(ctx).textTheme.titleMedium),
                  const Spacer(),
                  if (onSpeak != null)
                    IconButton.filledTonal(onPressed: () => onSpeak!(word.word), icon: const Icon(Icons.volume_up)),
                ],
              ),
              Text('AI nghe được: ${word.heardAs.isEmpty ? '(không có)' : word.heardAs}  ·  ${(word.score * 100).round()} điểm'),
              const SizedBox(height: 12),
              Table(
                columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1), 2: FlexColumnWidth(2)},
                children: [
                  const TableRow(children: [
                    Text('Âm chuẩn', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Bạn nói', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Đánh giá', style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  for (final p in word.phonemes)
                    TableRow(children: [
                      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('/${p.expectedIpa}/')),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(p.actualIpa == null ? '—' : '/${p.actualIpa}/'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          switch (p.status) {
                            PhonemeStatus.correct => '✓ Đúng',
                            PhonemeStatus.near => '≈ Gần đúng',
                            PhonemeStatus.wrong => '✗ Sai',
                            PhonemeStatus.missing => '✗ Bị bỏ sót',
                          },
                          style: TextStyle(color: _phonemeColor(ctx, p.status), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                  for (final x in word.extraPhonemes)
                    TableRow(children: [
                      const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('—')),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('/${ipaOf(x)}/')),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('+ Âm thừa', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                      ),
                    ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final FeedbackTip tip;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (tip.kind) {
      TipKind.praise => (Icons.emoji_events, const Color(0xFF16A34A)),
      TipKind.general => (Icons.info_outline, Theme.of(context).colorScheme.primary),
      TipKind.finalSound => (Icons.last_page, const Color(0xFFF59E0B)),
      _ => (Icons.record_voice_over, Theme.of(context).colorScheme.error),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (tip.words.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Trong: ${tip.words.join(', ')}',
                            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    const SizedBox(height: 4),
                    Text(tip.detail),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, this.onSpeak, this.onPractice, this.onOpenLesson});

  final ExerciseSuggestion exercise;
  final void Function(String)? onSpeak;
  final void Function(ExerciseSuggestion)? onPractice;
  final void Function(int)? onOpenLesson;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.fitness_center, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(exercise.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
              const SizedBox(height: 4),
              Text(exercise.description),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final w in exercise.practiceItems)
                    ActionChip(
                      avatar: const Icon(Icons.volume_up, size: 16),
                      label: Text(w),
                      onPressed: onSpeak == null ? null : () => onSpeak!(w),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  if (onPractice != null)
                    FilledButton.tonalIcon(
                      onPressed: () => onPractice!(exercise),
                      icon: const Icon(Icons.mic),
                      label: const Text('Luyện ngay'),
                    ),
                  if (onOpenLesson != null && exercise.lessonId != null)
                    TextButton(onPressed: () => onOpenLesson!(exercise.lessonId!), child: const Text('Mở bài học')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

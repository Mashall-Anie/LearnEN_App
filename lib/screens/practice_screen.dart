import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson.dart';
import '../models/practice_models.dart';
import '../pronunciation/pronunciation_result.dart';
import '../services/study_timer.dart';
import '../state/app_state.dart';
import '../utils/date_utils.dart';
import '../widgets/pronunciation_feedback_view.dart';
import 'lessons_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.title, required this.items, this.lessonId, this.startIndex = 0});

  final String title;
  final List<LessonItem> items;
  final int? lessonId;
  final int startIndex;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with WidgetsBindingObserver {
  late final AppState _app;
  final StudyTimer _timer = StudyTimer();
  final TextEditingController _typed = TextEditingController();
  late int _index;
  int? _sessionId;

  bool _listening = false;
  bool _evaluating = false;
  String _partial = '';
  double _level = 0;
  PronunciationResult? _result;
  final List<double> _scores = [];
  int _sessionSeconds = 0;

  LessonItem get _item => widget.items[_index];

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _index = widget.startIndex.clamp(0, widget.items.length - 1);
    WidgetsBinding.instance.addObserver(this);
    _timer.start();
    _startSession();
  }

  Future<void> _startSession() async {
    _sessionId = await _app.database.practice.startSession(
      userId: _app.currentUser!.id!,
      lessonId: widget.lessonId,
      at: _app.clock(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timer.resume();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _timer.pause();
      _flushTime();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _app.speech.cancel();
    _app.tts.stop();
    _typed.dispose();
    _finishSession();
    super.dispose();
  }

  Future<void> _finishSession() async {
    await _flushTime();
    if (_sessionId != null) await _app.database.practice.endSession(_sessionId!, _app.clock());
    await _app.onPracticeProgress();
  }

  /// Ghi thời gian học đã tích lũy vào CSDL.
  Future<void> _flushTime() async {
    final user = _app.currentUser;
    if (user == null) return;
    final secs = _timer.takeSeconds();
    if (secs <= 0) return;
    _sessionSeconds += secs;
    await _app.database.practice.addStudyTime(
      userId: user.id!,
      sessionId: _sessionId,
      seconds: secs,
      at: _app.clock(),
      goalMinutes: user.dailyGoalMinutes,
    );
  }

  void _speak(String text, {bool slow = false}) {
    _timer.markActivity();
    final rate = _app.currentUser!.speechRate;
    _app.tts.speak(text, rate: slow ? rate * 0.55 : rate);
  }

  Future<void> _toggleListen() async {
    _timer.markActivity();
    if (_listening) {
      await _app.speech.stop();
      return;
    }
    final ok = await _app.speech.init();
    if (!mounted) return;
    if (!ok) {
      _showMessage('Không dùng được nhận dạng giọng nói (${_app.speech.lastError ?? 'thiếu quyền micro hoặc dịch vụ Google'}). '
          'Bạn có thể bật "Chế độ kiểm thử" trong Cài đặt để nhập văn bản.');
      return;
    }
    await _app.tts.stop();
    setState(() {
      _listening = true;
      _partial = '';
      _result = null;
      _level = 0;
    });
    await _app.speech.start(
      onResult: (c) {
        if (mounted) setState(() => _partial = c.text);
      },
      onSoundLevel: (l) {
        if (mounted) setState(() => _level = l);
      },
      onDone: (last, error) {
        if (!mounted) return;
        setState(() => _listening = false);
        _timer.markActivity();
        if (last == null || last.text.trim().isEmpty) {
          _showMessage(error == null || error.contains('no_match') || error.contains('timeout')
              ? 'AI chưa nghe rõ. Hãy nói to, rõ ràng và thử lại.'
              : 'Lỗi nhận dạng: $error');
          return;
        }
        _evaluate(
          last.text,
          confidence: last.confidence,
          duration: last.speechDuration,
          alternatives: last.alternatives,
          inputMethod: 'voice',
        );
      },
    );
  }

  Future<void> _evaluate(
    String recognized, {
    double? confidence,
    Duration? duration,
    List<String> alternatives = const [],
    required String inputMethod,
  }) async {
    if (_evaluating) return;
    if (recognized.trim().isEmpty) {
      _showMessage('Hãy nhập câu mô phỏng trước khi chấm.');
      return;
    }
    setState(() => _evaluating = true);
    final user = _app.currentUser!;
    final before = _app.dashboard;
    final result = _app.scorer.evaluate(
      targetText: _item.text,
      recognizedText: recognized,
      confidence: confidence,
      speechDuration: duration,
      alternatives: alternatives,
    );
    setState(() {
      _result = result;
      _partial = recognized;
    });
    _scores.add(result.overall);

    await _app.database.practice.saveAttempt(
      attempt: AttemptRecord.fromResult(
        userId: user.id!,
        sessionId: _sessionId,
        lessonItemId: _item.id,
        result: result,
        speechDurationMs: duration?.inMilliseconds,
        inputMethod: inputMethod,
        createdAt: _app.clock(),
      ),
      result: result,
      goalMinutes: user.dailyGoalMinutes,
    );
    await _flushTime();
    await _app.onPracticeProgress();
    if (!mounted) return;
    setState(() => _evaluating = false);
    _celebrate(before, _app.dashboard);
  }

  void _celebrate(DashboardData? before, DashboardData? after) {
    if (after == null) return;
    if (before != null && !before.streak.practicedToday && after.streak.practicedToday) {
      _showMessage('🔥 Chuỗi ${after.streak.current} ngày! Tiếp tục phát huy nhé.');
    } else if (before != null && !before.today.goalMet && after.today.goalMet) {
      _showMessage('🎯 Bạn đã đạt mục tiêu ${after.today.goalMinutes} phút hôm nay!');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  void _goTo(int i) {
    _timer.markActivity();
    _app.speech.cancel();
    setState(() {
      _index = i;
      _result = null;
      _partial = '';
      _listening = false;
      _typed.clear();
    });
  }

  Future<void> _finish() async {
    await _flushTime();
    if (!mounted) return;
    final avg = _scores.isEmpty ? null : _scores.reduce((a, b) => a + b) / _scores.length;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoàn thành bài luyện 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số lượt nói: ${_scores.length}'),
            Text('Điểm trung bình: ${avg?.round() ?? '–'}'),
            Text('Thời gian học: ${formatDuration(_sessionSeconds)}'),
            if (avg != null) Text('Xếp loại: ${PronunciationResult.gradeOf(avg)}'),
          ],
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _practiceExercise(ExerciseSuggestion e) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PracticeScreen(
        title: e.title,
        items: [for (final w in e.practiceItems) LessonItem(text: w, meaning: '')],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AppState, bool>((s) => s.currentUser?.testMode ?? false);
    final theme = Theme.of(context);
    final total = widget.items.length;
    final isLast = _index == total - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_index + 1) / total),
        ),
        actions: [Center(child: Padding(padding: const EdgeInsets.only(right: 16), child: Text('${_index + 1}/$total')))],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _timer.markActivity,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _TargetCard(item: _item, onSpeak: _speak),
            const SizedBox(height: 20),
            Center(
              child: _MicButton(listening: _listening, level: _level, busy: _evaluating, onTap: _toggleListen),
            ),
            const SizedBox(height: 10),
            Text(
              _listening
                  ? 'Đang nghe… chạm lần nữa để dừng'
                  : _evaluating
                      ? 'AI đang phân tích…'
                      : 'Chạm micro rồi đọc to câu trên',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor),
            ),
            if (_partial.isNotEmpty && _result == null) ...[
              const SizedBox(height: 8),
              Text('“$_partial”', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            ],
            if (user) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🧪 Chế độ kiểm thử: nhập câu mô phỏng thay cho giọng nói',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _typed,
                              decoration: const InputDecoration(
                                  hintText: 'vd: I sink dis is de tird one', isDense: true, border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _evaluating
                                ? null
                                : () {
                                    _timer.markActivity();
                                    FocusScope.of(context).unfocus();
                                    _evaluate(_typed.text, inputMethod: 'text');
                                  },
                            child: const Text('Chấm'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              PronunciationFeedbackView(
                result: _result!,
                onSpeak: (t) => _speak(t),
                onPracticeExercise: _practiceExercise,
                onOpenLesson: widget.lessonId == null ? (id) => openLessonPractice(context, id) : null,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              IconButton.outlined(
                onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Câu trước',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _result == null || _listening ? null : _toggleListen,
                  icon: const Icon(Icons.replay),
                  label: const Text('Thử lại'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _listening ? null : (isLast ? _finish : () => _goTo(_index + 1)),
                  icon: Icon(isLast ? Icons.flag : Icons.chevron_right),
                  label: Text(isLast ? 'Hoàn thành' : 'Câu tiếp'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.item, required this.onSpeak});

  final LessonItem item;
  final void Function(String text, {bool slow}) onSpeak;

  @override
  Widget build(BuildContext context) {
    final scorer = context.read<AppState>().scorer;
    final theme = Theme.of(context);
    final words = scorer.wordIpa(item.text);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(item.text,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 4,
              children: [
                for (final (w, ipa) in words)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(w, style: const TextStyle(fontSize: 12)),
                      Text('/$ipa/', style: TextStyle(color: theme.colorScheme.primary, fontSize: 15)),
                    ],
                  ),
              ],
            ),
            if (item.meaning.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(item.meaning, style: TextStyle(color: theme.hintColor, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => onSpeak(item.text),
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Nghe mẫu'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onSpeak(item.text, slow: true),
                  icon: const Text('🐢'),
                  label: const Text('Chậm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.listening, required this.level, required this.busy, required this.onTap});

  final bool listening;
  final double level;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // speech_to_text trả mức âm lượng khoảng -2..10 dB.
    final pulse = listening ? (1 + (level.clamp(0, 10) / 10) * 0.35) : 1.0;
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 96 * pulse,
            height: 96 * pulse,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (listening ? scheme.error : scheme.primary).withValues(alpha: 0.18),
            ),
          ),
          Material(
            color: listening ? scheme.error : scheme.primary,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: busy ? null : onTap,
              child: SizedBox(
                width: 84,
                height: 84,
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(26),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : Icon(listening ? Icons.stop : Icons.mic, color: Colors.white, size: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

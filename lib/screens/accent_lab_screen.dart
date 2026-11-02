import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../pronunciation/accent_test_cases.dart';
import '../pronunciation/pronunciation_result.dart';
import '../state/app_state.dart';
import '../widgets/pronunciation_feedback_view.dart';

/// Phòng kiểm thử AI: chạy bộ ca mô phỏng nhiều kiểu giọng / người nói và
/// kiểm tra điểm số + lỗi phát hiện được có đúng kỳ vọng không.
class AccentLabScreen extends StatefulWidget {
  const AccentLabScreen({super.key});

  @override
  State<AccentLabScreen> createState() => _AccentLabScreenState();
}

class _LabRun {
  _LabRun(this.testCase, this.result);

  final AccentTestCase testCase;
  final PronunciationResult result;

  Set<String> get detected => result.errors.map((e) => e.expected).whereType<String>().toSet();

  bool get scoreOk => result.overall >= testCase.minScore && result.overall <= testCase.maxScore;
  bool get errorsOk => testCase.expectedErrorPhonemes.every(detected.contains);
  bool get passed => scoreOk && errorsOk;
}

class _AccentLabScreenState extends State<AccentLabScreen> {
  late List<_LabRun> _runs;
  final _target = TextEditingController(text: 'I think this is the third one.');
  final _heard = TextEditingController(text: 'I sink dis is de tird one');
  PronunciationResult? _custom;

  @override
  void initState() {
    super.initState();
    _runAll();
  }

  @override
  void dispose() {
    _target.dispose();
    _heard.dispose();
    super.dispose();
  }

  void _runAll() {
    final scorer = context.read<AppState>().scorer;
    _runs = [
      for (final c in kAccentTestCases)
        _LabRun(
          c,
          scorer.evaluate(
            targetText: c.target,
            recognizedText: c.transcript,
            confidence: c.confidence,
            speechDuration: c.duration,
          ),
        ),
    ];
  }

  void _show(PronunciationResult r, String title) {
    final state = context.read<AppState>();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(r.targetText, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            PronunciationFeedbackView(result: r, onSpeak: (t) => state.tts.speak(t)),
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final passed = _runs.where((r) => r.passed).length;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng kiểm thử AI'),
        actions: [IconButton(onPressed: () => setState(_runAll), icon: const Icon(Icons.play_arrow), tooltip: 'Chạy lại')],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            color: passed == _runs.length ? const Color(0xFFDCFCE7) : theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Đạt $passed/${_runs.length} ca kiểm thử mô phỏng giọng nói',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mỗi ca mô phỏng câu mà bộ nhận dạng giọng nói trả về khi một kiểu người nói đọc câu mẫu. '
            'Để kiểm thử với giọng thật, hãy cho nhiều người dùng luyện cùng một bài và so sánh trong Lịch sử.',
            style: TextStyle(color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          for (final r in _runs)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => _show(r.result, r.testCase.speaker),
                leading: Icon(r.passed ? Icons.check_circle : Icons.cancel,
                    color: r.passed ? const Color(0xFF16A34A) : theme.colorScheme.error),
                title: Text(r.testCase.speaker, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '“${r.testCase.transcript}”\n'
                  'Kỳ vọng ${r.testCase.minScore.round()}–${r.testCase.maxScore.round()}'
                  '${r.testCase.expectedErrorPhonemes.isEmpty ? '' : ' · lỗi ${r.testCase.expectedErrorPhonemes.join(', ')}'}',
                ),
                isThreeLine: true,
                trailing: Text(
                  r.result.overall.round().toString(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: scoreColor(context, r.result.overall)),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Tự tạo ca kiểm thử', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(controller: _target, decoration: const InputDecoration(labelText: 'Câu mẫu', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(
            controller: _heard,
            decoration: const InputDecoration(labelText: 'Câu AI nghe được (mô phỏng)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              final r = context.read<AppState>().scorer.evaluate(targetText: _target.text, recognizedText: _heard.text);
              setState(() => _custom = r);
              _show(r, 'Ca kiểm thử tự tạo');
            },
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Phân tích'),
          ),
          if (_custom != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Kết quả gần nhất: ${_custom!.overall.round()} điểm – ${_custom!.grade}'),
            ),
        ],
      ),
    );
  }
}

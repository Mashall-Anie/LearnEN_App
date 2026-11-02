// Kiểm thử độ chính xác của phân tích AI với nhiều kiểu người nói / giọng khác nhau.
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_en_app/pronunciation/accent_test_cases.dart';
import 'package:learn_en_app/pronunciation/pronunciation_scorer.dart';

void main() {
  final scorer = PronunciationScorer();

  for (final c in kAccentTestCases) {
    test('[${c.id}] ${c.speaker}: ${c.description}', () {
      final r = scorer.evaluate(
        targetText: c.target,
        recognizedText: c.transcript,
        confidence: c.confidence,
        speechDuration: c.duration,
      );
      expect(r.overall, inInclusiveRange(c.minScore, c.maxScore),
          reason: '"${c.transcript}" → ${r.overall} (acc ${r.accuracy}, comp ${r.completeness}, flu ${r.fluency})');
      final detected = r.errors.map((e) => e.expected).whereType<String>().toSet();
      for (final p in c.expectedErrorPhonemes) {
        expect(detected, contains(p), reason: 'Phải phát hiện lỗi âm $p, phát hiện được: $detected');
      }
      if (c.expectedErrorPhonemes.isEmpty && c.minScore >= 90) {
        expect(r.errors, isEmpty, reason: 'Giọng chuẩn không được báo lỗi giả');
      }
    });
  }

  test('Giọng chuẩn luôn cao điểm hơn giọng có lỗi trên cùng câu', () {
    final byTarget = <String, List<(AccentTestCase, double)>>{};
    for (final c in kAccentTestCases) {
      final r = scorer.evaluate(
          targetText: c.target, recognizedText: c.transcript, confidence: c.confidence, speechDuration: c.duration);
      byTarget.putIfAbsent(c.target, () => []).add((c, r.overall));
    }
    for (final entries in byTarget.values) {
      final clean = entries.where((e) => e.$1.expectedErrorPhonemes.isEmpty && e.$1.minScore >= 90);
      final faulty = entries.where((e) => e.$1.expectedErrorPhonemes.isNotEmpty);
      for (final a in clean) {
        for (final b in faulty) {
          expect(a.$2, greaterThan(b.$2), reason: '${a.$1.id} vs ${b.$1.id}');
        }
      }
    }
  });
}

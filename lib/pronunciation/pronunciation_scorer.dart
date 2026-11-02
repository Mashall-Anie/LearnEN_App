/// Chấm điểm phát âm bằng so sánh âm vị (phoneme comparison).
///
/// Quy trình:
/// 1. Chuẩn hóa câu mẫu và câu AI nhận dạng được → danh sách từ.
/// 2. Chuyển mỗi từ thành dãy âm vị (từ điển + quy tắc chính tả).
/// 3. Căn chỉnh hai dãy âm vị bằng Needleman–Wunsch có trọng số ngữ âm.
/// 4. Tính điểm từng âm / từng từ, rồi tổng hợp:
///    - Accuracy  : độ chính xác âm vị + tỉ lệ từ đúng hoàn toàn.
///    - Completeness: tỉ lệ từ được nói ra.
///    - Fluency   : tốc độ nói (từ/giây) so với khoảng tự nhiên của người học.
///    - Confidence: độ tin cậy của mô hình nhận dạng giọng nói (nếu có).
library;

import 'feedback_generator.dart';
import 'phoneme_aligner.dart';
import 'phoneme_inventory.dart';
import 'pronouncing_dictionary.dart';
import 'pronunciation_result.dart';

class PronunciationScorer {
  PronunciationScorer({
    PronouncingDictionary? dictionary,
    this.aligner = const PhonemeAligner(),
    this.feedback = const FeedbackGenerator(),
  }) : dictionary = dictionary ?? PronouncingDictionary.instance;

  final PronouncingDictionary dictionary;
  final PhonemeAligner aligner;
  final FeedbackGenerator feedback;

  /// Âm thay thế có chi phí nhỏ hơn ngưỡng này được coi là "gần đúng".
  static const nearThreshold = 0.35;

  PronunciationResult evaluate({
    required String targetText,
    required String recognizedText,
    double? confidence,
    Duration? speechDuration,
    List<String> alternatives = const [],
  }) {
    final targetWords = tokenize(targetText);
    final heardWords = tokenize(recognizedText);
    final targetPhones = targetWords.map((w) => dictionary.phonemesFor(w.key)).toList();
    final heardPhones = heardWords.map((w) => dictionary.phonemesFor(w.key)).toList();

    final alignment = aligner.align(PhonemeAligner.flatten(targetPhones), PhonemeAligner.flatten(heardPhones));

    // Gom kết quả theo từng từ của câu mẫu.
    final perWord = List.generate(targetWords.length, (_) => <PhonemeResult>[]);
    final heardIdx = List.generate(targetWords.length, (_) => <int>{});
    final extras = List.generate(targetWords.length, (_) => <String>[]);
    var lastWord = 0;
    var insertions = 0;
    for (final a in alignment) {
      if (a.expected == null) {
        insertions++;
        if (targetWords.isNotEmpty) {
          extras[lastWord].add(a.actual!.symbol);
          heardIdx[lastWord].add(a.actual!.wordIndex);
        }
        continue;
      }
      final w = a.expected!.wordIndex;
      lastWord = w;
      if (a.actual != null) heardIdx[w].add(a.actual!.wordIndex);
      perWord[w].add(_phonemeResult(a));
    }

    final words = <WordResult>[];
    var creditSum = 0.0;
    var phoneCount = 0;
    for (var i = 0; i < targetWords.length; i++) {
      final phones = perWord[i];
      final credit = phones.fold<double>(0, (s, p) => s + p.credit);
      creditSum += credit;
      phoneCount += phones.length;
      final allMissing = phones.isNotEmpty && phones.every((p) => p.status == PhonemeStatus.missing);
      final anyError = phones.any((p) => p.isError) || extras[i].isNotEmpty;
      final score = phones.isEmpty ? 0.0 : ((credit / phones.length) - 0.15 * extras[i].length).clamp(0.0, 1.0);
      final status = allMissing
          ? WordStatus.missing
          : !anyError
              ? WordStatus.correct
              : score >= 0.6
                  ? WordStatus.partial
                  : WordStatus.wrong;
      final heard = (heardIdx[i].toList()..sort()).map((k) => heardWords[k].display).join(' ');
      words.add(WordResult(
        word: targetWords[i].display,
        heardAs: heard,
        score: score,
        status: status,
        phonemes: phones,
        extraPhonemes: extras[i],
      ));
    }

    final totalWords = targetWords.length;
    double accuracy = 0;
    double completeness = 0;
    double? fluency;
    if (totalWords > 0 && phoneCount > 0 && heardWords.isNotEmpty) {
      final phonemeAcc = ((creditSum - 0.5 * insertions) / phoneCount).clamp(0.0, 1.0);
      final wordAcc = words.where((w) => w.status == WordStatus.correct).length / totalWords;
      accuracy = 100 * (0.75 * phonemeAcc + 0.25 * wordAcc);
      completeness = 100 * words.where((w) => w.status != WordStatus.missing).length / totalWords;
      if (speechDuration != null && totalWords >= 3 && speechDuration.inMilliseconds > 0) {
        final wps = heardWords.length / (speechDuration.inMilliseconds / 1000);
        fluency = speakingRateScore(wps) * completeness / 100;
      }
    }

    var overall = fluency == null
        ? 0.8 * accuracy + 0.2 * completeness
        : 0.7 * accuracy + 0.15 * completeness + 0.15 * fluency;
    final conf = (confidence != null && confidence > 0) ? confidence.clamp(0.0, 1.0) : null;
    if (conf != null) overall *= 0.85 + 0.15 * conf;
    overall = overall.clamp(0.0, 100.0);

    final List<FeedbackTip> tips;
    final List<ExerciseSuggestion> exercises;
    if (heardWords.isEmpty) {
      tips = const [
        FeedbackTip(
          kind: TipKind.general,
          title: 'Không nghe thấy giọng nói',
          detail: 'Hãy kiểm tra quyền micro, nói to và rõ hơn, đặt điện thoại gần miệng rồi thử lại.',
        ),
      ];
      exercises = const [];
    } else {
      final generated = feedback.generate(
        words: words,
        overall: overall,
        completeness: completeness,
        fluency: fluency,
        confidence: conf,
      );
      tips = generated.$1;
      exercises = generated.$2;
    }

    return PronunciationResult(
      targetText: targetText,
      recognizedText: recognizedText,
      overall: _round(overall),
      accuracy: _round(accuracy),
      completeness: _round(completeness),
      fluency: fluency == null ? null : _round(fluency),
      confidence: conf,
      words: words,
      tips: tips,
      exercises: exercises,
      alternatives: alternatives.where((a) => a.trim().isNotEmpty && a != recognizedText).toList(),
    );
  }

  PhonemeResult _phonemeResult(AlignedPhone a) {
    switch (a.op) {
      case AlignOp.match:
        return PhonemeResult(expected: a.expected!.symbol, actual: a.actual!.symbol, status: PhonemeStatus.correct, credit: 1);
      case AlignOp.substitution:
        return PhonemeResult(
          expected: a.expected!.symbol,
          actual: a.actual!.symbol,
          status: a.cost <= nearThreshold ? PhonemeStatus.near : PhonemeStatus.wrong,
          credit: (1 - a.cost) * 0.5,
        );
      case AlignOp.deletion:
      case AlignOp.insertion:
        return PhonemeResult(expected: a.expected!.symbol, status: PhonemeStatus.missing, credit: 0);
    }
  }

  /// Điểm tốc độ nói: 1,2–3,5 từ/giây là tự nhiên với người học.
  static double speakingRateScore(double wordsPerSecond) {
    if (wordsPerSecond < 0.5) return 30;
    if (wordsPerSecond < 1.2) return 30 + (wordsPerSecond - 0.5) / 0.7 * 70;
    if (wordsPerSecond <= 3.5) return 100;
    if (wordsPerSecond <= 5) return 100 - (wordsPerSecond - 3.5) / 1.5 * 30;
    return 70;
  }

  static double _round(double v) => (v * 10).roundToDouble() / 10;

  /// Phiên âm IPA của câu mẫu để hiển thị.
  String ipaFor(String text) => dictionary.ipaFor(text);

  /// Dãy âm vị theo từ (dùng cho màn hình bài học).
  List<(String, String)> wordIpa(String text) =>
      tokenize(text).map((t) => (t.display, ipaOfSequence(dictionary.phonemesFor(t.key)))).toList();
}

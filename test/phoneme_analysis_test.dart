import 'package:flutter_test/flutter_test.dart';
import 'package:learn_en_app/pronunciation/phoneme_aligner.dart';
import 'package:learn_en_app/pronunciation/phoneme_inventory.dart';
import 'package:learn_en_app/pronunciation/pronouncing_dictionary.dart';
import 'package:learn_en_app/pronunciation/pronunciation_result.dart';
import 'package:learn_en_app/pronunciation/pronunciation_scorer.dart';

void main() {
  final dict = PronouncingDictionary.instance;

  group('Chuẩn hóa văn bản', () {
    test('bỏ dấu câu, giữ dấu nháy, đổi số thành chữ', () {
      final t = tokenize("I'm 3 years old, aren’t I?").map((w) => w.key).toList();
      expect(t, ["i'm", 'three', 'years', 'old', "aren't", 'i']);
    });

    test('numberToWords', () {
      expect(numberToWords(0), 'zero');
      expect(numberToWords(21), 'twenty one');
      expect(numberToWords(305), 'three hundred five');
      expect(numberToWords(2026), 'two thousand twenty six');
    });
  });

  group('Từ điển phiên âm', () {
    test('tra từ điển trực tiếp', () {
      expect(dict.phonemesFor('think'), ['TH', 'IH', 'NG', 'K']);
      expect(dict.sourceOf('think'), PhonemeSource.dictionary);
    });

    test('suy luận hình thái -s / -ed / -ing', () {
      expect(dict.phonemesFor('desks'), ['D', 'EH', 'S', 'K', 'S']);
      expect(dict.phonemesFor('dishes'), ['D', 'IH', 'SH', 'IH', 'Z']);
      expect(dict.phonemesFor('played'), ['P', 'L', 'EY', 'D']);
      expect(dict.phonemesFor('asked'), ['AE', 'S', 'K', 'T']);
      expect(dict.phonemesFor('visited'), ['V', 'IH', 'Z', 'IH', 'T', 'IH', 'D']);
      expect(dict.phonemesFor('making'), ['M', 'EY', 'K', 'IH', 'NG']);
      expect(dict.sourceOf('likes'), PhonemeSource.morphology);
    });

    test('quy tắc chính tả cho từ lạ', () {
      expect(LetterToSound.convert('tink'), ['T', 'IH', 'NG', 'K']);
      expect(LetterToSound.convert('dis'), ['D', 'IH', 'S']);
      expect(LetterToSound.convert('bike'), ['B', 'AY', 'K']);
      expect(LetterToSound.convert('shop'), ['SH', 'AA', 'P']);
      expect(dict.sourceOf('blorf'), PhonemeSource.rules);
    });

    test('mọi từ trong từ điển chỉ dùng âm vị hợp lệ', () {
      for (final word in ['the', 'usually', 'pronunciation', 'nearest', 'weather']) {
        for (final p in dict.phonemesFor(word)) {
          expect(kPhonemes.containsKey(p), isTrue, reason: '$word → $p');
        }
      }
    });

    test('phiên âm IPA', () {
      expect(dict.ipaFor('Thank you'), '/θæŋk juː/');
    });
  });

  group('Khoảng cách ngữ âm', () {
    test('âm gần nhau rẻ hơn âm xa nhau', () {
      expect(substitutionCost('TH', 'TH'), 0);
      expect(substitutionCost('AH', 'AX'), 0);
      expect(substitutionCost('TH', 'S'), lessThan(substitutionCost('TH', 'K')));
      expect(substitutionCost('IY', 'IH'), lessThan(substitutionCost('IY', 'AA')));
      expect(substitutionCost('P', 'B'), lessThan(substitutionCost('P', 'M')));
      expect(substitutionCost('T', 'IY'), 1);
    });
  });

  group('Căn chỉnh âm vị', () {
    const aligner = PhonemeAligner();
    List<PhoneToken> toks(String s) => PhonemeAligner.flatten([s.split(' ')]);

    test('thay thế một âm', () {
      final r = aligner.align(toks('TH IH NG K'), toks('S IH NG K'));
      expect(r.map((a) => a.op), [AlignOp.substitution, AlignOp.match, AlignOp.match, AlignOp.match]);
    });

    test('mất âm cuối', () {
      final r = aligner.align(toks('D EH S K S'), toks('D EH S K'));
      expect(r.last.op, AlignOp.deletion);
      expect(r.last.expected!.symbol, 'S');
      expect(r.last.expected!.isWordFinal, isTrue);
    });

    test('thêm âm thừa', () {
      final r = aligner.align(toks('S T R IY T'), toks('S AX T R IY T'));
      expect(r.where((a) => a.op == AlignOp.insertion).length, 1);
    });
  });

  group('Chấm điểm', () {
    final scorer = PronunciationScorer();

    test('đọc đúng hoàn toàn được điểm cao', () {
      final r = scorer.evaluate(targetText: 'Nice to meet you.', recognizedText: 'nice to meet you', confidence: 0.95);
      expect(r.overall, greaterThanOrEqualTo(95));
      expect(r.words.every((w) => w.status == WordStatus.correct), isTrue);
      expect(r.tips.first.kind, TipKind.praise);
    });

    test('đánh dấu đúng âm bị sai và đưa ra gợi ý', () {
      final r = scorer.evaluate(targetText: 'think', recognizedText: 'sink');
      final w = r.words.single;
      expect(w.status, WordStatus.partial);
      expect(w.heardAs, 'sink');
      final wrong = w.phonemes.where((p) => p.isError).single;
      expect(wrong.expected, 'TH');
      expect(wrong.actual, 'S');
      expect(r.tips.first.kind, TipKind.substitution);
      expect(r.tips.first.title, contains('θ'));
      expect(r.exercises.first.phoneme, 'TH');
      expect(r.exercises.first.lessonId, 1);
      expect(r.exercises.first.practiceItems, contains('sink'));
    });

    test('phát hiện nuốt âm cuối', () {
      final r = scorer.evaluate(targetText: 'cats', recognizedText: 'cat');
      expect(r.tips.first.kind, TipKind.finalSound);
      expect(r.errors.single.type, 'deletion');
      expect(r.errors.single.expected, 'S');
    });

    test('nói nửa câu: các từ cuối bị đánh dấu thiếu', () {
      final r = scorer.evaluate(targetText: 'Where is the nearest bus station?', recognizedText: 'where is the');
      expect(r.completeness, 50);
      expect(r.words.take(3).every((w) => w.status == WordStatus.correct), isTrue);
      expect(r.words.skip(3).every((w) => w.status == WordStatus.missing), isTrue);
      expect(r.tips.any((t) => t.title.contains('Thiếu 3 từ')), isTrue);
    });

    test('không nói gì → 0 điểm', () {
      final r = scorer.evaluate(targetText: 'hello', recognizedText: '');
      expect(r.overall, 0);
      expect(r.words.single.status, WordStatus.missing);
    });

    test('JSON khứ hồi giữ nguyên kết quả', () {
      final r = scorer.evaluate(
          targetText: 'I think this is the third one.', recognizedText: 'I sink dis is de tird one', confidence: 0.6);
      final back = PronunciationResult.fromJson(r.toJson());
      expect(back.overall, r.overall);
      expect(back.words.length, r.words.length);
      expect(back.words[1].phonemes.first.actual, 'S');
      expect(back.tips.length, r.tips.length);
      expect(back.errors.length, r.errors.length);
    });

    test('điểm tốc độ nói', () {
      expect(PronunciationScorer.speakingRateScore(2.0), 100);
      expect(PronunciationScorer.speakingRateScore(0.3), 30);
      expect(PronunciationScorer.speakingRateScore(0.85), closeTo(65, 0.1));
    });
  });
}

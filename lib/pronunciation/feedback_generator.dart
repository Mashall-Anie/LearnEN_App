/// Module phản hồi: từ kết quả so khớp âm vị sinh ra lời khuyên và bài tập
/// cải thiện, ưu tiên các lỗi điển hình của người Việt học tiếng Anh.
library;

import '../data/lesson_catalog.dart';
import 'phoneme_inventory.dart';
import 'pronunciation_result.dart';

/// Lời khuyên cho các cặp nhầm lẫn cụ thể "âm đúng>âm đã nói".
const Map<String, String> kConfusionTips = {
  'TH>T': 'Bạn đang chặn hơi như âm /t/. Với /θ/, đặt lưỡi GIỮA hai hàm răng và để hơi thoát ra liên tục, không bật.',
  'TH>S': 'Lưỡi đang nằm sau răng như /s/. Hãy thè nhẹ đầu lưỡi ra giữa hai răng rồi thổi hơi.',
  'TH>F': 'Bạn đang dùng môi – răng như /f/. Với /θ/ chỉ dùng lưỡi và răng, môi thả lỏng.',
  'DH>D': 'Bạn đang đọc như "đ" tiếng Việt. Đặt lưỡi giữa hai răng, rung dây thanh và để hơi thoát ra liên tục.',
  'DH>Z': 'Lưỡi đang ở sau răng như /z/. Đưa đầu lưỡi ra giữa hai răng.',
  'SH>S': 'Âm /ʃ/ cần tròn môi và lưỡi lùi về sau; /s/ thì môi dẹt. Thử nói "suỵt" rồi chuyển sang "she".',
  'S>SH': 'Bạn đang tròn môi quá – /s/ cần môi dẹt, đầu lưỡi gần lợi trên.',
  'R>L': 'Lưỡi đang chạm lợi như /l/. Với /r/, cong lưỡi lên nhưng không chạm vào đâu cả.',
  'L>R': 'Hãy để đầu lưỡi chạm hẳn vào lợi trên khi phát âm /l/.',
  'R>Z': 'Đừng đọc "r" như "d/gi" giọng miền Bắc. Cong lưỡi về sau, môi hơi tròn.',
  'V>B': 'Âm /v/ cần răng trên chạm môi dưới, không mím hai môi như /b/.',
  'V>W': 'Đừng tròn môi như /w/ – để răng trên chạm môi dưới.',
  'W>V': 'Âm /w/ không dùng răng: tròn môi như "u" rồi mở ra.',
  'IH>IY': 'Bạn kéo dài âm quá. /ɪ/ là âm ngắn và lỏng (sit, ship) – nói nhanh, gọn.',
  'IY>IH': 'Âm /iː/ cần kéo dài và căng môi như đang cười (seat, sheep).',
  'AE>EH': 'Mở miệng rộng hơn, hạ hàm dưới: /æ/ nằm giữa "a" và "e".',
  'EH>AE': 'Miệng đang mở quá rộng – /e/ chỉ mở vừa phải.',
  'Z>S': 'Âm /z/ cần rung dây thanh – đặt tay lên cổ họng sẽ thấy rung.',
  'CH>SH': '/tʃ/ bắt đầu bằng việc chặn hơi như /t/ rồi mới xả ra: "t-sh".',
  'SH>CH': 'Đừng chặn hơi – /ʃ/ là âm xát, hơi ra liên tục.',
  'JH>Z': '/dʒ/ phải chặn hơi rồi xả như "d-ʒ", không đọc như "gi" tiếng Việt.',
  'JH>Y': 'Đầu lưỡi phải chạm lợi rồi bật ra, không lướt nhẹ như /j/.',
  'N>NG': 'Âm cuối /n/: đầu lưỡi chạm lợi trên, đừng chuyển thành "ng".',
  'NG>N': 'Âm /ŋ/ dùng cuống lưỡi chạm ngạc mềm, không dùng đầu lưỡi như /n/.',
  'UH>UW': '/ʊ/ là âm ngắn, đừng chu môi và kéo dài quá.',
  'UW>UH': 'Kéo dài hơn và chu môi tròn hơn cho /uː/.',
  'P>B': '/p/ là âm vô thanh: bật hơi mạnh, không rung dây thanh.',
  'T>D': '/t/ là âm vô thanh: bật hơi mạnh, không rung dây thanh.',
  'K>G': '/k/ là âm vô thanh: bật hơi mạnh, không rung dây thanh.',
  'B>P': '/b/ là âm hữu thanh: rung dây thanh và bật nhẹ.',
  'D>T': '/d/ là âm hữu thanh: rung dây thanh và bật nhẹ.',
  'G>K': '/ɡ/ là âm hữu thanh: rung dây thanh và bật nhẹ.',
};

class _ErrorGroup {
  _ErrorGroup(this.kind, this.expected, this.actual);

  final TipKind kind;
  final String expected;
  final String? actual;
  final Set<String> words = {};
  int count = 0;
}

class FeedbackGenerator {
  const FeedbackGenerator();

  (List<FeedbackTip>, List<ExerciseSuggestion>) generate({
    required List<WordResult> words,
    required double overall,
    required double completeness,
    double? fluency,
    double? confidence,
  }) {
    final groups = <String, _ErrorGroup>{};
    void record(String key, TipKind kind, String expected, String? actual, String word) {
      final g = groups.putIfAbsent(key, () => _ErrorGroup(kind, expected, actual));
      g.words.add(word);
      g.count++;
    }

    for (final w in words) {
      if (w.status == WordStatus.missing) continue; // bỏ cả từ: xử lý ở phần "độ đầy đủ"
      for (var i = 0; i < w.phonemes.length; i++) {
        final p = w.phonemes[i];
        if (!p.isError) continue;
        final info = phonemeInfo(p.expected);
        if (p.status == PhonemeStatus.missing) {
          final isFinal = (info?.isConsonant ?? false) && _isInFinalCluster(w.phonemes, i);
          if (isFinal) {
            record('final:${p.expected}', TipKind.finalSound, p.expected, null, w.word);
          } else {
            record('miss:${p.expected}', TipKind.missingSound, p.expected, null, w.word);
          }
        } else {
          record('sub:${p.expected}>${p.actual}', TipKind.substitution, p.expected, p.actual, w.word);
        }
      }
      for (final x in w.extraPhonemes) {
        record('extra:$x', TipKind.extraSound, x, null, w.word);
      }
    }

    final sorted = groups.values.toList()..sort((a, b) => b.count.compareTo(a.count));
    final tips = <FeedbackTip>[];
    for (final g in sorted.take(4)) {
      tips.add(_tipFor(g));
    }

    final missingWords = words.where((w) => w.status == WordStatus.missing).map((w) => w.word).toList();
    if (missingWords.isNotEmpty && completeness < 100) {
      tips.add(FeedbackTip(
        kind: TipKind.general,
        title: 'Thiếu ${missingWords.length} từ',
        detail: completeness < 60
            ? 'AI chỉ nghe được một phần câu. Hãy nói trọn câu, to và rõ, giữ điện thoại cách miệng 15–20 cm.'
            : 'Một số từ chưa được nhận ra. Hãy nói rõ cả những từ ngắn như a, the, to.',
        words: missingWords,
      ));
    }
    if (confidence != null && confidence > 0 && confidence < 0.6) {
      tips.add(const FeedbackTip(
        kind: TipKind.general,
        title: 'AI chưa chắc chắn về câu bạn nói',
        detail: 'Thử nói chậm hơn, nhấn rõ từng từ và luyện ở nơi yên tĩnh.',
      ));
    }
    if (fluency != null && fluency < 60 && completeness >= 60) {
      tips.add(const FeedbackTip(
        kind: TipKind.general,
        title: 'Tốc độ nói chưa tự nhiên',
        detail: 'Nghe câu mẫu rồi nói liền mạch, không ngắt quãng giữa các từ. Không cần nói quá nhanh.',
      ));
    }
    if (tips.isEmpty && overall >= 85) {
      tips.add(const FeedbackTip(
        kind: TipKind.praise,
        title: 'Tuyệt vời!',
        detail: 'Bạn phát âm rõ ràng, đúng các âm trong câu. Hãy thử câu dài hơn hoặc bài nâng cao.',
      ));
    }

    return (tips, _exercisesFor(sorted));
  }

  /// Âm bị thiếu nằm ở cụm phụ âm cuối từ (sau nguyên âm cuối cùng).
  static bool _isInFinalCluster(List<PhonemeResult> phonemes, int index) {
    for (var k = index + 1; k < phonemes.length; k++) {
      if (phonemeInfo(phonemes[k].expected)?.isVowel ?? false) return false;
    }
    return true;
  }

  FeedbackTip _tipFor(_ErrorGroup g) {
    final info = phonemeInfo(g.expected);
    final ipa = ipaOf(g.expected);
    final general = info?.tip ?? '';
    switch (g.kind) {
      case TipKind.substitution:
        final actualIpa = ipaOf(g.actual!);
        final specific = kConfusionTips['${g.expected}>${g.actual}'];
        return FeedbackTip(
          kind: g.kind,
          phoneme: g.expected,
          title: 'Âm /$ipa/ bị đọc thành /$actualIpa/',
          detail: specific == null ? general : '$specific\n$general',
          words: g.words.toList(),
        );
      case TipKind.finalSound:
        return FeedbackTip(
          kind: g.kind,
          phoneme: g.expected,
          title: 'Thiếu âm cuối /$ipa/',
          detail: 'Người Việt hay "nuốt" âm cuối. Kết thúc từ bằng âm /$ipa/ thật rõ rồi mới nói từ tiếp theo. $general',
          words: g.words.toList(),
        );
      case TipKind.missingSound:
        return FeedbackTip(
          kind: g.kind,
          phoneme: g.expected,
          title: 'Thiếu âm /$ipa/',
          detail: (info?.isConsonant ?? false)
              ? 'Nếu đây là cụm phụ âm, hãy đọc liền các phụ âm, không bỏ âm nào. $general'
              : general,
          words: g.words.toList(),
        );
      case TipKind.extraSound:
        return FeedbackTip(
          kind: g.kind,
          phoneme: g.expected,
          title: 'Thừa âm /$ipa/',
          detail: 'Có vẻ bạn thêm âm thừa (thường là "ơ" ở cuối từ hoặc giữa cụm phụ âm). Hãy kết thúc từ gọn gàng.',
          words: g.words.toList(),
        );
      case TipKind.praise:
      case TipKind.general:
        return FeedbackTip(kind: g.kind, title: '/$ipa/', detail: general);
    }
  }

  List<ExerciseSuggestion> _exercisesFor(List<_ErrorGroup> groups) {
    final out = <ExerciseSuggestion>[];
    final seen = <String>{};
    for (final g in groups) {
      if (out.length >= 3) break;
      if (g.kind == TipKind.extraSound) continue;
      final finalSound = g.kind == TipKind.finalSound;
      final key = finalSound ? 'final' : g.expected;
      if (!seen.add(key)) continue;
      final info = phonemeInfo(g.expected);
      if (info == null) continue;
      final lessonId = lessonIdForPhoneme(g.expected, finalSound: finalSound);
      final ipa = info.ipa;
      List<String> items;
      if (finalSound) {
        items = lessonSeedById(LessonIds.finalSounds)!.items.take(5).map((e) => e.first).toList();
      } else if (info.minimalPairs.isNotEmpty) {
        items = [for (final pair in info.minimalPairs) ...pair];
      } else {
        items = [info.example, ...g.words];
      }
      out.add(ExerciseSuggestion(
        title: finalSound ? 'Luyện âm cuối /$ipa/' : 'Luyện âm /$ipa/',
        description: finalSound
            ? 'Đọc chậm từng từ, phát âm rõ âm cuối rồi tăng dần tốc độ.'
            : info.minimalPairs.isNotEmpty
                ? 'Đọc lần lượt từng cặp từ tối thiểu để phân biệt /$ipa/ với âm dễ nhầm.'
                : 'Đọc các từ chứa âm /$ipa/: ${info.example}.',
        practiceItems: items.toSet().toList(),
        phoneme: g.expected,
        lessonId: lessonId,
      ));
    }
    return out;
  }
}

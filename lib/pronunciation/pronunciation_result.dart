/// Mô hình kết quả phân tích phát âm (lưu dưới dạng JSON trong CSDL).
library;

import 'phoneme_inventory.dart';

enum PhonemeStatus { correct, near, wrong, missing }

enum WordStatus { correct, partial, wrong, missing }

enum TipKind { praise, substitution, finalSound, missingSound, extraSound, general }

class PhonemeResult {
  const PhonemeResult({required this.expected, this.actual, required this.status, required this.credit});

  factory PhonemeResult.fromJson(Map<String, dynamic> j) => PhonemeResult(
        expected: j['e'] as String,
        actual: j['a'] as String?,
        status: PhonemeStatus.values.byName(j['s'] as String),
        credit: (j['c'] as num).toDouble(),
      );

  final String expected;
  final String? actual;
  final PhonemeStatus status;

  /// Điểm cho âm này (0..1).
  final double credit;

  String get expectedIpa => ipaOf(expected);
  String? get actualIpa => actual == null ? null : ipaOf(actual!);
  bool get isError => status != PhonemeStatus.correct;

  Map<String, dynamic> toJson() => {'e': expected, 'a': actual, 's': status.name, 'c': credit};
}

class WordResult {
  const WordResult({
    required this.word,
    required this.heardAs,
    required this.score,
    required this.status,
    required this.phonemes,
    this.extraPhonemes = const [],
  });

  factory WordResult.fromJson(Map<String, dynamic> j) => WordResult(
        word: j['w'] as String,
        heardAs: j['h'] as String,
        score: (j['sc'] as num).toDouble(),
        status: WordStatus.values.byName(j['st'] as String),
        phonemes: (j['p'] as List).map((e) => PhonemeResult.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        extraPhonemes: (j['x'] as List? ?? const []).cast<String>(),
      );

  /// Từ trong câu mẫu.
  final String word;

  /// Những gì AI nghe được ở vị trí của từ này.
  final String heardAs;

  /// Điểm của từ (0..1).
  final double score;
  final WordStatus status;
  final List<PhonemeResult> phonemes;

  /// Các âm thừa người dùng thêm vào trong/sau từ này.
  final List<String> extraPhonemes;

  String get expectedIpa => ipaOfSequence(phonemes.map((p) => p.expected));

  Map<String, dynamic> toJson() => {
        'w': word,
        'h': heardAs,
        'sc': score,
        'st': status.name,
        'p': phonemes.map((p) => p.toJson()).toList(),
        'x': extraPhonemes,
      };
}

class FeedbackTip {
  const FeedbackTip({required this.kind, required this.title, required this.detail, this.phoneme, this.words = const []});

  factory FeedbackTip.fromJson(Map<String, dynamic> j) => FeedbackTip(
        kind: TipKind.values.byName(j['k'] as String),
        title: j['t'] as String,
        detail: j['d'] as String,
        phoneme: j['p'] as String?,
        words: (j['w'] as List? ?? const []).cast<String>(),
      );

  final TipKind kind;
  final String title;
  final String detail;
  final String? phoneme;
  final List<String> words;

  Map<String, dynamic> toJson() => {'k': kind.name, 't': title, 'd': detail, 'p': phoneme, 'w': words};
}

class ExerciseSuggestion {
  const ExerciseSuggestion({required this.title, required this.description, required this.practiceItems, this.phoneme, this.lessonId});

  factory ExerciseSuggestion.fromJson(Map<String, dynamic> j) => ExerciseSuggestion(
        title: j['t'] as String,
        description: j['d'] as String,
        practiceItems: (j['i'] as List).cast<String>(),
        phoneme: j['p'] as String?,
        lessonId: j['l'] as int?,
      );

  final String title;
  final String description;

  /// Các từ / cặp từ để luyện ngay.
  final List<String> practiceItems;
  final String? phoneme;

  /// Bài học liên quan trong giáo trình.
  final int? lessonId;

  Map<String, dynamic> toJson() => {'t': title, 'd': description, 'i': practiceItems, 'p': phoneme, 'l': lessonId};
}

/// Một lỗi âm vị để lưu vào bảng phoneme_errors.
class PhonemeErrorRecord {
  const PhonemeErrorRecord({required this.word, this.expected, this.actual, required this.type});

  final String word;
  final String? expected;
  final String? actual;

  /// substitution | deletion | insertion
  final String type;
}

class PronunciationResult {
  const PronunciationResult({
    required this.targetText,
    required this.recognizedText,
    required this.overall,
    required this.accuracy,
    required this.completeness,
    this.fluency,
    this.confidence,
    required this.words,
    required this.tips,
    required this.exercises,
    this.alternatives = const [],
  });

  factory PronunciationResult.fromJson(Map<String, dynamic> j) => PronunciationResult(
        targetText: j['target'] as String,
        recognizedText: j['recognized'] as String,
        overall: (j['overall'] as num).toDouble(),
        accuracy: (j['accuracy'] as num).toDouble(),
        completeness: (j['completeness'] as num).toDouble(),
        fluency: (j['fluency'] as num?)?.toDouble(),
        confidence: (j['confidence'] as num?)?.toDouble(),
        words: (j['words'] as List).map((e) => WordResult.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        tips: (j['tips'] as List).map((e) => FeedbackTip.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        exercises:
            (j['exercises'] as List).map((e) => ExerciseSuggestion.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        alternatives: (j['alternatives'] as List? ?? const []).cast<String>(),
      );

  final String targetText;
  final String recognizedText;

  /// Điểm tổng (0..100).
  final double overall;

  /// Độ chính xác âm vị (0..100).
  final double accuracy;

  /// Độ đầy đủ – tỉ lệ từ được nói ra (0..100).
  final double completeness;

  /// Độ trôi chảy (0..100), null nếu không đo được (nhập văn bản, câu quá ngắn).
  final double? fluency;

  /// Độ tin cậy của bộ nhận dạng giọng nói (0..1).
  final double? confidence;
  final List<WordResult> words;
  final List<FeedbackTip> tips;
  final List<ExerciseSuggestion> exercises;

  /// Các khả năng nhận dạng khác (N-best) do AI trả về.
  final List<String> alternatives;

  String get grade => gradeOf(overall);

  static String gradeOf(double score) {
    if (score >= 90) return 'Xuất sắc';
    if (score >= 75) return 'Tốt';
    if (score >= 60) return 'Khá';
    if (score >= 40) return 'Cần cố gắng';
    return 'Chưa đạt';
  }

  int get correctWordCount => words.where((w) => w.status == WordStatus.correct).length;

  /// Danh sách lỗi âm vị để thống kê.
  List<PhonemeErrorRecord> get errors {
    final out = <PhonemeErrorRecord>[];
    for (final w in words) {
      for (final p in w.phonemes) {
        if (p.status == PhonemeStatus.missing) {
          out.add(PhonemeErrorRecord(word: w.word, expected: p.expected, type: 'deletion'));
        } else if (p.status != PhonemeStatus.correct) {
          out.add(PhonemeErrorRecord(word: w.word, expected: p.expected, actual: p.actual, type: 'substitution'));
        }
      }
      for (final x in w.extraPhonemes) {
        out.add(PhonemeErrorRecord(word: w.word, actual: x, type: 'insertion'));
      }
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
        'target': targetText,
        'recognized': recognizedText,
        'overall': overall,
        'accuracy': accuracy,
        'completeness': completeness,
        'fluency': fluency,
        'confidence': confidence,
        'words': words.map((w) => w.toJson()).toList(),
        'tips': tips.map((t) => t.toJson()).toList(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'alternatives': alternatives,
      };
}

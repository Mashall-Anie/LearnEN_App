import 'dart:convert';

import '../pronunciation/pronunciation_result.dart';

/// Một lượt phát âm đã được chấm điểm (bảng pronunciation_attempts).
class AttemptRecord {
  const AttemptRecord({
    this.id,
    required this.userId,
    this.sessionId,
    this.lessonItemId,
    required this.targetText,
    required this.recognizedText,
    this.asrConfidence,
    required this.overallScore,
    required this.accuracyScore,
    required this.completenessScore,
    this.fluencyScore,
    this.speechDurationMs,
    this.inputMethod = 'voice',
    required this.analysisJson,
    required this.createdAt,
  });

  factory AttemptRecord.fromResult({
    required int userId,
    int? sessionId,
    int? lessonItemId,
    required PronunciationResult result,
    int? speechDurationMs,
    String inputMethod = 'voice',
    required DateTime createdAt,
  }) =>
      AttemptRecord(
        userId: userId,
        sessionId: sessionId,
        lessonItemId: lessonItemId,
        targetText: result.targetText,
        recognizedText: result.recognizedText,
        asrConfidence: result.confidence,
        overallScore: result.overall,
        accuracyScore: result.accuracy,
        completenessScore: result.completeness,
        fluencyScore: result.fluency,
        speechDurationMs: speechDurationMs,
        inputMethod: inputMethod,
        analysisJson: jsonEncode(result.toJson()),
        createdAt: createdAt,
      );

  factory AttemptRecord.fromMap(Map<String, Object?> m) => AttemptRecord(
        id: m['id'] as int,
        userId: m['user_id'] as int,
        sessionId: m['session_id'] as int?,
        lessonItemId: m['lesson_item_id'] as int?,
        targetText: m['target_text'] as String,
        recognizedText: m['recognized_text'] as String,
        asrConfidence: (m['asr_confidence'] as num?)?.toDouble(),
        overallScore: (m['overall_score'] as num).toDouble(),
        accuracyScore: (m['accuracy_score'] as num).toDouble(),
        completenessScore: (m['completeness_score'] as num).toDouble(),
        fluencyScore: (m['fluency_score'] as num?)?.toDouble(),
        speechDurationMs: m['speech_duration_ms'] as int?,
        inputMethod: m['input_method'] as String,
        analysisJson: m['analysis_json'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  final int? id;
  final int userId;
  final int? sessionId;
  final int? lessonItemId;
  final String targetText;
  final String recognizedText;
  final double? asrConfidence;
  final double overallScore;
  final double accuracyScore;
  final double completenessScore;
  final double? fluencyScore;
  final int? speechDurationMs;

  /// voice | text (chế độ kiểm thử)
  final String inputMethod;
  final String analysisJson;
  final DateTime createdAt;

  PronunciationResult get result =>
      PronunciationResult.fromJson(Map<String, dynamic>.from(jsonDecode(analysisJson) as Map));

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'session_id': sessionId,
        'lesson_item_id': lessonItemId,
        'target_text': targetText,
        'recognized_text': recognizedText,
        'asr_confidence': asrConfidence,
        'overall_score': overallScore,
        'accuracy_score': accuracyScore,
        'completeness_score': completenessScore,
        'fluency_score': fluencyScore,
        'speech_duration_ms': speechDurationMs,
        'input_method': inputMethod,
        'analysis_json': analysisJson,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Tổng hợp theo ngày (bảng daily_progress) – nguồn dữ liệu cho streak và mục tiêu ngày.
class DailyProgress {
  const DailyProgress({
    required this.date,
    this.studySeconds = 0,
    this.attemptCount = 0,
    this.scoreSum = 0,
    this.goalMinutes = 10,
  });

  factory DailyProgress.fromMap(Map<String, Object?> m) => DailyProgress(
        date: m['date'] as String,
        studySeconds: m['study_seconds'] as int,
        attemptCount: m['attempt_count'] as int,
        scoreSum: (m['score_sum'] as num).toDouble(),
        goalMinutes: m['goal_minutes'] as int,
      );

  /// yyyy-MM-dd theo giờ địa phương.
  final String date;
  final int studySeconds;
  final int attemptCount;
  final double scoreSum;
  final int goalMinutes;

  double get studyMinutes => studySeconds / 60;
  double? get averageScore => attemptCount == 0 ? null : scoreSum / attemptCount;
  bool get goalMet => studySeconds >= goalMinutes * 60;
  bool get practiced => attemptCount > 0;
}

/// Thống kê độ chính xác theo từng âm vị (bảng phoneme_stats).
class PhonemeStat {
  const PhonemeStat({required this.phoneme, required this.totalCount, required this.errorCount});

  factory PhonemeStat.fromMap(Map<String, Object?> m) => PhonemeStat(
        phoneme: m['phoneme'] as String,
        totalCount: m['total_count'] as int,
        errorCount: m['error_count'] as int,
      );

  final String phoneme;
  final int totalCount;
  final int errorCount;

  double get accuracy => totalCount == 0 ? 1 : 1 - errorCount / totalCount;
}

class StudyTotals {
  const StudyTotals({
    required this.totalSeconds,
    required this.totalAttempts,
    required this.practiceDays,
    this.averageScore,
    this.bestScore,
  });

  final int totalSeconds;
  final int totalAttempts;
  final int practiceDays;
  final double? averageScore;
  final double? bestScore;
}

import 'package:sqflite/sqflite.dart';

import '../../models/practice_models.dart';
import '../../pronunciation/pronunciation_result.dart';
import '../../utils/date_utils.dart';

class PracticeRepository {
  PracticeRepository(this._db);

  final Database _db;

  Future<int> startSession({required int userId, int? lessonId, required DateTime at}) =>
      _db.insert('practice_sessions', {
        'user_id': userId,
        'lesson_id': lessonId,
        'started_at': at.toIso8601String(),
      });

  Future<void> endSession(int sessionId, DateTime at) =>
      _db.update('practice_sessions', {'ended_at': at.toIso8601String()}, where: 'id = ?', whereArgs: [sessionId]);

  /// Lưu một lượt phát âm cùng các lỗi âm vị, đồng thời cập nhật thống kê
  /// âm vị, phiên luyện tập và tiến độ ngày – tất cả trong một transaction.
  Future<int> saveAttempt({
    required AttemptRecord attempt,
    required PronunciationResult result,
    required int goalMinutes,
  }) {
    return _db.transaction((txn) async {
      final id = await txn.insert('pronunciation_attempts', attempt.toMap()..remove('id'));
      final created = attempt.createdAt.toIso8601String();

      final batch = txn.batch();
      for (final e in result.errors) {
        batch.insert('phoneme_errors', {
          'attempt_id': id,
          'user_id': attempt.userId,
          'word': e.word,
          'expected_phoneme': e.expected,
          'actual_phoneme': e.actual,
          'error_type': e.type,
          'created_at': created,
        });
      }

      // Thống kê theo âm vị: tổng số lần xuất hiện và số lần sai.
      final totals = <String, int>{};
      final errors = <String, int>{};
      for (final w in result.words) {
        for (final p in w.phonemes) {
          totals[p.expected] = (totals[p.expected] ?? 0) + 1;
          if (p.isError) errors[p.expected] = (errors[p.expected] ?? 0) + 1;
        }
      }
      for (final entry in totals.entries) {
        // INSERT OR IGNORE + UPDATE thay cho UPSERT để chạy được trên SQLite cũ (Android 7–10).
        batch.rawInsert(
          'INSERT OR IGNORE INTO phoneme_stats(user_id, phoneme, total_count, error_count) VALUES (?, ?, 0, 0)',
          [attempt.userId, entry.key],
        );
        batch.rawUpdate(
          'UPDATE phoneme_stats SET total_count = total_count + ?, error_count = error_count + ? '
          'WHERE user_id = ? AND phoneme = ?',
          [entry.value, errors[entry.key] ?? 0, attempt.userId, entry.key],
        );
      }

      if (attempt.sessionId != null) {
        batch.rawUpdate(
          'UPDATE practice_sessions SET attempt_count = attempt_count + 1, score_sum = score_sum + ? WHERE id = ?',
          [attempt.overallScore, attempt.sessionId],
        );
      }
      _addDaily(batch, attempt.userId, dateKey(attempt.createdAt), goalMinutes,
          attempts: 1, score: attempt.overallScore);
      await batch.commit(noResult: true);
      return id;
    });
  }

  /// Cộng thời gian học vào phiên và vào ngày tương ứng.
  Future<void> addStudyTime({
    required int userId,
    int? sessionId,
    required int seconds,
    required DateTime at,
    required int goalMinutes,
  }) async {
    if (seconds <= 0) return;
    final batch = _db.batch();
    if (sessionId != null) {
      batch.rawUpdate(
        'UPDATE practice_sessions SET duration_seconds = duration_seconds + ? WHERE id = ?',
        [seconds, sessionId],
      );
    }
    _addDaily(batch, userId, dateKey(at), goalMinutes, seconds: seconds);
    await batch.commit(noResult: true);
  }

  void _addDaily(Batch batch, int userId, String date, int goalMinutes,
      {int seconds = 0, int attempts = 0, double score = 0}) {
    batch.rawInsert(
      'INSERT OR IGNORE INTO daily_progress(user_id, date, study_seconds, attempt_count, score_sum, goal_minutes) '
      'VALUES (?, ?, 0, 0, 0, ?)',
      [userId, date, goalMinutes],
    );
    batch.rawUpdate(
      'UPDATE daily_progress SET study_seconds = study_seconds + ?, attempt_count = attempt_count + ?, '
      'score_sum = score_sum + ?, goal_minutes = ? WHERE user_id = ? AND date = ?',
      [seconds, attempts, score, goalMinutes, userId, date],
    );
  }

  Future<List<AttemptRecord>> getRecentAttempts(int userId, {int limit = 100}) async {
    final rows = await _db.query('pronunciation_attempts',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC, id DESC', limit: limit);
    return rows.map(AttemptRecord.fromMap).toList();
  }

  Future<AttemptRecord?> getAttempt(int id) async {
    final rows = await _db.query('pronunciation_attempts', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : AttemptRecord.fromMap(rows.first);
  }

  Future<int> countErrors(int attemptId) async {
    final r = await _db.rawQuery('SELECT COUNT(*) AS n FROM phoneme_errors WHERE attempt_id = ?', [attemptId]);
    return r.first['n'] as int;
  }
}

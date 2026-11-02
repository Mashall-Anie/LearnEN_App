import 'package:sqflite/sqflite.dart';

import '../../models/practice_models.dart';
import '../../utils/date_utils.dart';

class ProgressRepository {
  ProgressRepository(this._db);

  final Database _db;

  /// Các ngày (yyyy-MM-dd) có ít nhất một lượt luyện phát âm – dùng để tính streak.
  Future<List<DateTime>> getPracticeDays(int userId) async {
    final rows = await _db.query('daily_progress',
        columns: ['date'], where: 'user_id = ? AND attempt_count > 0', whereArgs: [userId], orderBy: 'date');
    return rows.map((r) => parseDateKey(r['date'] as String)).toList();
  }

  Future<DailyProgress?> getDay(int userId, DateTime day) async {
    final rows =
        await _db.query('daily_progress', where: 'user_id = ? AND date = ?', whereArgs: [userId, dateKey(day)]);
    return rows.isEmpty ? null : DailyProgress.fromMap(rows.first);
  }

  /// Tiến độ từng ngày trong khoảng [from]..[to] (đủ mọi ngày, ngày trống = 0).
  Future<List<DailyProgress>> getRange(int userId, DateTime from, DateTime to, {int goalMinutes = 10}) async {
    final rows = await _db.query('daily_progress',
        where: 'user_id = ? AND date >= ? AND date <= ?', whereArgs: [userId, dateKey(from), dateKey(to)]);
    final byDate = {for (final r in rows) r['date'] as String: DailyProgress.fromMap(r)};
    final out = <DailyProgress>[];
    for (var d = dayOnly(from); !d.isAfter(dayOnly(to)); d = addDays(d, 1)) {
      final k = dateKey(d);
      out.add(byDate[k] ?? DailyProgress(date: k, goalMinutes: goalMinutes));
    }
    return out;
  }

  /// Âm vị yếu nhất (tỉ lệ sai cao nhất, xuất hiện ít nhất [minCount] lần).
  Future<List<PhonemeStat>> getWeakPhonemes(int userId, {int limit = 3, int minCount = 3}) async {
    final rows = await _db.rawQuery('''
      SELECT phoneme, total_count, error_count
      FROM phoneme_stats
      WHERE user_id = ? AND total_count >= ? AND error_count > 0
      ORDER BY CAST(error_count AS REAL) / total_count DESC, error_count DESC
      LIMIT ?
    ''', [userId, minCount, limit]);
    return rows.map(PhonemeStat.fromMap).toList();
  }

  Future<List<PhonemeStat>> getPhonemeStats(int userId) async {
    final rows = await _db.query('phoneme_stats', where: 'user_id = ?', whereArgs: [userId]);
    return rows.map(PhonemeStat.fromMap).toList();
  }

  /// Cặp nhầm lẫn thường gặp nhất: âm đúng → âm đã nói.
  Future<List<(String, String?, String, int)>> getTopConfusions(int userId, {int limit = 5}) async {
    final rows = await _db.rawQuery('''
      SELECT expected_phoneme, actual_phoneme, error_type, COUNT(*) AS n
      FROM phoneme_errors
      WHERE user_id = ? AND expected_phoneme IS NOT NULL
      GROUP BY expected_phoneme, actual_phoneme, error_type
      ORDER BY n DESC
      LIMIT ?
    ''', [userId, limit]);
    return rows
        .map((r) => (r['expected_phoneme'] as String, r['actual_phoneme'] as String?, r['error_type'] as String, r['n'] as int))
        .toList();
  }

  Future<StudyTotals> getTotals(int userId) async {
    final d = (await _db.rawQuery('''
      SELECT COALESCE(SUM(study_seconds), 0) AS secs,
             COUNT(CASE WHEN attempt_count > 0 THEN 1 END) AS days
      FROM daily_progress WHERE user_id = ?
    ''', [userId])).first;
    final a = (await _db.rawQuery('''
      SELECT COUNT(*) AS n, AVG(overall_score) AS avg, MAX(overall_score) AS best
      FROM pronunciation_attempts WHERE user_id = ?
    ''', [userId])).first;
    return StudyTotals(
      totalSeconds: (d['secs'] as num).toInt(),
      practiceDays: d['days'] as int,
      totalAttempts: a['n'] as int,
      averageScore: (a['avg'] as num?)?.toDouble(),
      bestScore: (a['best'] as num?)?.toDouble(),
    );
  }
}

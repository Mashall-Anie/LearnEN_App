import 'package:sqflite/sqflite.dart';

import '../../models/lesson.dart';

class LessonRepository {
  LessonRepository(this._db);

  final Database _db;

  Future<List<Lesson>> getLessons() async {
    final rows = await _db.query('lessons', orderBy: 'sort_order');
    return rows.map(Lesson.fromMap).toList();
  }

  Future<Lesson?> getLesson(int id) async {
    final rows = await _db.query('lessons', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Lesson.fromMap(rows.first);
  }

  Future<List<LessonItem>> getItems(int lessonId) async {
    final rows = await _db.query('lesson_items', where: 'lesson_id = ?', whereArgs: [lessonId], orderBy: 'sort_order');
    return rows.map(LessonItem.fromMap).toList();
  }

  /// Tiến độ của [userId] trên từng bài: số câu đã luyện, điểm cao nhất trung bình.
  Future<Map<int, LessonProgress>> getProgress(int userId) async {
    final rows = await _db.rawQuery('''
      SELECT li.lesson_id AS lesson_id,
             COUNT(*) AS item_count,
             COUNT(best.item_id) AS practiced,
             AVG(best.best_score) AS best_avg
      FROM lesson_items li
      LEFT JOIN (
        SELECT lesson_item_id AS item_id, MAX(overall_score) AS best_score
        FROM pronunciation_attempts
        WHERE user_id = ? AND lesson_item_id IS NOT NULL
        GROUP BY lesson_item_id
      ) best ON best.item_id = li.id
      GROUP BY li.lesson_id
    ''', [userId]);
    return {
      for (final r in rows)
        r['lesson_id'] as int: LessonProgress(
          lessonId: r['lesson_id'] as int,
          itemCount: r['item_count'] as int,
          practicedItems: r['practiced'] as int,
          bestAverage: (r['best_avg'] as num?)?.toDouble(),
        ),
    };
  }

  /// Điểm cao nhất của từng câu trong bài cho [userId].
  Future<Map<int, double>> getBestScores(int userId, int lessonId) async {
    final rows = await _db.rawQuery('''
      SELECT a.lesson_item_id AS item_id, MAX(a.overall_score) AS best
      FROM pronunciation_attempts a
      JOIN lesson_items li ON li.id = a.lesson_item_id
      WHERE a.user_id = ? AND li.lesson_id = ?
      GROUP BY a.lesson_item_id
    ''', [userId, lessonId]);
    return {for (final r in rows) r['item_id'] as int: (r['best'] as num).toDouble()};
  }
}

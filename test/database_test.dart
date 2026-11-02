// Kiểm thử CSDL SQLite (chạy bằng sqflite_common_ffi trên máy tính) với nhiều người dùng.
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_en_app/data/app_database.dart';
import 'package:learn_en_app/data/lesson_catalog.dart';
import 'package:learn_en_app/models/practice_models.dart';
import 'package:learn_en_app/models/user_profile.dart';
import 'package:learn_en_app/pronunciation/pronunciation_scorer.dart';
import 'package:learn_en_app/services/streak_calculator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase db;
  final scorer = PronunciationScorer();

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
  });
  tearDown(() => db.close());

  Future<UserProfile> newUser(String name, {int goal = 10}) =>
      db.users.create(UserProfile(name: name, dailyGoalMinutes: goal, createdAt: DateTime(2026, 10, 1)));

  Future<void> practise(UserProfile u, String target, String heard, DateTime at, {int? itemId, int seconds = 120}) async {
    final session = await db.practice.startSession(userId: u.id!, at: at);
    final result = scorer.evaluate(targetText: target, recognizedText: heard);
    await db.practice.saveAttempt(
      attempt: AttemptRecord.fromResult(userId: u.id!, sessionId: session, lessonItemId: itemId, result: result, createdAt: at),
      result: result,
      goalMinutes: u.dailyGoalMinutes,
    );
    await db.practice.addStudyTime(
        userId: u.id!, sessionId: session, seconds: seconds, at: at, goalMinutes: u.dailyGoalMinutes);
  }

  test('nạp sẵn giáo trình khi tạo CSDL', () async {
    final lessons = await db.lessons.getLessons();
    expect(lessons.length, kLessonCatalog.length);
    final items = await db.lessons.getItems(LessonIds.th);
    expect(items.first.text, 'think');
    expect(items.length, kLessonCatalog.first.items.length);
  });

  test('lưu lượt phát âm, lỗi âm vị và tiến độ ngày', () async {
    final an = await newUser('An');
    final day = DateTime(2026, 11, 2, 9);
    await practise(an, 'think', 'sink', day);

    final attempts = await db.practice.getRecentAttempts(an.id!);
    expect(attempts, hasLength(1));
    expect(attempts.single.result.words.single.phonemes.first.actual, 'S');
    expect(await db.practice.countErrors(attempts.single.id!), 1);

    final today = await db.progress.getDay(an.id!, day);
    expect(today!.attemptCount, 1);
    expect(today.studySeconds, 120);

    final stats = await db.progress.getPhonemeStats(an.id!);
    final th = stats.firstWhere((s) => s.phoneme == 'TH');
    expect(th.totalCount, 1);
    expect(th.errorCount, 1);
  });

  test('streak và dữ liệu tách biệt giữa nhiều người dùng', () async {
    final an = await newUser('An');
    final binh = await newUser('Bình', goal: 5);
    final today = DateTime(2026, 11, 2, 20);

    for (var i = 3; i >= 0; i--) {
      await practise(an, 'Nice to meet you.', 'nice to meet you', DateTime(2026, 11, 2 - i, 8));
    }
    await practise(binh, 'three', 'tree', DateTime(2026, 10, 30, 8));

    final anStreak = StreakCalculator.compute(await db.progress.getPracticeDays(an.id!), today);
    final binhStreak = StreakCalculator.compute(await db.progress.getPracticeDays(binh.id!), today);
    expect(anStreak.current, 4);
    expect(anStreak.practicedToday, isTrue);
    expect(binhStreak.current, 0);
    expect(binhStreak.longest, 1);

    expect((await db.practice.getRecentAttempts(an.id!)).length, 4);
    expect((await db.practice.getRecentAttempts(binh.id!)).length, 1);
    final binhTotals = await db.progress.getTotals(binh.id!);
    expect(binhTotals.totalAttempts, 1);
    expect(binhTotals.practiceDays, 1);
  });

  test('âm yếu nhất và tiến độ bài học', () async {
    final an = await newUser('An');
    final items = await db.lessons.getItems(LessonIds.th);
    final at = DateTime(2026, 11, 2, 10);
    await practise(an, items[0].text, 'sink', at, itemId: items[0].id); // think → sink
    await practise(an, items[1].text, 'tree', at, itemId: items[1].id); // three → tree
    await practise(an, items[0].text, 'think', at, itemId: items[0].id);

    final weak = await db.progress.getWeakPhonemes(an.id!, minCount: 2);
    expect(weak.first.phoneme, 'TH');
    expect(weak.first.errorCount, 2);
    expect(weak.first.totalCount, 3);

    final progress = await db.lessons.getProgress(an.id!);
    expect(progress[LessonIds.th]!.practicedItems, 2);
    final best = await db.lessons.getBestScores(an.id!, LessonIds.th);
    expect(best[items[0].id], greaterThanOrEqualTo(95));
  });

  test('getRange trả đủ mọi ngày, ngày trống = 0', () async {
    final an = await newUser('An');
    await practise(an, 'hello', 'hello', DateTime(2026, 11, 1, 10), seconds: 600);
    final range = await db.progress.getRange(an.id!, DateTime(2026, 10, 27), DateTime(2026, 11, 2));
    expect(range.length, 7);
    expect(range.where((d) => d.practiced).length, 1);
    expect(range[5].goalMet, isTrue); // 10 phút = mục tiêu 10 phút
  });

  test('xóa người dùng xóa theo toàn bộ dữ liệu (ON DELETE CASCADE)', () async {
    final an = await newUser('An');
    await practise(an, 'think', 'sink', DateTime(2026, 11, 2));
    await db.users.delete(an.id!);
    for (final table in ['pronunciation_attempts', 'phoneme_errors', 'phoneme_stats', 'daily_progress', 'practice_sessions']) {
      final rows = await db.db.rawQuery('SELECT COUNT(*) AS n FROM $table');
      expect(rows.first['n'], 0, reason: table);
    }
  });

  test('app_meta lưu người dùng cuối', () async {
    await db.setMeta('last_user_id', '7');
    expect(await db.getMeta('last_user_id'), '7');
    await db.setMeta('last_user_id', null);
    expect(await db.getMeta('last_user_id'), isNull);
  });
}

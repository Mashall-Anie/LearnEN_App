import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'lesson_catalog.dart';
import 'repositories/lesson_repository.dart';
import 'repositories/practice_repository.dart';
import 'repositories/progress_repository.dart';
import 'repositories/user_repository.dart';

/// CSDL SQLite cục bộ của ứng dụng. Sơ đồ chi tiết: docs/DATABASE.md
class AppDatabase {
  AppDatabase._(this.db)
      : users = UserRepository(db),
        lessons = LessonRepository(db),
        practice = PracticeRepository(db),
        progress = ProgressRepository(db);

  static const fileName = 'learn_en.db';
  static const version = 1;

  final Database db;
  final UserRepository users;
  final LessonRepository lessons;
  final PracticeRepository practice;
  final ProgressRepository progress;

  /// Mở (hoặc tạo) CSDL. Unit test truyền [factory] = databaseFactoryFfi và
  /// [path] = inMemoryDatabasePath.
  static Future<AppDatabase> open({String? path, DatabaseFactory? factory}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), fileName);
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
      ),
    );
    return AppDatabase._(db);
  }

  Future<void> close() => db.close();

  static const List<String> schema = [
    '''
    CREATE TABLE users (
      id                 INTEGER PRIMARY KEY AUTOINCREMENT,
      name               TEXT    NOT NULL,
      avatar             TEXT    NOT NULL DEFAULT '🙂',
      daily_goal_minutes INTEGER NOT NULL DEFAULT 10,
      reminder_enabled   INTEGER NOT NULL DEFAULT 1,
      reminder_hour      INTEGER NOT NULL DEFAULT 20,
      reminder_minute    INTEGER NOT NULL DEFAULT 0,
      speech_rate        REAL    NOT NULL DEFAULT 0.45,
      test_mode          INTEGER NOT NULL DEFAULT 0,
      created_at         TEXT    NOT NULL,
      last_active_at     TEXT
    )''',
    '''
    CREATE TABLE lessons (
      id             INTEGER PRIMARY KEY,
      title          TEXT    NOT NULL,
      description    TEXT    NOT NULL,
      focus_phonemes TEXT    NOT NULL,
      level          TEXT    NOT NULL,
      icon           TEXT    NOT NULL,
      sort_order     INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE lesson_items (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      lesson_id  INTEGER NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
      text       TEXT    NOT NULL,
      meaning    TEXT    NOT NULL,
      sort_order INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE practice_sessions (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id          INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      lesson_id        INTEGER REFERENCES lessons(id),
      started_at       TEXT    NOT NULL,
      ended_at         TEXT,
      duration_seconds INTEGER NOT NULL DEFAULT 0,
      attempt_count    INTEGER NOT NULL DEFAULT 0,
      score_sum        REAL    NOT NULL DEFAULT 0
    )''',
    '''
    CREATE TABLE pronunciation_attempts (
      id                 INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id            INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      session_id         INTEGER REFERENCES practice_sessions(id) ON DELETE SET NULL,
      lesson_item_id     INTEGER REFERENCES lesson_items(id) ON DELETE SET NULL,
      target_text        TEXT    NOT NULL,
      recognized_text    TEXT    NOT NULL,
      asr_confidence     REAL,
      overall_score      REAL    NOT NULL,
      accuracy_score     REAL    NOT NULL,
      completeness_score REAL    NOT NULL,
      fluency_score      REAL,
      speech_duration_ms INTEGER,
      input_method       TEXT    NOT NULL DEFAULT 'voice',
      analysis_json      TEXT    NOT NULL,
      created_at         TEXT    NOT NULL
    )''',
    '''
    CREATE TABLE phoneme_errors (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      attempt_id       INTEGER NOT NULL REFERENCES pronunciation_attempts(id) ON DELETE CASCADE,
      user_id          INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      word             TEXT    NOT NULL,
      expected_phoneme TEXT,
      actual_phoneme   TEXT,
      error_type       TEXT    NOT NULL,
      created_at       TEXT    NOT NULL
    )''',
    '''
    CREATE TABLE phoneme_stats (
      user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      phoneme     TEXT    NOT NULL,
      total_count INTEGER NOT NULL DEFAULT 0,
      error_count INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (user_id, phoneme)
    )''',
    '''
    CREATE TABLE daily_progress (
      user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      date          TEXT    NOT NULL,
      study_seconds INTEGER NOT NULL DEFAULT 0,
      attempt_count INTEGER NOT NULL DEFAULT 0,
      score_sum     REAL    NOT NULL DEFAULT 0,
      goal_minutes  INTEGER NOT NULL DEFAULT 10,
      PRIMARY KEY (user_id, date)
    )''',
    '''
    CREATE TABLE app_meta (
      key   TEXT PRIMARY KEY,
      value TEXT
    )''',
    'CREATE INDEX idx_attempts_user_time ON pronunciation_attempts(user_id, created_at)',
    'CREATE INDEX idx_attempts_item ON pronunciation_attempts(user_id, lesson_item_id)',
    'CREATE INDEX idx_errors_user_phoneme ON phoneme_errors(user_id, expected_phoneme)',
    'CREATE INDEX idx_sessions_user_time ON practice_sessions(user_id, started_at)',
    'CREATE INDEX idx_items_lesson ON lesson_items(lesson_id, sort_order)',
  ];

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final sql in schema) {
      batch.execute(sql);
    }
    await batch.commit(noResult: true);
    await seedLessons(db);
  }

  /// Nạp giáo trình mặc định.
  static Future<void> seedLessons(DatabaseExecutor db) async {
    final batch = db.batch();
    for (var i = 0; i < kLessonCatalog.length; i++) {
      final l = kLessonCatalog[i];
      batch.insert('lessons', {
        'id': l.id,
        'title': l.title,
        'description': l.description,
        'focus_phonemes': l.focusPhonemes.join(','),
        'level': l.level,
        'icon': l.icon,
        'sort_order': i,
      });
      for (var j = 0; j < l.items.length; j++) {
        batch.insert('lesson_items', {
          'lesson_id': l.id,
          'text': l.items[j][0],
          'meaning': l.items[j][1],
          'sort_order': j,
        });
      }
    }
    await batch.commit(noResult: true);
  }

  Future<String?> getMeta(String key) async {
    final rows = await db.query('app_meta', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String? value) =>
      db.insert('app_meta', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
}

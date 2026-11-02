import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import '../models/practice_models.dart';
import '../models/user_profile.dart';
import '../pronunciation/pronunciation_scorer.dart';
import '../services/notification_service.dart';
import '../services/speech_service.dart';
import '../services/streak_calculator.dart';
import '../services/tts_service.dart';
import '../utils/date_utils.dart';

/// Dữ liệu cho màn hình Tổng quan.
class DashboardData {
  const DashboardData({
    required this.streak,
    required this.today,
    required this.last7Days,
    required this.weakPhonemes,
    required this.totals,
  });

  final StreakInfo streak;
  final DailyProgress today;
  final List<DailyProgress> last7Days;
  final List<PhonemeStat> weakPhonemes;
  final StudyTotals totals;

  double get goalProgress => today.goalMinutes == 0 ? 1 : (today.studySeconds / (today.goalMinutes * 60)).clamp(0.0, 1.0);
}

class AppState extends ChangeNotifier {
  AppState({
    required this.database,
    required this.notifications,
    SpeechService? speech,
    TtsService? tts,
    PronunciationScorer? scorer,
    DateTime Function()? clock,
  })  : speech = speech ?? SpeechService(),
        tts = tts ?? TtsService(),
        scorer = scorer ?? PronunciationScorer(),
        clock = clock ?? DateTime.now;

  static const _lastUserKey = 'last_user_id';

  final AppDatabase database;
  final NotificationService notifications;
  final SpeechService speech;
  final TtsService tts;
  final PronunciationScorer scorer;
  final DateTime Function() clock;

  List<UserProfile> users = [];
  UserProfile? currentUser;
  DashboardData? dashboard;
  bool initialized = false;

  Future<void> init() async {
    users = await database.users.getAll();
    final lastId = int.tryParse(await database.getMeta(_lastUserKey) ?? '');
    if (lastId != null) {
      for (final u in users) {
        if (u.id == lastId) {
          await selectUser(u, notify: false);
          break;
        }
      }
    }
    initialized = true;
    notifyListeners();
  }

  Future<void> reloadUsers() async {
    users = await database.users.getAll();
    notifyListeners();
  }

  Future<UserProfile> createUser({required String name, required String avatar, required int dailyGoalMinutes}) async {
    final user = await database.users.create(UserProfile(
      name: name.trim(),
      avatar: avatar,
      dailyGoalMinutes: dailyGoalMinutes,
      createdAt: clock(),
    ));
    users = await database.users.getAll();
    notifyListeners();
    return user;
  }

  Future<void> selectUser(UserProfile user, {bool notify = true}) async {
    currentUser = user;
    await database.users.touch(user.id!, clock());
    await database.setMeta(_lastUserKey, '${user.id}');
    await refreshDashboard(notify: false);
    if (notify) notifyListeners();
    if (user.reminderEnabled) {
      await notifications.requestPermission();
      await _rescheduleReminder();
    }
  }

  void logout() {
    currentUser = null;
    dashboard = null;
    database.setMeta(_lastUserKey, null);
    reloadUsers();
  }

  Future<void> updateUser(UserProfile user) async {
    await database.users.update(user);
    if (currentUser?.id == user.id) currentUser = user;
    users = await database.users.getAll();
    await refreshDashboard(notify: false);
    notifyListeners();
    await _rescheduleReminder();
  }

  Future<void> deleteUser(UserProfile user) async {
    await notifications.cancelReminder(user.id!);
    await database.users.delete(user.id!);
    if (currentUser?.id == user.id) {
      currentUser = null;
      dashboard = null;
      await database.setMeta(_lastUserKey, null);
    }
    users = await database.users.getAll();
    notifyListeners();
  }

  Future<void> refreshDashboard({bool notify = true}) async {
    final user = currentUser;
    if (user == null) return;
    final now = clock();
    final days = await database.progress.getPracticeDays(user.id!);
    final streak = StreakCalculator.compute(days, now);
    final last7 = await database.progress.getRange(user.id!, addDays(now, -6), now, goalMinutes: user.dailyGoalMinutes);
    final weak = await database.progress.getWeakPhonemes(user.id!);
    final totals = await database.progress.getTotals(user.id!);
    final today = last7.last;
    dashboard = DashboardData(
      streak: streak,
      today: DailyProgress(
        date: today.date,
        studySeconds: today.studySeconds,
        attemptCount: today.attemptCount,
        scoreSum: today.scoreSum,
        goalMinutes: user.dailyGoalMinutes,
      ),
      last7Days: last7,
      weakPhonemes: weak,
      totals: totals,
    );
    if (notify) notifyListeners();
  }

  /// Gọi sau mỗi lượt luyện / khi rời màn hình luyện tập.
  Future<void> onPracticeProgress() async {
    await refreshDashboard();
    await _rescheduleReminder();
  }

  /// Đặt lại lời nhắc: nội dung theo streak mới; nếu hôm nay đã đạt mục tiêu
  /// thì hôm nay không nhắc nữa, bắt đầu nhắc lại từ ngày mai.
  Future<void> _rescheduleReminder() async {
    final user = currentUser;
    final d = dashboard;
    if (user == null) return;
    await notifications.scheduleDailyReminder(
      user,
      streak: d?.streak.current ?? 0,
      skipToday: d?.today.goalMet ?? false,
    );
  }
}

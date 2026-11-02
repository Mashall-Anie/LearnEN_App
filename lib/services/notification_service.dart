import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/user_profile.dart';

/// Thông báo nhắc nhở luyện tập hằng ngày (mỗi người học một lịch riêng).
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'daily_reminder';
  static const _channelName = 'Nhắc nhở luyện tập';
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Nhắc bạn luyện phát âm mỗi ngày để giữ chuỗi streak',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static int reminderIdFor(int userId) => 1000 + userId;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      }
      await _plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService.init lỗi: $e');
    }
  }

  /// Xin quyền hiển thị thông báo (Android 13+).
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  /// Thời điểm nhắc kế tiếp. Nếu [skipToday] (đã đạt mục tiêu hôm nay) thì bắt đầu từ ngày mai.
  static DateTime nextReminderTime(DateTime now, int hour, int minute, {bool skipToday = false}) {
    var t = DateTime(now.year, now.month, now.day, hour, minute);
    if (skipToday || !t.isAfter(now)) t = DateTime(now.year, now.month, now.day + 1, hour, minute);
    return t;
  }

  /// Nội dung nhắc nhở, cá nhân hóa theo tên và chuỗi ngày hiện tại.
  static (String, String) reminderText(UserProfile user, int streak) {
    if (streak > 0) {
      return (
        '🔥 Giữ chuỗi $streak ngày nhé, ${user.name}!',
        'Dành ${user.dailyGoalMinutes} phút luyện phát âm hôm nay để không mất chuỗi.',
      );
    }
    return (
      '🎤 Đến giờ luyện phát âm rồi, ${user.name}!',
      'Chỉ ${user.dailyGoalMinutes} phút mỗi ngày – bắt đầu một chuỗi streak mới nào.',
    );
  }

  /// Đặt (hoặc đặt lại) lịch nhắc lặp lại hằng ngày cho [user].
  Future<void> scheduleDailyReminder(UserProfile user, {int streak = 0, bool skipToday = false}) async {
    await init();
    if (!_initialized || user.id == null) return;
    final id = reminderIdFor(user.id!);
    await _plugin.cancel(id: id);
    if (!user.reminderEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final next = nextReminderTime(now, user.reminderHour, user.reminderMinute, skipToday: skipToday);
    final (title, body) = reminderText(user, streak);
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime(tz.local, next.year, next.month, next.day, next.hour, next.minute),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Không đặt được lịch nhắc: $e');
    }
  }

  Future<void> cancelReminder(int userId) async {
    await init();
    if (!_initialized) return;
    await _plugin.cancel(id: reminderIdFor(userId));
  }

  /// Gửi một thông báo ngay để kiểm tra.
  Future<void> showTest(UserProfile user, int streak) async {
    await init();
    if (!_initialized) return;
    final (title, body) = reminderText(user, streak);
    await _plugin.show(id: 999, title: title, body: body, notificationDetails: _details);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_en_app/models/user_profile.dart';
import 'package:learn_en_app/services/notification_service.dart';
import 'package:learn_en_app/services/streak_calculator.dart';
import 'package:learn_en_app/services/study_timer.dart';

void main() {
  group('StreakCalculator', () {
    final today = DateTime(2026, 11, 2, 21);

    test('chưa luyện ngày nào', () {
      final s = StreakCalculator.compute([], today);
      expect(s.current, 0);
      expect(s.longest, 0);
    });

    test('luyện liên tục đến hôm nay', () {
      final s = StreakCalculator.compute(
          [DateTime(2026, 10, 31), DateTime(2026, 11, 1), DateTime(2026, 11, 2, 7)], today);
      expect(s.current, 3);
      expect(s.practicedToday, isTrue);
      expect(s.atRisk, isFalse);
    });

    test('hôm nay chưa luyện thì chuỗi vẫn giữ nhưng "có nguy cơ"', () {
      final s = StreakCalculator.compute([DateTime(2026, 10, 31), DateTime(2026, 11, 1)], today);
      expect(s.current, 2);
      expect(s.practicedToday, isFalse);
      expect(s.atRisk, isTrue);
    });

    test('bỏ một ngày thì mất chuỗi, kỷ lục vẫn được giữ', () {
      final s = StreakCalculator.compute([
        DateTime(2026, 10, 20),
        DateTime(2026, 10, 21),
        DateTime(2026, 10, 22),
        DateTime(2026, 10, 23),
        DateTime(2026, 10, 31),
      ], today);
      expect(s.current, 0);
      expect(s.longest, 4);
    });

    test('nhiều lượt trong cùng một ngày chỉ tính một ngày; qua tháng vẫn liền mạch', () {
      final s = StreakCalculator.compute([
        DateTime(2026, 10, 31, 8),
        DateTime(2026, 10, 31, 22),
        DateTime(2026, 11, 1, 9),
        DateTime(2026, 11, 2, 6),
      ], today);
      expect(s.current, 3);
    });
  });

  group('StudyTimer', () {
    test('cộng thời gian giữa các tương tác, giới hạn thời gian rảnh', () {
      var now = DateTime(2026, 11, 2, 10);
      final timer = StudyTimer(maxIdleGap: const Duration(minutes: 2), clock: () => now);
      timer.start();
      now = now.add(const Duration(seconds: 30));
      timer.markActivity();
      now = now.add(const Duration(minutes: 10)); // để máy 10 phút → chỉ tính 2 phút
      timer.markActivity();
      expect(timer.takeSeconds(), 150);
      expect(timer.takeSeconds(), 0);
    });

    test('không tính thời gian khi ứng dụng chạy nền', () {
      var now = DateTime(2026, 11, 2, 10);
      final timer = StudyTimer(clock: () => now);
      timer.start();
      now = now.add(const Duration(seconds: 20));
      timer.pause();
      now = now.add(const Duration(minutes: 30));
      timer.resume();
      now = now.add(const Duration(seconds: 10));
      expect(timer.takeSeconds(), 30);
    });
  });

  group('Lịch nhắc nhở', () {
    test('giờ nhắc kế tiếp', () {
      final morning = DateTime(2026, 11, 2, 7);
      expect(NotificationService.nextReminderTime(morning, 20, 0), DateTime(2026, 11, 2, 20));
      final night = DateTime(2026, 11, 2, 21);
      expect(NotificationService.nextReminderTime(night, 20, 0), DateTime(2026, 11, 3, 20));
      expect(NotificationService.nextReminderTime(morning, 20, 0, skipToday: true), DateTime(2026, 11, 3, 20));
      // Cuối tháng
      expect(NotificationService.nextReminderTime(DateTime(2026, 11, 30, 22), 8, 30), DateTime(2026, 12, 1, 8, 30));
    });

    test('nội dung nhắc theo streak', () {
      final u = UserProfile(name: 'An', dailyGoalMinutes: 15, createdAt: DateTime(2026));
      expect(NotificationService.reminderText(u, 5).$1, contains('5 ngày'));
      expect(NotificationService.reminderText(u, 0).$2, contains('15 phút'));
    });
  });
}

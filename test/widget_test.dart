import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_en_app/app.dart';
import 'package:learn_en_app/data/app_database.dart';
import 'package:learn_en_app/models/user_profile.dart';
import 'package:learn_en_app/pronunciation/pronunciation_scorer.dart';
import 'package:learn_en_app/services/notification_service.dart';
import 'package:learn_en_app/state/app_state.dart';
import 'package:learn_en_app/widgets/pronunciation_feedback_view.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Thông báo giả – môi trường test không có plugin native.
class FakeNotifications extends NotificationService {
  final scheduled = <int, bool>{};

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleDailyReminder(UserProfile user, {int streak = 0, bool skipToday = false}) async {
    scheduled[user.id!] = skipToday;
  }

  @override
  Future<void> cancelReminder(int userId) async => scheduled.remove(userId);
}

void main() {
  sqfliteFfiInit();

  testWidgets('Màn hình kết quả hiển thị điểm, từ sai và gợi ý', (tester) async {
    final result = PronunciationScorer().evaluate(targetText: 'I think so', recognizedText: 'I sink so', confidence: 0.8);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: PronunciationFeedbackView(result: result, onSpeak: (_) {}))),
    ));
    await tester.pumpAndSettle();

    // "think" xuất hiện ở phần phân tích từ và trong bài tập cặp từ tối thiểu.
    expect(find.text('think'), findsNWidgets(2));
    expect(find.text('Gợi ý cải thiện'), findsOneWidget);
    expect(find.textContaining('/θ/ bị đọc thành /s/'), findsOneWidget);
    expect(find.text('Bài tập đề xuất'), findsOneWidget);

    // Chạm vào từ để xem bảng âm vị chi tiết.
    await tester.tap(find.text('think').first);
    await tester.pumpAndSettle();
    expect(find.text('✗ Sai'), findsNothing); // /θ/→/s/ là "gần đúng"
    expect(find.text('≈ Gần đúng'), findsOneWidget);
  });

  testWidgets('Tạo người học mới rồi vào trang tổng quan', (tester) async {
    late AppState state;
    await tester.runAsync(() async {
      final db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
      state = AppState(database: db, notifications: FakeNotifications());
      await state.init();
    });

    await tester.pumpWidget(ChangeNotifierProvider.value(value: state, child: const LearnEnApp()));
    await tester.pump();
    expect(find.text('Tạo hồ sơ để bắt đầu'), findsOneWidget);

    // Hộp thoại tạo hồ sơ kiểm tra tên trống.
    await tester.tap(find.text('Thêm người học'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pump();
    expect(find.text('Nhập tên người học'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    // Thao tác CSDL thật cần chạy ngoài vùng thời gian giả của widget test.
    await tester.runAsync(() async {
      final user = await state.createUser(name: 'Minh', avatar: '🦊', dailyGoalMinutes: 15);
      await state.selectUser(user);
    });
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(state.currentUser?.name, 'Minh');
    expect(find.textContaining('Chào Minh'), findsOneWidget);
    expect(find.text('Chuỗi ngày'), findsOneWidget);
    expect(find.text('Mục tiêu hôm nay'), findsOneWidget);
    expect((state.notifications as FakeNotifications).scheduled.containsKey(state.currentUser!.id), isTrue);
  });
}

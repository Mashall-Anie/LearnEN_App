# LearnEN – Ứng dụng học tiếng Anh với phân tích phát âm AI

Bài thực hành **TH3** – môn Lập trình Android với Flutter.

Ứng dụng giúp người Việt luyện phát âm tiếng Anh: thu giọng nói, nhận dạng bằng AI, so sánh từng **âm vị** với phiên âm chuẩn, chấm điểm, đánh dấu âm sai và gợi ý bài tập; đồng thời rèn **tính kỷ luật** bằng streak, mục tiêu ngày, thống kê và nhắc nhở hằng ngày.

## Tính năng theo checklist

| # | Yêu cầu | Thực hiện | Mã nguồn chính |
|---|---|---|---|
| 1 | CSDL lưu người dùng, lịch sử luyện tập, kết quả phân tích | SQLite 9 bảng, khóa ngoại, transaction, chỉ mục – xem [docs/DATABASE.md](docs/DATABASE.md) | [lib/data/](lib/data/) |
| 2 | Streak, thống kê thời gian học, mục tiêu ngày | Streak hiện tại + kỷ lục, đồng hồ học "thực" (bỏ thời gian rảnh/chạy nền), mục tiêu phút/ngày, biểu đồ 7/30 ngày, lịch 5 tuần | [streak_calculator.dart](lib/services/streak_calculator.dart), [study_timer.dart](lib/services/study_timer.dart), [stats_screen.dart](lib/screens/stats_screen.dart) |
| 3 | API nhận dạng giọng nói | `speech_to_text` (dịch vụ nhận dạng của Google trên Android): kết quả tạm thời, kết quả cuối, độ tin cậy, N-best, mức âm lượng | [speech_service.dart](lib/services/speech_service.dart) |
| 4 | Mô hình AI / so sánh âm vị để chấm điểm | Từ điển phiên âm ARPAbet + suy luận hình thái + quy tắc chính tả → căn chỉnh **Needleman–Wunsch có trọng số ngữ âm** → điểm Chính xác / Đầy đủ / Trôi chảy / Độ tin cậy AI | [lib/pronunciation/](lib/pronunciation/) |
| 5 | Phản hồi: điểm, đánh dấu âm sai, đề xuất bài tập | Vòng điểm + 4 điểm thành phần, từ tô màu, IPA từng âm tô đỏ chỗ sai, bảng "âm chuẩn / bạn nói", mẹo khẩu hình cho người Việt, cặp từ tối thiểu, nút "Luyện ngay" | [feedback_generator.dart](lib/pronunciation/feedback_generator.dart), [pronunciation_feedback_view.dart](lib/widgets/pronunciation_feedback_view.dart) |
| 6 | Thông báo nhắc nhở + giao diện tiến độ | Nhắc hằng ngày theo giờ chọn, nội dung theo streak, tự bỏ qua hôm nay khi đã đạt mục tiêu, khôi phục sau khởi động lại máy; trang Tổng quan + Thống kê | [notification_service.dart](lib/services/notification_service.dart), [dashboard_screen.dart](lib/screens/dashboard_screen.dart) |
| 7 | Kiểm thử nhiều người dùng, nhiều giọng | Nhiều hồ sơ người học trên một máy; 13 ca mô phỏng giọng (bản ngữ, giọng Việt các miền, nhầm R/L, trẻ em, môi trường ồn…); 50 unit/widget test; màn hình "Phòng kiểm thử AI" – xem [docs/TESTING.md](docs/TESTING.md) | [accent_test_cases.dart](lib/pronunciation/accent_test_cases.dart), [test/](test/) |

## Thuật toán phân tích phát âm

```
Giọng nói ──► Speech-to-Text (AI của Google) ──► "I sink dis is de tird one" (+ độ tin cậy, N-best, thời lượng)
                                                       │
Câu mẫu "I think this is the third one" ───────────────┤
                                                       ▼
                         Chuẩn hóa văn bản (bỏ dấu câu, "3" → "three")
                                                       ▼
            Chuyển sang âm vị: từ điển ARPAbet → hình thái (-s, -ed, -ing) → quy tắc chính tả
            mẫu:  AY | TH IH NG K | DH IH S | IH Z | DH AX | TH ER D | W AH N
            nói:  AY | S  IH NG K | D  IH S | IH Z | D  IY | T  ER D | W AH N
                                                       ▼
            Căn chỉnh Needleman–Wunsch; chi phí thay thế = khoảng cách đặc trưng ngữ âm
            (vị trí cấu âm, phương thức, hữu thanh / độ mở, vị trí lưỡi, tròn môi, độ dài…)
            θ→s = 0.15 (gần đúng)   θ→t = 0.50 (sai)   thiếu / thừa âm = 1.0
                                                       ▼
            Điểm = 0.7·Chính xác + 0.15·Đầy đủ + 0.15·Trôi chảy, × (0.85 + 0.15·độ tin cậy ASR)
                                                       ▼
            Phản hồi: gom lỗi theo (âm đúng → âm đã nói), mẹo cho từng cặp nhầm lẫn,
            phát hiện "nuốt âm cuối", cặp từ tối thiểu, bài học liên quan
```

## Cấu trúc thư mục

```
lib/
  main.dart, app.dart          Khởi động, theme Material 3, tiếng Việt
  data/                        SQLite: app_database.dart, lesson_catalog.dart (10 bài), repositories/
  models/                      UserProfile, Lesson, AttemptRecord, DailyProgress, PhonemeStat
  pronunciation/               Lõi AI: phoneme_inventory, pronouncing_dictionary, phoneme_aligner,
                               pronunciation_scorer, feedback_generator, accent_test_cases
  services/                    speech_service, tts_service, notification_service, streak_calculator, study_timer
  state/app_state.dart         Quản lý trạng thái (Provider)
  screens/                     Chọn người học, Tổng quan, Bài học, Luyện tập, Thống kê, Lịch sử, Cài đặt, Phòng kiểm thử AI
  widgets/                     Vòng điểm, biểu đồ (fl_chart), khung phản hồi phát âm
test/                          50 test tự động
docs/                          DATABASE.md, TESTING.md
```

## Cài đặt & chạy

Môi trường đã cài trên máy này (ổ D:):

| Thành phần | Đường dẫn |
|---|---|
| Flutter 3.47.9 (stable) | `D:\src\flutter` |
| JDK 17 (Microsoft OpenJDK) | `D:\src\jdk-17` |
| Android SDK (platform 36, build-tools 35/36, NDK 28) | `D:\src\android-sdk` |

Biến môi trường người dùng `JAVA_HOME`, `ANDROID_HOME` và `PATH` đã được thiết lập – mở terminal mới để dùng lệnh `flutter`.

```bash
flutter pub get
flutter test
flutter build apk --release
```

File APK: `build/app/outputs/flutter-apk/app-release.apk`. Chép sang điện thoại Android (7.0 trở lên), mở file để cài (cho phép "Cài ứng dụng không rõ nguồn gốc" nếu được hỏi).

Muốn APK nhỏ hơn cho riêng điện thoại 64-bit: `flutter build apk --release --split-per-abi` rồi dùng file `app-arm64-v8a-release.apk`.

**Lưu ý khi chạy trên điện thoại**

- Nhận dạng giọng nói dùng dịch vụ của Google: điện thoại cần có ứng dụng **Google** và bật mạng (hoặc đã tải gói tiếng Anh offline).
- Cho phép quyền **Micro** và **Thông báo** khi app hỏi.
- Không có micro (máy ảo)? Vào **Cài đặt → Chế độ kiểm thử** để nhập câu mô phỏng thay cho giọng nói.

## Thư viện sử dụng

`sqflite`, `speech_to_text`, `flutter_tts`, `flutter_local_notifications`, `timezone`, `flutter_timezone`, `fl_chart`, `provider`, `intl`, `flutter_localizations`; test: `sqflite_common_ffi`.

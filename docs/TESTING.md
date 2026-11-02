# Báo cáo kiểm thử – LearnEN

## 1. Kiểm thử tự động

Chạy toàn bộ: `flutter test` → **50/50 test đạt** (Flutter 3.47.9, Dart 3.13.7, Windows 11, ngày 02/11/2026). `flutter analyze`: không có lỗi/cảnh báo.

| File test | Nội dung | Số test |
|---|---|---|
| [test/phoneme_analysis_test.dart](../test/phoneme_analysis_test.dart) | Chuẩn hóa văn bản, đổi số → chữ, từ điển phiên âm, suy luận -s/-ed/-ing, quy tắc chính tả, khoảng cách ngữ âm, căn chỉnh âm vị, chấm điểm, lưu/đọc JSON | 18 |
| [test/accent_simulation_test.dart](../test/accent_simulation_test.dart) | 13 kiểu người nói / giọng khác nhau + kiểm tra giọng chuẩn luôn cao điểm hơn giọng có lỗi | 14 |
| [test/database_test.dart](../test/database_test.dart) | CSDL SQLite thật (sqflite_common_ffi): nạp giáo trình, lưu lượt nói, **dữ liệu tách biệt giữa nhiều người dùng**, âm yếu nhất, tiến độ bài, xóa dây chuyền | 7 |
| [test/progress_tracking_test.dart](../test/progress_tracking_test.dart) | Streak (liên tục, qua tháng, mất chuỗi, kỷ lục), bộ đếm thời gian học, giờ nhắc nhở | 9 |
| [test/widget_test.dart](../test/widget_test.dart) | Giao diện kết quả phân tích; luồng tạo người học → trang tổng quan | 2 |

## 2. Kiểm thử độ chính xác AI với nhiều giọng nói (mô phỏng)

Mỗi ca mô phỏng **câu mà bộ nhận dạng giọng nói trả về** khi một kiểu người nói đọc câu mẫu, kèm độ tin cậy và thời lượng nói. Bộ ca nằm trong [lib/pronunciation/accent_test_cases.dart](../lib/pronunciation/accent_test_cases.dart), dùng chung cho unit test và màn hình **Cài đặt → Phòng kiểm thử AI** trong app.

Kết quả thực tế (điểm 0–100):

| Ca | Người nói | Câu AI nghe được | Tổng | Chính xác | Đầy đủ | Trôi chảy | Lỗi AI phát hiện | Kỳ vọng | Đạt |
|---|---|---|---|---|---|---|---|---|---|
| native-th | Bản ngữ (Mỹ) | I think this is the third one | 99.3 | 100 | 100 | 100 | – | ≥ 90, không lỗi | ✅ |
| vn-th | Người Việt mới học | I sink dis is de tird one | 74.8 | 70.4 | 100 | 100 | θ→s, ð→d (×2), ə→iː, θ→t | 40–80, có lỗi TH, DH | ✅ |
| vn-final | Người Việt nuốt âm cuối | he ask for six desk | 84.6 | 81.7 | 100 | 100 | thiếu /t/ (asked), thiếu /s/ (desks) | 55–90, lỗi T, S | ✅ |
| rl-confusion | Người học châu Á nhầm R/L | the led lorry lolled down the load | 81.3 | 78.8 | 100 | 100 | r→l (×3), oʊ→ɑː | 45–85, lỗi R | ✅ |
| vowel-length | Nhầm nguyên âm dài/ngắn | please seat in this sit | 84.7 | 82.9 | 100 | 100 | ɪ→iː, iː→ɪ | 50–88, lỗi IH, IY | ✅ |
| sh-s | Người Việt miền Nam | see sells sea sells | 82.3 | 80.3 | 100 | 100 | ʃ→s (×2) | 50–88, lỗi SH | ✅ |
| v-w | Nhầm V/W/B | we have berry fine wetter | 83.8 | 82.5 | 100 | 100 | v→b, ð→t | 45–88, lỗi V, DH | ✅ |
| female-native | Giọng nữ bản ngữ (Anh) | could you help me please | 99.0 | 100 | 100 | 100 | – | ≥ 90, không lỗi | ✅ |
| child-slow | Trẻ em nói rất chậm (9 s) | where is the nearest bus station | 89.9 | 100 | 100 | 46.7 | – (chỉ trừ điểm trôi chảy) | 75–95 | ✅ |
| quiet-partial | Nói nhỏ / môi trường ồn | where is the | 37.4 | 36.4 | 50 | 50 | thiếu 3 từ cuối | ≤ 60 | ✅ |
| wrong-sentence | Đọc sai câu | what time is it | 34.4 | 17.7 | 75 | 75 | nhiều lỗi | ≤ 40 | ✅ |
| silence | Im lặng | (rỗng) | 0 | 0 | 0 | – | toàn bộ âm bị thiếu | 0 | ✅ |
| digits | ASR trả về chữ số | thank you for these 3 things | 98.5 | 100 | 100 | 100 | – ("3" → "three") | ≥ 90 | ✅ |

**Nhận xét**

- Giọng chuẩn (nam/nữ, Mỹ/Anh) đạt 99+, không có lỗi giả. Mọi ca có lỗi đều bị phát hiện đúng âm vị và có điểm thấp hơn giọng chuẩn cùng câu.
- Lỗi thay âm gần (θ→s, ʃ→s) được tính "gần đúng" (vẫn được một phần điểm), lỗi xa hơn (θ→t, ð→d) bị trừ nhiều hơn – nhờ chi phí thay thế theo đặc trưng ngữ âm.
- Hạn chế đã biết: bộ nhận dạng giọng nói có mô hình ngôn ngữ nên đôi khi **tự sửa** phát âm sai thành từ đúng (ví dụ nói "tink" vẫn ra "think"). Khi đó app dựa thêm vào độ tin cậy (confidence) của ASR và danh sách khả năng khác (N-best) để giảm điểm/cảnh báo.

## 3. Kế hoạch kiểm thử với người thật (trên điện thoại)

Thực hiện trên điện thoại Android thật, mỗi người tạo **một hồ sơ riêng** trong app (để kiểm tra luôn tính năng nhiều người dùng). Mỗi người đọc cùng 3 câu trong bài "Âm /θ/ và /ð/" và bài "Giao tiếp hằng ngày", rồi ghi điểm từ màn hình **Lịch sử**.

| # | Người thử | Giới tính / độ tuổi | Giọng | Môi trường | Câu | Điểm | AI phát hiện lỗi gì | Nhận xét (đúng/sai so với tai người nghe) |
|---|---|---|---|---|---|---|---|---|
| 1 | | | Bắc | Yên tĩnh | I think this is the third one. | | | |
| 2 | | | Trung | Yên tĩnh | I think this is the third one. | | | |
| 3 | | | Nam | Yên tĩnh | I think this is the third one. | | | |
| 4 | | | (người đọc tốt) | Yên tĩnh | Could you help me, please? | | | |
| 5 | | | bất kỳ | Ồn (quán cà phê) | Where is the nearest bus station? | | | |
| 6 | | | bất kỳ | Nói nhỏ / xa micro | Nice to meet you. | | | |

> Bảng trên để điền khi thử trên máy thật. Gợi ý thêm: so sánh điểm của cùng một người giữa lần 1 và lần thứ 5 (sau khi làm theo gợi ý) để đánh giá module phản hồi.

**Các mục cần kiểm tra thủ công**

- [ ] Lần đầu bấm micro: Android hỏi quyền ghi âm; từ chối → app báo lỗi rõ ràng, gợi ý bật Chế độ kiểm thử.
- [ ] Đổi giờ nhắc thành 1–2 phút sau giờ hiện tại → nhận được thông báo; nội dung có tên và số ngày streak.
- [ ] Đạt mục tiêu ngày → hôm đó không nhắc nữa (lịch dời sang hôm sau).
- [ ] Khởi động lại điện thoại → nhắc nhở vẫn hoạt động.
- [ ] Hai người dùng trên cùng máy → streak, lịch sử, thống kê không lẫn vào nhau.
- [ ] Tắt mạng: nhận dạng giọng nói vẫn chạy nếu máy đã tải gói ngôn ngữ tiếng Anh offline (tùy máy).

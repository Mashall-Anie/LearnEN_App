import '../utils/date_utils.dart';

class StreakInfo {
  const StreakInfo({required this.current, required this.longest, required this.practicedToday});

  static const empty = StreakInfo(current: 0, longest: 0, practicedToday: false);

  /// Số ngày luyện tập liên tiếp tính đến hôm nay (hoặc hôm qua nếu hôm nay chưa luyện).
  final int current;
  final int longest;
  final bool practicedToday;

  /// Chuỗi đang "có nguy cơ" mất: đã có chuỗi nhưng hôm nay chưa luyện.
  bool get atRisk => current > 0 && !practicedToday;
}

/// Tính chuỗi ngày luyện tập (streak) từ danh sách các ngày có luyện tập.
class StreakCalculator {
  static StreakInfo compute(Iterable<DateTime> practiceDays, DateTime today) {
    final days = practiceDays.map(dateKey).toSet();
    if (days.isEmpty) return StreakInfo.empty;

    final todayKey = dateKey(today);
    final practicedToday = days.contains(todayKey);

    // Chuỗi hiện tại: hôm nay chưa luyện thì chuỗi vẫn giữ nếu hôm qua có luyện.
    var cursor = practicedToday ? dayOnly(today) : addDays(today, -1);
    var current = 0;
    while (days.contains(dateKey(cursor))) {
      current++;
      cursor = addDays(cursor, -1);
    }

    // Chuỗi dài nhất.
    final sorted = days.map(parseDateKey).toList()..sort();
    var longest = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (dateKey(addDays(sorted[i - 1], 1)) == dateKey(sorted[i])) {
        run++;
      } else {
        run = 1;
      }
      if (run > longest) longest = run;
    }
    return StreakInfo(current: current, longest: longest < current ? current : longest, practicedToday: practicedToday);
  }
}

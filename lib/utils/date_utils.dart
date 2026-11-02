/// Khóa ngày dạng yyyy-MM-dd theo giờ địa phương.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDateKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Cộng/trừ ngày theo lịch (an toàn khi đổi giờ mùa hè).
DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

const _weekdayShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

String weekdayShort(DateTime d) => _weekdayShort[d.weekday - 1];

String formatDuration(int seconds) {
  if (seconds < 60) return '$seconds giây';
  final m = seconds ~/ 60;
  if (m < 60) return '$m phút';
  final h = m ~/ 60;
  final rest = m % 60;
  return rest == 0 ? '$h giờ' : '$h giờ $rest phút';
}

String formatDateTime(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Đo thời gian học "thực" trên màn hình luyện tập.
///
/// Thời gian chỉ được cộng giữa hai lần tương tác, mỗi khoảng tối đa
/// [maxIdleGap] – để máy để quên trên màn hình không bị tính là đang học.
/// Khi ứng dụng chạy nền thì tạm dừng.
class StudyTimer {
  StudyTimer({this.maxIdleGap = const Duration(minutes: 2), DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final Duration maxIdleGap;
  final DateTime Function() _clock;

  DateTime? _last;
  Duration _accumulated = Duration.zero;
  bool _paused = true;

  bool get isRunning => !_paused;

  void start() {
    _last = _clock();
    _paused = false;
  }

  /// Ghi nhận một tương tác (bấm nút, nói, xem kết quả...).
  void markActivity() {
    if (_paused || _last == null) return;
    final now = _clock();
    var gap = now.difference(_last!);
    if (gap.isNegative) gap = Duration.zero;
    _accumulated += gap > maxIdleGap ? maxIdleGap : gap;
    _last = now;
  }

  void pause() {
    markActivity();
    _paused = true;
  }

  void resume() {
    if (!_paused) return;
    start();
  }

  /// Lấy số giây (nguyên) đã tích lũy và giữ lại phần lẻ cho lần sau.
  int takeSeconds() {
    markActivity();
    final s = _accumulated.inSeconds;
    _accumulated -= Duration(seconds: s);
    return s;
  }
}

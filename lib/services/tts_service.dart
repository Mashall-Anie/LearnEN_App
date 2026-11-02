import 'package:flutter_tts/flutter_tts.dart';

/// Đọc mẫu câu tiếng Anh bằng Text-to-Speech của hệ điều hành.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    _ready = true;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      // Một số máy không có giọng en-US: dùng giọng mặc định.
    }
  }

  /// [rate] 0..1 (0,5 ≈ tốc độ bình thường trên Android).
  Future<void> speak(String text, {double rate = 0.45}) async {
    await _ensureReady();
    try {
      await _tts.stop();
      await _tts.setSpeechRate(rate.clamp(0.1, 1.0));
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

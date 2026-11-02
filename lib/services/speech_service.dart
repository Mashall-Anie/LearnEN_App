import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Kết quả thu âm + nhận dạng một lần nói.
class SpeechCapture {
  const SpeechCapture({
    required this.text,
    this.confidence,
    this.alternatives = const [],
    this.speechDuration,
    required this.isFinal,
  });

  final String text;

  /// Độ tin cậy 0..1 do mô hình nhận dạng trả về (null nếu nền tảng không hỗ trợ).
  final double? confidence;

  /// Các khả năng nhận dạng khác (N-best).
  final List<String> alternatives;

  /// Thời lượng nói ước tính: từ lúc có chữ đầu tiên tới lần cập nhật cuối.
  final Duration? speechDuration;
  final bool isFinal;
}

/// Bọc plugin speech_to_text (dùng dịch vụ nhận dạng giọng nói của Google
/// trên Android / Apple Speech trên iOS) để thu âm và nhận dạng tiếng Anh.
class SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;
  bool _available = false;
  String? _localeId;
  String? lastError;

  void Function(String status)? _onStatus;
  void Function(String error)? _onError;

  bool get isAvailable => _available;
  bool get isListening => _stt.isListening;

  Future<bool> init() async {
    if (_initialized) return _available;
    _initialized = true;
    try {
      _available = await _stt.initialize(
        onStatus: (s) => _onStatus?.call(s),
        onError: (SpeechRecognitionError e) {
          lastError = e.errorMsg;
          _onError?.call(e.errorMsg);
        },
      );
      if (_available) _localeId = await _pickEnglishLocale();
    } catch (e) {
      lastError = e.toString();
      _available = false;
    }
    return _available;
  }

  Future<String?> _pickEnglishLocale() async {
    final locales = await _stt.locales();
    String? norm(String id) => id.replaceAll('-', '_').toLowerCase();
    for (final pref in ['en_us', 'en_gb']) {
      for (final l in locales) {
        if (norm(l.localeId) == pref) return l.localeId;
      }
    }
    for (final l in locales) {
      if (norm(l.localeId)!.startsWith('en')) return l.localeId;
    }
    return 'en_US';
  }

  /// Bắt đầu nghe. [onResult] được gọi với kết quả tạm thời và kết quả cuối.
  /// [onDone] được gọi khi phiên nghe kết thúc (kể cả khi không nhận được gì).
  Future<void> start({
    required void Function(SpeechCapture capture) onResult,
    required void Function(SpeechCapture? last, String? error) onDone,
    void Function(double level)? onSoundLevel,
  }) async {
    if (!_available) {
      onDone(null, lastError ?? 'Thiết bị không hỗ trợ nhận dạng giọng nói');
      return;
    }
    DateTime? firstWordAt;
    DateTime? lastChangeAt;
    String lastText = '';
    SpeechCapture? last;
    var finished = false;

    void finish(String? error) {
      if (finished) return;
      finished = true;
      _onStatus = null;
      _onError = null;
      onDone(last, error);
    }

    _onStatus = (s) {
      if (s == SpeechToText.doneStatus || s == SpeechToText.notListeningStatus) {
        // Chờ một nhịp để kết quả cuối (nếu có) đến trước.
        Future.delayed(const Duration(milliseconds: 400), () => finish(null));
      }
    };
    _onError = (e) => finish(e);
    lastError = null;

    await _stt.listen(
      onResult: (SpeechRecognitionResult r) {
        final now = DateTime.now();
        final text = r.recognizedWords;
        if (text.isNotEmpty) {
          firstWordAt ??= now;
          if (text != lastText) {
            lastText = text;
            lastChangeAt = now;
          }
        }
        final duration = firstWordAt == null
            ? null
            : lastChangeAt!.difference(firstWordAt!) + const Duration(milliseconds: 500);
        final top = r.alternates.isNotEmpty ? r.alternates.first : null;
        last = SpeechCapture(
          text: text,
          confidence: (top != null && top.hasConfidenceRating && top.confidence > 0) ? top.confidence : null,
          alternatives: r.alternates.skip(1).map((a) => a.recognizedWords).toList(),
          speechDuration: duration,
          isFinal: r.finalResult,
        );
        onResult(last!);
        if (r.finalResult) finish(null);
      },
      onSoundLevelChange: onSoundLevel,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        localeId: _localeId,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> stop() => _stt.stop();

  Future<void> cancel() => _stt.cancel();
}

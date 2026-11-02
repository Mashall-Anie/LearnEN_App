/// Bộ ca kiểm thử mô phỏng nhiều kiểu giọng / người nói khác nhau.
/// Dùng chung cho unit test (test/accent_simulation_test.dart) và màn hình
/// "Phòng kiểm thử AI" trong ứng dụng.
///
/// Mỗi ca mô phỏng kết quả mà bộ nhận dạng giọng nói trả về khi một kiểu
/// người nói đọc câu mẫu (transcript + độ tin cậy + thời lượng nói).
library;

class AccentTestCase {
  const AccentTestCase({
    required this.id,
    required this.speaker,
    required this.description,
    required this.target,
    required this.transcript,
    this.confidence,
    this.durationMs,
    required this.minScore,
    required this.maxScore,
    this.expectedErrorPhonemes = const [],
  });

  final String id;

  /// Kiểu người nói (giọng bản ngữ, giọng Việt, trẻ em...).
  final String speaker;
  final String description;
  final String target;
  final String transcript;
  final double? confidence;
  final int? durationMs;

  /// Khoảng điểm tổng kỳ vọng.
  final double minScore;
  final double maxScore;

  /// Các âm vị (ARPAbet) mà AI phải phát hiện là sai.
  final List<String> expectedErrorPhonemes;

  Duration? get duration => durationMs == null ? null : Duration(milliseconds: durationMs!);
}

const List<AccentTestCase> kAccentTestCases = [
  AccentTestCase(
    id: 'native-th',
    speaker: 'Người bản ngữ (Mỹ)',
    description: 'Đọc chuẩn, tốc độ tự nhiên.',
    target: 'I think this is the third one.',
    transcript: 'I think this is the third one',
    confidence: 0.95,
    durationMs: 2300,
    minScore: 90,
    maxScore: 100,
  ),
  AccentTestCase(
    id: 'vn-th',
    speaker: 'Người Việt – mới học',
    description: 'Đọc /θ/ thành /s/, /t/ và /ð/ thành "đ".',
    target: 'I think this is the third one.',
    transcript: 'I sink dis is de tird one',
    confidence: 0.62,
    durationMs: 3200,
    minScore: 40,
    maxScore: 80,
    expectedErrorPhonemes: ['TH', 'DH'],
  ),
  AccentTestCase(
    id: 'vn-final',
    speaker: 'Người Việt – nuốt âm cuối',
    description: 'Bỏ âm cuối -ed và -s.',
    target: 'He asked for six desks.',
    transcript: 'he ask for six desk',
    confidence: 0.8,
    durationMs: 2400,
    minScore: 55,
    maxScore: 90,
    expectedErrorPhonemes: ['T', 'S'],
  ),
  AccentTestCase(
    id: 'rl-confusion',
    speaker: 'Người học châu Á – nhầm R/L',
    description: 'Đọc /r/ thành /l/.',
    target: 'The red lorry rolled down the road.',
    transcript: 'the led lorry lolled down the load',
    confidence: 0.7,
    durationMs: 3000,
    minScore: 45,
    maxScore: 85,
    expectedErrorPhonemes: ['R'],
  ),
  AccentTestCase(
    id: 'vowel-length',
    speaker: 'Người Việt – nhầm nguyên âm dài/ngắn',
    description: 'Đảo /ɪ/ và /iː/.',
    target: 'Please sit in this seat.',
    transcript: 'please seat in this sit',
    confidence: 0.75,
    durationMs: 2200,
    minScore: 50,
    maxScore: 88,
    expectedErrorPhonemes: ['IH', 'IY'],
  ),
  AccentTestCase(
    id: 'sh-s',
    speaker: 'Người Việt miền Nam',
    description: 'Đọc /ʃ/ thành /s/.',
    target: 'She sells sea shells.',
    transcript: 'see sells sea sells',
    confidence: 0.7,
    durationMs: 2000,
    minScore: 50,
    maxScore: 88,
    expectedErrorPhonemes: ['SH'],
  ),
  AccentTestCase(
    id: 'v-w',
    speaker: 'Người học – nhầm V/W/B',
    description: 'Đọc /v/ thành /b/ và /w/.',
    target: 'We have very fine weather.',
    transcript: 'we have berry fine wetter',
    confidence: 0.7,
    durationMs: 2400,
    minScore: 45,
    maxScore: 88,
    expectedErrorPhonemes: ['V', 'DH'],
  ),
  AccentTestCase(
    id: 'female-native',
    speaker: 'Giọng nữ bản ngữ (Anh)',
    description: 'Câu giao tiếp, đọc chuẩn.',
    target: 'Could you help me, please?',
    transcript: 'could you help me please',
    confidence: 0.93,
    durationMs: 1800,
    minScore: 90,
    maxScore: 100,
  ),
  AccentTestCase(
    id: 'child-slow',
    speaker: 'Trẻ em – nói rất chậm',
    description: 'Đúng âm nhưng ngắt quãng, tốc độ chậm.',
    target: 'Where is the nearest bus station?',
    transcript: 'where is the nearest bus station',
    confidence: 0.85,
    durationMs: 9000,
    minScore: 75,
    maxScore: 95,
  ),
  AccentTestCase(
    id: 'quiet-partial',
    speaker: 'Nói nhỏ / môi trường ồn',
    description: 'AI chỉ nghe được nửa câu.',
    target: 'Where is the nearest bus station?',
    transcript: 'where is the',
    confidence: 0.5,
    durationMs: 1200,
    minScore: 0,
    maxScore: 60,
  ),
  AccentTestCase(
    id: 'wrong-sentence',
    speaker: 'Đọc sai câu',
    description: 'Nói một câu hoàn toàn khác.',
    target: 'Have a nice weekend!',
    transcript: 'what time is it',
    confidence: 0.9,
    durationMs: 1500,
    minScore: 0,
    maxScore: 40,
  ),
  AccentTestCase(
    id: 'silence',
    speaker: 'Im lặng',
    description: 'Không nói gì / micro bị tắt.',
    target: 'Nice to meet you.',
    transcript: '',
    minScore: 0,
    maxScore: 0,
  ),
  AccentTestCase(
    id: 'digits',
    speaker: 'AI trả về chữ số',
    description: 'Bộ nhận dạng ghi "3" thay cho "three".',
    target: 'Thank you for these three things.',
    transcript: 'thank you for these 3 things',
    confidence: 0.9,
    durationMs: 2200,
    minScore: 90,
    maxScore: 100,
  ),
];

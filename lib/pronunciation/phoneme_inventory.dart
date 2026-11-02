/// Bảng âm vị tiếng Anh (ký hiệu ARPAbet giống CMU Pronouncing Dictionary)
/// kèm đặc trưng ngữ âm để tính độ "gần" giữa hai âm, phiên âm IPA
/// và mẹo phát âm dành cho người Việt.
library;

enum PhonemeKind { vowel, consonant }

/// Phương thức cấu âm của phụ âm.
enum Manner { stop, affricate, fricative, nasal, lateral, rhotic, glide }

class PhonemeInfo {
  const PhonemeInfo.consonant({
    required this.symbol,
    required this.ipa,
    required this.example,
    required this.tip,
    required this.place,
    required Manner this.manner,
    required this.voiced,
    this.minimalPairs = const [],
  })  : kind = PhonemeKind.consonant,
        height = 0,
        backness = 0,
        rounded = false,
        long = false,
        diphthong = false,
        rhotic = false;

  const PhonemeInfo.vowel({
    required this.symbol,
    required this.ipa,
    required this.example,
    required this.tip,
    required this.height,
    required this.backness,
    this.rounded = false,
    this.long = false,
    this.diphthong = false,
    this.rhotic = false,
    this.minimalPairs = const [],
  })  : kind = PhonemeKind.vowel,
        place = 0,
        manner = null,
        voiced = true;

  final String symbol;
  final String ipa;
  final PhonemeKind kind;

  /// Từ ví dụ chứa âm này.
  final String example;

  /// Hướng dẫn khẩu hình (tiếng Việt).
  final String tip;

  /// Các cặp từ tối thiểu (minimal pairs) để luyện phân biệt: [từ chứa âm, từ đối chiếu].
  final List<List<String>> minimalPairs;

  // Đặc trưng phụ âm.
  /// Vị trí cấu âm: 0 môi-môi, 1 môi-răng, 2 răng, 3 lợi, 4 sau lợi, 5 ngạc cứng, 6 ngạc mềm, 7 thanh hầu.
  final double place;
  final Manner? manner;
  final bool voiced;

  // Đặc trưng nguyên âm.
  /// Độ mở: 0 đóng (cao) .. 3 mở (thấp).
  final double height;

  /// Vị trí lưỡi: 0 trước .. 2 sau.
  final double backness;
  final bool rounded;
  final bool long;
  final bool diphthong;
  final bool rhotic;

  bool get isVowel => kind == PhonemeKind.vowel;
  bool get isConsonant => kind == PhonemeKind.consonant;
}

const Map<String, PhonemeInfo> kPhonemes = {
  // ---------- Phụ âm ----------
  'P': PhonemeInfo.consonant(
    symbol: 'P', ipa: 'p', example: 'pen', place: 0, manner: Manner.stop, voiced: false,
    tip: 'Mím hai môi rồi bật hơi mạnh (đặt tờ giấy trước miệng sẽ thấy giấy rung). Ở cuối từ như "stop" vẫn phải khép môi rõ.',
    minimalPairs: [['pen', 'ben'], ['pat', 'bat'], ['cap', 'cab']],
  ),
  'B': PhonemeInfo.consonant(
    symbol: 'B', ipa: 'b', example: 'bad', place: 0, manner: Manner.stop, voiced: true,
    tip: 'Mím hai môi, rung dây thanh và bật nhẹ – không bật hơi mạnh như /p/.',
    minimalPairs: [['bat', 'pat'], ['bin', 'pin'], ['cab', 'cap']],
  ),
  'T': PhonemeInfo.consonant(
    symbol: 'T', ipa: 't', example: 'ten', place: 3, manner: Manner.stop, voiced: false,
    tip: 'Đầu lưỡi chạm lợi trên (sau răng cửa) rồi bật hơi. /t/ tiếng Anh bật hơi mạnh hơn chữ "t" tiếng Việt; ở cuối từ phải dừng lưỡi rõ ràng.',
    minimalPairs: [['ten', 'den'], ['tree', 'three'], ['bet', 'bed']],
  ),
  'D': PhonemeInfo.consonant(
    symbol: 'D', ipa: 'd', example: 'day', place: 3, manner: Manner.stop, voiced: true,
    tip: 'Đầu lưỡi chạm lợi trên và rung dây thanh. Khác chữ "đ" tiếng Việt: lưỡi đặt ở lợi chứ không ở răng.',
    minimalPairs: [['day', 'they'], ['den', 'then'], ['bed', 'bet']],
  ),
  'K': PhonemeInfo.consonant(
    symbol: 'K', ipa: 'k', example: 'cat', place: 6, manner: Manner.stop, voiced: false,
    tip: 'Cuống lưỡi chạm ngạc mềm rồi bật hơi. Ở cuối từ (book, desk) phải phát âm rõ, đừng nuốt âm.',
    minimalPairs: [['back', 'bag'], ['coat', 'goat']],
  ),
  'G': PhonemeInfo.consonant(
    symbol: 'G', ipa: 'ɡ', example: 'go', place: 6, manner: Manner.stop, voiced: true,
    tip: 'Cuống lưỡi chạm ngạc mềm và rung dây thanh.',
    minimalPairs: [['bag', 'back'], ['goat', 'coat']],
  ),
  'CH': PhonemeInfo.consonant(
    symbol: 'CH', ipa: 'tʃ', example: 'chair', place: 4, manner: Manner.affricate, voiced: false,
    tip: 'Bắt đầu như /t/ rồi xả nhanh sang /ʃ/, môi hơi tròn và đưa ra trước. Không đọc như "ch" tiếng Việt.',
    minimalPairs: [['chair', 'share'], ['cheap', 'sheep'], ['watch', 'wash']],
  ),
  'JH': PhonemeInfo.consonant(
    symbol: 'JH', ipa: 'dʒ', example: 'job', place: 4, manner: Manner.affricate, voiced: true,
    tip: 'Giống /tʃ/ nhưng rung dây thanh. Tránh đọc thành "gi" hoặc /z/ của tiếng Việt.',
    minimalPairs: [['jet', 'yet'], ['jeep', 'cheap'], ['gin', 'chin']],
  ),
  'F': PhonemeInfo.consonant(
    symbol: 'F', ipa: 'f', example: 'fine', place: 1, manner: Manner.fricative, voiced: false,
    tip: 'Răng trên chạm nhẹ môi dưới, thổi hơi liên tục.',
    minimalPairs: [['fine', 'vine'], ['fan', 'van'], ['free', 'three']],
  ),
  'V': PhonemeInfo.consonant(
    symbol: 'V', ipa: 'v', example: 'very', place: 1, manner: Manner.fricative, voiced: true,
    tip: 'Răng trên chạm môi dưới và rung dây thanh. Đừng đọc thành /b/ hay /w/; ở cuối từ (live, have) vẫn giữ âm /v/.',
    minimalPairs: [['very', 'berry'], ['vine', 'wine'], ['vest', 'west']],
  ),
  'TH': PhonemeInfo.consonant(
    symbol: 'TH', ipa: 'θ', example: 'think', place: 2, manner: Manner.fricative, voiced: false,
    tip: 'Đặt đầu lưỡi giữa hai hàm răng (thè nhẹ ra), thổi hơi qua khe lưỡi – răng, không rung dây thanh. Người Việt hay đọc nhầm thành /t/ hoặc /s/.',
    minimalPairs: [['think', 'sink'], ['three', 'tree'], ['thick', 'tick'], ['bath', 'bat']],
  ),
  'DH': PhonemeInfo.consonant(
    symbol: 'DH', ipa: 'ð', example: 'this', place: 2, manner: Manner.fricative, voiced: true,
    tip: 'Đặt đầu lưỡi giữa hai hàm răng như /θ/ nhưng rung dây thanh (sờ cổ thấy rung). Tránh đọc thành "đ" hoặc /z/.',
    minimalPairs: [['they', 'day'], ['then', 'den'], ['though', 'dough']],
  ),
  'S': PhonemeInfo.consonant(
    symbol: 'S', ipa: 's', example: 'see', place: 3, manner: Manner.fricative, voiced: false,
    tip: 'Đầu lưỡi gần lợi trên, hai hàm răng gần khép, môi dẹt, thổi hơi tạo tiếng "xì". Đuôi số nhiều (cats, books) phải nghe rõ /s/.',
    minimalPairs: [['see', 'she'], ['sip', 'ship'], ['sink', 'think']],
  ),
  'Z': PhonemeInfo.consonant(
    symbol: 'Z', ipa: 'z', example: 'zoo', place: 3, manner: Manner.fricative, voiced: true,
    tip: 'Giống /s/ nhưng rung dây thanh như tiếng ong "zzz". Đuôi -s sau âm hữu thanh (dogs, plays) đọc là /z/.',
    minimalPairs: [['zoo', 'sue'], ['eyes', 'ice'], ['prize', 'price']],
  ),
  'SH': PhonemeInfo.consonant(
    symbol: 'SH', ipa: 'ʃ', example: 'she', place: 4, manner: Manner.fricative, voiced: false,
    tip: 'Tròn môi đẩy ra trước, lưỡi lùi về sau hơn /s/, thổi hơi như tiếng "suỵt". Đừng đọc thành /s/.',
    minimalPairs: [['she', 'see'], ['ship', 'sip'], ['shoe', 'sue']],
  ),
  'ZH': PhonemeInfo.consonant(
    symbol: 'ZH', ipa: 'ʒ', example: 'measure', place: 4, manner: Manner.fricative, voiced: true,
    tip: 'Khẩu hình như /ʃ/ (môi tròn, lưỡi lùi) nhưng rung dây thanh. Gặp trong measure, usually, pleasure.',
    minimalPairs: [['measure', 'pleasure'], ['usually', 'measure']],
  ),
  'HH': PhonemeInfo.consonant(
    symbol: 'HH', ipa: 'h', example: 'hat', place: 7, manner: Manner.fricative, voiced: false,
    tip: 'Thở một luồng hơi nhẹ từ họng, không cọ xát mạnh như "h" tiếng Việt.',
    minimalPairs: [['hat', 'at'], ['heat', 'eat'], ['hair', 'air']],
  ),
  'M': PhonemeInfo.consonant(
    symbol: 'M', ipa: 'm', example: 'man', place: 0, manner: Manner.nasal, voiced: true,
    tip: 'Mím môi, để hơi đi qua mũi. Ở cuối từ phải khép môi lại.',
    minimalPairs: [['some', 'sun'], ['mice', 'nice']],
  ),
  'N': PhonemeInfo.consonant(
    symbol: 'N', ipa: 'n', example: 'no', place: 3, manner: Manner.nasal, voiced: true,
    tip: 'Đầu lưỡi chạm lợi trên, hơi đi qua mũi. Ở cuối từ (fine, ten) giữ lưỡi ở lợi, đừng chuyển thành "ng".',
    minimalPairs: [['sin', 'sing'], ['thin', 'thing'], ['ran', 'rang']],
  ),
  'NG': PhonemeInfo.consonant(
    symbol: 'NG', ipa: 'ŋ', example: 'sing', place: 6, manner: Manner.nasal, voiced: true,
    tip: 'Cuống lưỡi chạm ngạc mềm, hơi đi qua mũi. Không thêm /g/ ở cuối.',
    minimalPairs: [['sing', 'sin'], ['thing', 'thin'], ['rang', 'ran']],
  ),
  'L': PhonemeInfo.consonant(
    symbol: 'L', ipa: 'l', example: 'light', place: 3, manner: Manner.lateral, voiced: true,
    tip: 'Đầu lưỡi chạm lợi trên, hơi thoát ra hai bên lưỡi. Ở cuối từ (feel, school) là "L tối": cong lưỡi, đừng bỏ âm hay đọc thành /u/.',
    minimalPairs: [['light', 'right'], ['lead', 'read'], ['long', 'wrong']],
  ),
  'R': PhonemeInfo.consonant(
    symbol: 'R', ipa: 'r', example: 'red', place: 4, manner: Manner.rhotic, voiced: true,
    tip: 'Cong đầu lưỡi lên nhưng KHÔNG chạm vòm miệng, môi hơi tròn. Không rung lưỡi như "r" tiếng Việt, không đọc thành /z/ hay /l/.',
    minimalPairs: [['right', 'light'], ['red', 'led'], ['rice', 'lice']],
  ),
  'W': PhonemeInfo.consonant(
    symbol: 'W', ipa: 'w', example: 'we', place: 0, manner: Manner.glide, voiced: true,
    tip: 'Tròn môi nhỏ như sắp nói "u" rồi mở nhanh. Răng không chạm môi (khác /v/).',
    minimalPairs: [['wine', 'vine'], ['west', 'vest'], ['wet', 'vet']],
  ),
  'Y': PhonemeInfo.consonant(
    symbol: 'Y', ipa: 'j', example: 'yes', place: 5, manner: Manner.glide, voiced: true,
    tip: 'Nâng lưỡi về phía vòm như "i" rồi trượt nhanh sang nguyên âm phía sau.',
    minimalPairs: [['yet', 'jet'], ['year', 'ear']],
  ),

  // ---------- Nguyên âm ----------
  'IY': PhonemeInfo.vowel(
    symbol: 'IY', ipa: 'iː', example: 'see', height: 0, backness: 0, long: true,
    tip: 'Âm "i" dài: kéo môi sang hai bên như đang cười và giữ lâu hơn "i" tiếng Việt.',
    minimalPairs: [['sheep', 'ship'], ['seat', 'sit'], ['leave', 'live']],
  ),
  'IH': PhonemeInfo.vowel(
    symbol: 'IH', ipa: 'ɪ', example: 'sit', height: 0.8, backness: 0.4,
    tip: 'Âm "i" ngắn, thả lỏng: miệng mở hơn /iː/ một chút, nghe gần giữa "i" và "ê". Phát âm thật ngắn.',
    minimalPairs: [['ship', 'sheep'], ['sit', 'seat'], ['live', 'leave']],
  ),
  'EY': PhonemeInfo.vowel(
    symbol: 'EY', ipa: 'eɪ', example: 'day', height: 1, backness: 0, diphthong: true,
    tip: 'Bắt đầu từ "ê" rồi trượt sang "i" (gần giống "ây").',
    minimalPairs: [['late', 'let'], ['main', 'men']],
  ),
  'EH': PhonemeInfo.vowel(
    symbol: 'EH', ipa: 'e', example: 'bed', height: 1.6, backness: 0,
    tip: 'Âm "e" ngắn: miệng mở vừa phải, nằm giữa "ê" và "e" tiếng Việt.',
    minimalPairs: [['bed', 'bad'], ['men', 'man'], ['pen', 'pan']],
  ),
  'AE': PhonemeInfo.vowel(
    symbol: 'AE', ipa: 'æ', example: 'cat', height: 2.6, backness: 0.2,
    tip: 'Mở miệng rộng, hạ hàm dưới, kéo môi sang hai bên – âm nằm giữa "a" và "e". Đừng đọc thành "e" hay "a" tiếng Việt.',
    minimalPairs: [['bad', 'bed'], ['man', 'men'], ['cat', 'cut']],
  ),
  'AA': PhonemeInfo.vowel(
    symbol: 'AA', ipa: 'ɑː', example: 'father', height: 3, backness: 2, long: true,
    tip: 'Mở miệng thật rộng, lưỡi hạ thấp và lùi về sau – âm "a" dài.',
    minimalPairs: [['hot', 'hut'], ['lock', 'luck'], ['cart', 'cut']],
  ),
  'AO': PhonemeInfo.vowel(
    symbol: 'AO', ipa: 'ɔː', example: 'saw', height: 2, backness: 2, rounded: true, long: true,
    tip: 'Tròn môi, miệng mở vừa – giống "o" tiếng Việt nhưng kéo dài.',
    minimalPairs: [['walk', 'work'], ['law', 'low'], ['caught', 'coat']],
  ),
  'OW': PhonemeInfo.vowel(
    symbol: 'OW', ipa: 'oʊ', example: 'go', height: 1, backness: 2, rounded: true, diphthong: true,
    tip: 'Bắt đầu bằng "ô" rồi khép môi tròn trượt sang "u" (gần giống "âu").',
    minimalPairs: [['coat', 'caught'], ['low', 'law'], ['boat', 'bought']],
  ),
  'UH': PhonemeInfo.vowel(
    symbol: 'UH', ipa: 'ʊ', example: 'book', height: 0.8, backness: 1.6, rounded: true,
    tip: 'Âm "u" ngắn, môi tròn nhưng lỏng, phát âm nhanh.',
    minimalPairs: [['full', 'fool'], ['look', 'luke'], ['pull', 'pool']],
  ),
  'UW': PhonemeInfo.vowel(
    symbol: 'UW', ipa: 'uː', example: 'food', height: 0, backness: 2, rounded: true, long: true,
    tip: 'Âm "u" dài: chu môi tròn ra trước và giữ lâu.',
    minimalPairs: [['fool', 'full'], ['pool', 'pull']],
  ),
  'AH': PhonemeInfo.vowel(
    symbol: 'AH', ipa: 'ʌ', example: 'cup', height: 2, backness: 1,
    tip: 'Âm "ă" ngắn: miệng mở vừa, lưỡi ở giữa, phát âm dứt khoát.',
    minimalPairs: [['cup', 'cap'], ['hut', 'hot'], ['luck', 'lock']],
  ),
  'AX': PhonemeInfo.vowel(
    symbol: 'AX', ipa: 'ə', example: 'about', height: 1.5, backness: 1,
    tip: 'Âm "ơ" rất nhẹ và ngắn (schwa) ở âm tiết không nhấn – đọc lướt, đừng nhấn mạnh.',
  ),
  'ER': PhonemeInfo.vowel(
    symbol: 'ER', ipa: 'ɜːr', example: 'bird', height: 1.5, backness: 1, rhotic: true,
    tip: 'Giống "ơ" nhưng cong lưỡi lên (không chạm vòm miệng) và giữ âm /r/ nhẹ ở cuối.',
    minimalPairs: [['work', 'walk'], ['heard', 'hard'], ['bird', 'bud']],
  ),
  'AY': PhonemeInfo.vowel(
    symbol: 'AY', ipa: 'aɪ', example: 'my', height: 3, backness: 1, diphthong: true,
    tip: 'Bắt đầu bằng "a" rồi trượt sang "i" (giống "ai").',
    minimalPairs: [['like', 'lake'], ['rice', 'race']],
  ),
  'AW': PhonemeInfo.vowel(
    symbol: 'AW', ipa: 'aʊ', example: 'now', height: 3, backness: 1, diphthong: true,
    tip: 'Bắt đầu bằng "a" rồi tròn môi trượt sang "u" (giống "ao").',
    minimalPairs: [['now', 'no'], ['town', 'tone']],
  ),
  'OY': PhonemeInfo.vowel(
    symbol: 'OY', ipa: 'ɔɪ', example: 'boy', height: 2, backness: 2, rounded: true, diphthong: true,
    tip: 'Bắt đầu bằng "o" rồi trượt sang "i" (giống "oi").',
    minimalPairs: [['boy', 'buy'], ['toy', 'tie']],
  ),
};

PhonemeInfo? phonemeInfo(String symbol) => kPhonemes[symbol];

String ipaOf(String symbol) => kPhonemes[symbol]?.ipa ?? symbol.toLowerCase();

/// Chuỗi IPA cho một dãy âm vị, ví dụ [TH, IH, NG, K] → "θɪŋk".
String ipaOfSequence(Iterable<String> symbols) => symbols.map(ipaOf).join();

double _mannerDistance(Manner a, Manner b) {
  if (a == b) return 0;
  bool pair(Manner x, Manner y) => (a == x && b == y) || (a == y && b == x);
  if (pair(Manner.stop, Manner.affricate)) return 0.5;
  if (pair(Manner.affricate, Manner.fricative)) return 0.5;
  if (pair(Manner.lateral, Manner.rhotic)) return 0.5;
  if (pair(Manner.rhotic, Manner.glide)) return 0.5;
  if (pair(Manner.lateral, Manner.glide)) return 0.7;
  if (pair(Manner.nasal, Manner.stop)) return 0.8;
  return 1;
}

/// Chi phí thay thế âm [a] bằng âm [b] trong khoảng 0..1:
/// 0 = giống hệt, càng lớn thì hai âm càng khác xa về mặt cấu âm.
double substitutionCost(String a, String b) {
  if (a == b) return 0;
  // /ʌ/ và /ə/ chỉ khác nhau ở trọng âm – coi như tương đương.
  if ((a == 'AH' && b == 'AX') || (a == 'AX' && b == 'AH')) return 0;
  final pa = kPhonemes[a];
  final pb = kPhonemes[b];
  if (pa == null || pb == null) return 1;

  if (pa.isVowel != pb.isVowel) {
    // Bán nguyên âm gần với nguyên âm tương ứng.
    const near = {'W': 'UW', 'Y': 'IY', 'R': 'ER'};
    if (near[a] == b || near[b] == a) return 0.6;
    return 1;
  }

  double cost;
  if (pa.isVowel) {
    cost = 0.22 * (pa.height - pb.height).abs() + 0.22 * (pa.backness - pb.backness).abs();
    if (pa.rounded != pb.rounded) cost += 0.12;
    if (pa.long != pb.long) cost += 0.15;
    if (pa.diphthong != pb.diphthong) cost += 0.2;
    if (pa.rhotic != pb.rhotic) cost += 0.25;
  } else {
    final placeDistance = ((pa.place - pb.place).abs() / 3).clamp(0.0, 1.0);
    cost = 0.45 * placeDistance + 0.35 * _mannerDistance(pa.manner!, pb.manner!);
    if (pa.voiced != pb.voiced) cost += 0.2;
  }
  return cost.clamp(0.12, 1.0);
}

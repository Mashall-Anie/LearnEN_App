/// Giáo trình mặc định – được nạp vào bảng lessons / lesson_items khi tạo CSDL.
/// Mỗi bài tập trung vào nhóm âm người Việt hay phát âm sai.
library;

class LessonSeed {
  const LessonSeed({
    required this.id,
    required this.title,
    required this.description,
    required this.focusPhonemes,
    required this.level,
    required this.icon,
    required this.items,
  });

  final int id;
  final String title;
  final String description;

  /// Âm vị trọng tâm (ARPAbet).
  final List<String> focusPhonemes;
  final String level;
  final String icon;

  /// [câu tiếng Anh, nghĩa tiếng Việt]
  final List<List<String>> items;
}

class LessonIds {
  static const th = 1;
  static const shS = 2;
  static const longShortI = 3;
  static const finalSounds = 4;
  static const rl = 5;
  static const aeE = 6;
  static const vwf = 7;
  static const clusters = 8;
  static const affricates = 9;
  static const daily = 10;
}

const List<LessonSeed> kLessonCatalog = [
  LessonSeed(
    id: LessonIds.th,
    title: 'Âm /θ/ và /ð/ (TH)',
    description: 'Đặt lưỡi giữa hai răng – âm khó nhất với người Việt.',
    focusPhonemes: ['TH', 'DH'],
    level: 'Cơ bản',
    icon: '👅',
    items: [
      ['think', 'nghĩ'],
      ['three', 'số ba'],
      ['thank you', 'cảm ơn bạn'],
      ['birthday', 'sinh nhật'],
      ['mother', 'mẹ'],
      ['this', 'cái này'],
      ['weather', 'thời tiết'],
      ['I think this is the third one.', 'Tôi nghĩ đây là cái thứ ba.'],
      ['Thank you for these three things.', 'Cảm ơn bạn vì ba điều này.'],
    ],
  ),
  LessonSeed(
    id: LessonIds.shS,
    title: 'Âm /ʃ/ và /s/',
    description: 'Phân biệt "she" và "see": tròn môi hay môi dẹt.',
    focusPhonemes: ['SH', 'S'],
    level: 'Cơ bản',
    icon: '🤫',
    items: [
      ['she', 'cô ấy'],
      ['see', 'nhìn thấy'],
      ['ship', 'con tàu'],
      ['sip', 'nhấp một ngụm'],
      ['shoe', 'chiếc giày'],
      ['sure', 'chắc chắn'],
      ['Please wash the dishes.', 'Làm ơn rửa bát đĩa.'],
      ['She sells sea shells by the sea shore.', 'Cô ấy bán vỏ sò bên bờ biển.'],
    ],
  ),
  LessonSeed(
    id: LessonIds.longShortI,
    title: 'Nguyên âm dài /iː/ – ngắn /ɪ/',
    description: 'sheep hay ship? seat hay sit? Độ dài nguyên âm đổi nghĩa của từ.',
    focusPhonemes: ['IY', 'IH'],
    level: 'Cơ bản',
    icon: '⏱️',
    items: [
      ['sheep', 'con cừu'],
      ['ship', 'con tàu'],
      ['seat', 'chỗ ngồi'],
      ['sit', 'ngồi'],
      ['leave', 'rời đi'],
      ['live', 'sống'],
      ['Please sit in this seat.', 'Mời ngồi vào ghế này.'],
      ['We will leave the city.', 'Chúng tôi sẽ rời thành phố.'],
    ],
  ),
  LessonSeed(
    id: LessonIds.finalSounds,
    title: 'Âm cuối (ending sounds)',
    description: 'Không nuốt âm cuối: -s, -ed, /t/, /k/, /d/.',
    focusPhonemes: ['S', 'Z', 'T', 'D', 'K'],
    level: 'Trung bình',
    icon: '🔚',
    items: [
      ['cats', 'những con mèo'],
      ['books', 'những quyển sách'],
      ['desks', 'những cái bàn'],
      ['worked', 'đã làm việc'],
      ['played', 'đã chơi'],
      ['He asked for six desks.', 'Anh ấy xin sáu cái bàn.'],
      ['She looked at the old maps.', 'Cô ấy nhìn những tấm bản đồ cũ.'],
    ],
  ),
  LessonSeed(
    id: LessonIds.rl,
    title: 'Âm /r/ và /l/',
    description: 'right – light, red – led: cong lưỡi hay chạm lợi.',
    focusPhonemes: ['R', 'L'],
    level: 'Trung bình',
    icon: '🌀',
    items: [
      ['right', 'bên phải / đúng'],
      ['light', 'ánh sáng'],
      ['red', 'màu đỏ'],
      ['really', 'thật sự'],
      ['rice', 'cơm, gạo'],
      ['Please turn on the light.', 'Làm ơn bật đèn lên.'],
      ['The red lorry rolled down the road.', 'Chiếc xe tải đỏ lăn xuống đường.'],
    ],
  ),
  LessonSeed(
    id: LessonIds.aeE,
    title: 'Âm /æ/ và /e/',
    description: 'bad – bed, man – men: mở miệng rộng hay vừa.',
    focusPhonemes: ['AE', 'EH'],
    level: 'Cơ bản',
    icon: '😮',
    items: [
      ['bad', 'tồi, xấu'],
      ['bed', 'cái giường'],
      ['man', 'người đàn ông'],
      ['men', 'những người đàn ông'],
      ['apple', 'quả táo'],
      ['The black cat sat on the mat.', 'Con mèo đen ngồi trên tấm thảm.'],
      ['Can you pass me the black bag?', 'Bạn đưa tôi cái túi đen được không?'],
    ],
  ),
  LessonSeed(
    id: LessonIds.vwf,
    title: 'Âm /v/, /w/ và /f/',
    description: 'Răng chạm môi (v, f) hay tròn môi (w).',
    focusPhonemes: ['V', 'W', 'F'],
    level: 'Trung bình',
    icon: '🦷',
    items: [
      ['very', 'rất'],
      ['wine', 'rượu vang'],
      ['video', 'video'],
      ['fine', 'tốt, ổn'],
      ['We have very fine weather.', 'Thời tiết của chúng tôi rất đẹp.'],
      ['We visit the village every week.', 'Chúng tôi đến thăm ngôi làng mỗi tuần.'],
    ],
  ),
  LessonSeed(
    id: LessonIds.clusters,
    title: 'Cụm phụ âm (str, spr, spl)',
    description: 'Đọc liền nhiều phụ âm, không chèn "ơ" vào giữa.',
    focusPhonemes: ['S', 'T', 'R', 'P'],
    level: 'Nâng cao',
    icon: '🔗',
    items: [
      ['street', 'con đường'],
      ['spring', 'mùa xuân'],
      ['strong', 'mạnh mẽ'],
      ['splash', 'té nước'],
      ['The students stretch in the street.', 'Các sinh viên giãn cơ trên đường.'],
      ['Spring is a great time to travel.', 'Mùa xuân là thời điểm tuyệt vời để du lịch.'],
    ],
  ),
  LessonSeed(
    id: LessonIds.affricates,
    title: 'Âm /dʒ/, /tʃ/ và /ʒ/',
    description: 'job, church, measure – âm tắc xát và âm xát sau lợi.',
    focusPhonemes: ['JH', 'CH', 'ZH'],
    level: 'Nâng cao',
    icon: '🎺',
    items: [
      ['job', 'công việc'],
      ['church', 'nhà thờ'],
      ['chair', 'cái ghế'],
      ['measure', 'đo lường'],
      ['usually', 'thường xuyên'],
      ['Change the large orange jacket.', 'Hãy đổi chiếc áo khoác màu cam cỡ lớn.'],
      ['I usually watch the news at lunch.', 'Tôi thường xem tin tức vào bữa trưa.'],
    ],
  ),
  LessonSeed(
    id: LessonIds.daily,
    title: 'Giao tiếp hằng ngày',
    description: 'Các câu nói thông dụng – luyện ngữ điệu và độ trôi chảy.',
    focusPhonemes: [],
    level: 'Cơ bản',
    icon: '💬',
    items: [
      ['How are you today?', 'Hôm nay bạn thế nào?'],
      ['Nice to meet you.', 'Rất vui được gặp bạn.'],
      ['Could you help me, please?', 'Bạn có thể giúp tôi được không?'],
      ['What time is it now?', 'Bây giờ là mấy giờ?'],
      ['I would like a cup of coffee.', 'Tôi muốn một tách cà phê.'],
      ['Where is the nearest bus station?', 'Bến xe buýt gần nhất ở đâu?'],
      ['Have a nice weekend!', 'Cuối tuần vui vẻ nhé!'],
    ],
  ),
];

/// Bài học phù hợp để luyện một âm bị phát âm sai.
int? lessonIdForPhoneme(String phoneme, {bool finalSound = false}) {
  if (finalSound) return LessonIds.finalSounds;
  switch (phoneme) {
    case 'TH':
    case 'DH':
      return LessonIds.th;
    case 'SH':
    case 'S':
      return LessonIds.shS;
    case 'IY':
    case 'IH':
      return LessonIds.longShortI;
    case 'R':
    case 'L':
      return LessonIds.rl;
    case 'AE':
    case 'EH':
      return LessonIds.aeE;
    case 'V':
    case 'W':
    case 'F':
      return LessonIds.vwf;
    case 'JH':
    case 'CH':
    case 'ZH':
      return LessonIds.affricates;
    case 'Z':
    case 'T':
    case 'D':
    case 'K':
      return LessonIds.finalSounds;
  }
  return null;
}

LessonSeed? lessonSeedById(int id) {
  for (final l in kLessonCatalog) {
    if (l.id == id) return l;
  }
  return null;
}

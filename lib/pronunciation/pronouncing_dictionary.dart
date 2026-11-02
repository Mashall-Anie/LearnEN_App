/// Từ điển phiên âm (grapheme → phoneme) dùng để chuyển câu mẫu và câu
/// nhận dạng được thành dãy âm vị ARPAbet.
///
/// Thứ tự tra cứu: từ điển tích hợp → suy luận hình thái (-s, -ed, -ing...)
/// → quy tắc chính tả (letter-to-sound) cho từ chưa biết.
library;

import 'phoneme_inventory.dart';

enum PhonemeSource { dictionary, morphology, rules }

class WordToken {
  const WordToken(this.display, this.key);

  /// Từ để hiển thị (giữ chữ hoa).
  final String display;

  /// Khóa tra từ điển (chữ thường).
  final String key;

  @override
  String toString() => display;
}

class PronouncingDictionary {
  PronouncingDictionary._(this._entries);

  static final PronouncingDictionary instance = PronouncingDictionary._(_parse(_kDictionaryData));

  final Map<String, List<String>> _entries;

  int get size => _entries.length;

  bool contains(String word) => _entries.containsKey(word.toLowerCase());

  List<String> phonemesFor(String word) => lookup(word).$1;

  PhonemeSource sourceOf(String word) => lookup(word).$2;

  (List<String>, PhonemeSource) lookup(String word) {
    final w = word.toLowerCase();
    final direct = _entries[w];
    if (direct != null) return (direct, PhonemeSource.dictionary);
    final morph = _morphological(w);
    if (morph != null) return (morph, PhonemeSource.morphology);
    return (LetterToSound.convert(w), PhonemeSource.rules);
  }

  /// Phiên âm IPA cho cả câu, ví dụ "Thank you" → "/θæŋk juː/".
  String ipaFor(String text) {
    final words = tokenize(text).map((t) => ipaOfSequence(phonemesFor(t.key)));
    return '/${words.join(' ')}/';
  }

  // ---------------- Hình thái học ----------------

  List<String>? _base(String stem) => stem.isEmpty ? null : _entries[stem];

  List<String>? _morphological(String w) {
    if (w.endsWith("'s") && w.length > 2) {
      final base = _base(w.substring(0, w.length - 2)) ?? LetterToSound.convert(w.substring(0, w.length - 2));
      return _appendS(base);
    }
    if (w.endsWith("'re") && w.length > 3) {
      final base = _base(w.substring(0, w.length - 3));
      if (base != null) return [...base, 'ER'];
    }
    if (w.endsWith("'ll") && w.length > 3) {
      final base = _base(w.substring(0, w.length - 3));
      if (base != null) return [...base, 'L'];
    }
    if (w.endsWith("n't") && w.length > 3) {
      final base = _base(w.substring(0, w.length - 3));
      if (base != null) return [...base, 'AX', 'N', 'T'];
    }

    if (w.length > 3 && w.endsWith('ies')) {
      return _withSuffix(['${w.substring(0, w.length - 3)}y'], _appendS);
    }
    if (w.length > 3 && w.endsWith('es')) {
      final r = _withSuffix([w.substring(0, w.length - 2), w.substring(0, w.length - 1)], _appendS, requireDictionary: true);
      if (r != null) return r;
    }
    if (w.length > 2 && w.endsWith('s') && !w.endsWith('ss') && !w.endsWith('us') && !w.endsWith('is')) {
      return _withSuffix([w.substring(0, w.length - 1)], _appendS);
    }
    if (w.length > 4 && w.endsWith('ied')) {
      return _withSuffix(['${w.substring(0, w.length - 3)}y'], _appendEd);
    }
    if (w.length > 3 && w.endsWith('ed')) {
      final stem = w.substring(0, w.length - 2);
      return _withSuffix([stem, '${stem}e', if (_isDoubled(stem)) stem.substring(0, stem.length - 1)], _appendEd);
    }
    if (w.length > 4 && w.endsWith('ing')) {
      final stem = w.substring(0, w.length - 3);
      return _withSuffix(
        [stem, '${stem}e', if (_isDoubled(stem)) stem.substring(0, stem.length - 1)],
        (p) => [...p, 'IH', 'NG'],
      );
    }
    if (w.length > 4 && w.endsWith('ly')) {
      return _withSuffix([w.substring(0, w.length - 2)], (p) => [...p, 'L', 'IY'], requireDictionary: true);
    }
    if (w.length > 4 && w.endsWith('er')) {
      final stem = w.substring(0, w.length - 2);
      return _withSuffix([stem, '${stem}e', if (_isDoubled(stem)) stem.substring(0, stem.length - 1)], (p) => [...p, 'ER'],
          requireDictionary: true);
    }
    return null;
  }

  static bool _isDoubled(String s) =>
      s.length >= 2 && s[s.length - 1] == s[s.length - 2] && !'aeiou'.contains(s[s.length - 1]);

  /// Thử các gốc từ trong từ điển; nếu không có thì (tùy chọn) dùng quy tắc
  /// chính tả cho gốc đầu tiên rồi ghép hậu tố.
  List<String>? _withSuffix(List<String> stems, List<String> Function(List<String>) suffix,
      {bool requireDictionary = false}) {
    for (final s in stems) {
      final base = _base(s);
      if (base != null) return suffix(base);
    }
    if (requireDictionary || stems.first.length < 2) return null;
    return suffix(LetterToSound.convert(stems.first));
  }

  static List<String> _appendS(List<String> base) {
    if (base.isEmpty) return const ['S'];
    final last = base.last;
    if (const {'S', 'Z', 'SH', 'ZH', 'CH', 'JH'}.contains(last)) return [...base, 'IH', 'Z'];
    if (const {'P', 'T', 'K', 'F', 'TH'}.contains(last)) return [...base, 'S'];
    return [...base, 'Z'];
  }

  static List<String> _appendEd(List<String> base) {
    if (base.isEmpty) return const ['D'];
    final last = base.last;
    if (last == 'T' || last == 'D') return [...base, 'IH', 'D'];
    if (const {'P', 'K', 'F', 'S', 'SH', 'CH', 'TH'}.contains(last)) return [...base, 'T'];
    return [...base, 'D'];
  }

  static Map<String, List<String>> _parse(String data) {
    final map = <String, List<String>>{};
    for (final line in data.split('\n')) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 2 || parts.first.isEmpty) continue;
      map[parts.first] = parts.sublist(1);
    }
    return map;
  }
}

/// Tách câu thành từ: bỏ dấu câu, đổi chữ số thành chữ, giữ dấu nháy trong từ (I'm, don't).
List<WordToken> tokenize(String text) {
  var t = text.replaceAll(RegExp(r'[’‘`´]'), "'");
  t = t.replaceAllMapped(RegExp(r'\d+'), (m) {
    final n = int.tryParse(m[0]!);
    return n == null ? ' ' : ' ${numberToWords(n)} ';
  });
  t = t.replaceAll(RegExp(r"[^A-Za-z' ]"), ' ');
  final tokens = <WordToken>[];
  for (final raw in t.split(RegExp(r'\s+'))) {
    final w = raw.replaceAll(RegExp(r"^'+|'+$"), '');
    if (w.isEmpty) continue;
    final key = w.toLowerCase();
    tokens.add(WordToken(key == 'i' ? 'I' : w, key));
  }
  return tokens;
}

const _ones = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven',
  'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'];
const _tens = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];

/// Đổi số nguyên không âm (< 1 triệu) thành chữ tiếng Anh: 42 → "forty two".
String numberToWords(int n) {
  if (n < 0) return numberToWords(-n);
  if (n < 20) return _ones[n];
  if (n < 100) return n % 10 == 0 ? _tens[n ~/ 10] : '${_tens[n ~/ 10]} ${_ones[n % 10]}';
  if (n < 1000) {
    final rest = n % 100;
    return '${_ones[n ~/ 100]} hundred${rest == 0 ? '' : ' ${numberToWords(rest)}'}';
  }
  if (n < 1000000) {
    final rest = n % 1000;
    return '${numberToWords(n ~/ 1000)} thousand${rest == 0 ? '' : ' ${numberToWords(rest)}'}';
  }
  return n.toString().split('').map((d) => _ones[int.parse(d)]).join(' ');
}

/// Quy tắc chính tả → âm vị (ước lượng) cho các từ không có trong từ điển.
class LetterToSound {
  static const _vowelLetters = 'aeiou';
  static const _voicedEnd = {'B', 'D', 'G', 'V', 'DH', 'Z', 'ZH', 'JH', 'M', 'N', 'NG', 'L', 'R', 'W', 'Y'};

  static List<String> convert(String word) {
    final w = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (w.isEmpty) return const [];
    final out = <String>[];
    bool isV(int k) => k >= 0 && k < w.length && _vowelLetters.contains(w[k]);
    final n = w.length;
    // "Magic e": nguyên âm + 1 phụ âm + e cuối (make, time, home...).
    final magicE = n >= 3 && w[n - 1] == 'e' && !isV(n - 2) && isV(n - 3) && !(n >= 4 && isV(n - 4));

    var i = 0;
    void add(String p, int len) {
      for (final s in p.split(' ')) {
        if (s.isNotEmpty) out.add(s);
      }
      i += len;
    }

    while (i < n) {
      final c = w[i];
      final rest = w.substring(i);
      final next = i + 1 < n ? w[i + 1] : '';
      final afterNext = i + 2 < n ? w[i + 2] : '';
      final isLast = i == n - 1;

      // Phụ âm đôi (ll, tt, ss...) → đọc một lần.
      if (next == c && !isV(i) && c != 'e' && c != 'o') {
        i++;
        continue;
      }
      if (rest.startsWith('tch')) { add('CH', 3); continue; }
      if (rest.startsWith('dge')) { add('JH', 3); continue; }
      if (rest.startsWith('tion')) { add('SH AX N', 4); continue; }
      if (rest.startsWith('sion')) { add('ZH AX N', 4); continue; }
      if (rest.startsWith('ture')) { add('CH ER', 4); continue; }
      if (rest.startsWith('igh')) { add('AY', 3); continue; }
      if (rest.startsWith('ough') || rest.startsWith('augh')) { add('AO', 4); continue; }
      if (i == 0 && rest.startsWith('kn')) { add('N', 2); continue; }
      if (i == 0 && rest.startsWith('wr')) { add('R', 2); continue; }
      if (rest.startsWith('wh')) { add('W', 2); continue; }
      if (rest == 'mb') { add('M', 2); continue; }
      if (rest.startsWith('ph')) { add('F', 2); continue; }
      if (rest.startsWith('sh')) { add('SH', 2); continue; }
      if (rest.startsWith('ch')) { add('CH', 2); continue; }
      if (rest.startsWith('th')) { add('TH', 2); continue; }
      if (rest.startsWith('ck')) { add('K', 2); continue; }
      if (rest.startsWith('ng')) { add('NG', 2); continue; }
      if (rest.startsWith('nk')) { add('NG K', 2); continue; }
      if (rest.startsWith('qu')) { add('K W', 2); continue; }
      if (rest.startsWith('gh')) { add(i == 0 ? 'G' : '', 2); continue; }

      // Nguyên âm đôi.
      if (rest.startsWith('ee') || rest.startsWith('ea')) { add('IY', 2); continue; }
      if (rest.startsWith('oo')) { add('UW', 2); continue; }
      if (rest.startsWith('ou')) { add('AW', 2); continue; }
      if (rest.startsWith('ow') || rest.startsWith('oa')) { add('OW', 2); continue; }
      if (rest.startsWith('oi') || rest.startsWith('oy')) { add('OY', 2); continue; }
      if (rest.startsWith('ai') || rest.startsWith('ay') || rest.startsWith('ei')) { add('EY', 2); continue; }
      if (rest.startsWith('ey')) { add(i + 2 == n ? 'IY' : 'EY', 2); continue; }
      if (rest.startsWith('au') || rest.startsWith('aw')) { add('AO', 2); continue; }
      if (rest.startsWith('ue') || rest.startsWith('ew')) { add('UW', 2); continue; }
      if (rest.startsWith('ie')) { add(i + 2 == n && n <= 4 ? 'AY' : 'IY', 2); continue; }

      // Nguyên âm + r (không đứng trước nguyên âm).
      if (next == 'r' && !isV(i + 2) && afterNext != 'r') {
        if (c == 'a') { add('AA R', 2); continue; }
        if (c == 'o') { add('AO R', 2); continue; }
        if (c == 'e' || c == 'i' || c == 'u') { add('ER', 2); continue; }
      }

      // Đuôi "-le" sau phụ âm: apple, table.
      if (c == 'l' && rest == 'le' && i > 0 && !isV(i - 1)) { add('AX L', 2); continue; }

      switch (c) {
        case 'a':
        case 'e':
        case 'i':
        case 'o':
        case 'u':
          if (c == 'e' && isLast && n > 2) {
            i++; // e câm cuối từ
          } else if (c == 'e' && isLast) {
            add('IY', 1); // he, me, we, be
          } else if (c == 'o' && isLast) {
            add('OW', 1); // go, no, so
          } else if (magicE && i == n - 3) {
            add(const {'a': 'EY', 'e': 'IY', 'i': 'AY', 'o': 'OW', 'u': 'UW'}[c]!, 1);
          } else {
            add(const {'a': 'AE', 'e': 'EH', 'i': 'IH', 'o': 'AA', 'u': 'AH'}[c]!, 1);
          }
        case 'y':
          if (i == 0) {
            add('Y', 1);
          } else if (isLast) {
            add(n <= 3 ? 'AY' : 'IY', 1);
          } else {
            add('IH', 1);
          }
        case 'c':
          add('eiy'.contains(next) && next.isNotEmpty ? 'S' : 'K', 1);
        case 'g':
          add('eiy'.contains(next) && next.isNotEmpty ? 'JH' : 'G', 1);
        case 's':
          if (isLast && out.isNotEmpty && _voicedEnd.contains(out.last)) {
            add('Z', 1);
          } else if (isV(i - 1) && isV(i + 1)) {
            add('Z', 1);
          } else {
            add('S', 1);
          }
        case 'x':
          add(i == 0 ? 'Z' : 'K S', 1);
        case 'j':
          add('JH', 1);
        case 'h':
          add('HH', 1);
        case 'q':
          add('K', 1);
        default:
          add(c.toUpperCase(), 1);
      }
    }
    // Loại các phụ âm lặp liền nhau sinh ra do quy tắc.
    final result = <String>[];
    for (final p in out) {
      if (result.isNotEmpty && result.last == p && !(kPhonemes[p]?.isVowel ?? false)) continue;
      if (kPhonemes.containsKey(p)) result.add(p);
    }
    return result;
  }
}

/// Từ điển tích hợp (ARPAbet, bỏ dấu trọng âm; AX = schwa /ə/).
/// Gồm toàn bộ từ trong bài học, cặp từ tối thiểu và các từ thông dụng
/// mà bộ nhận dạng giọng nói hay trả về khi phát âm sai.
const String _kDictionaryData = '''
a AX
about AX B AW T
after AE F T ER
again AX G EH N
air EH R
all AO L
am AE M
an AE N
and AE N D
apple AE P AX L
are AA R
ask AE S K
at AE T
back B AE K
bad B AE D
bag B AE G
bat B AE T
bath B AE TH
be B IY
because B IH K AO Z
bed B EH D
been B IH N
beg B EH G
ben B EH N
berry B EH R IY
best B EH S T
bet B EH T
big B IH G
bin B IH N
bird B ER D
birth B ER TH
birthday B ER TH D EY
black B L AE K
boat B OW T
book B UH K
both B OW TH
bought B AO T
boy B OY
bread B R EH D
brother B R AH DH ER
bud B AH D
bus B AH S
but B AH T
buy B AY
by B AY
bye B AY
cab K AE B
can K AE N
can't K AE N T
cap K AE P
car K AA R
cart K AA R T
cat K AE T
caught K AO T
chair CH EH R
change CH EY N JH
cheap CH IY P
cheese CH IY Z
chin CH IH N
chip CH IH P
church CH ER CH
city S IH T IY
coat K OW T
coffee K AO F IY
come K AH M
cook K UH K
could K UH D
cup K AH P
cut K AH T
day D EY
den D EH N
desk D EH S K
did D IH D
dish D IH SH
do D UW
does D AH Z
dog D AO G
don't D OW N T
dough D OW
down D AW N
ear IH R
eat IY T
eight EY T
eighteen EY T IY N
eighty EY T IY
eleven IH L EH V AX N
english IH NG G L IH SH
every EH V R IY
excuse IH K S K Y UW Z
eyes AY Z
family F AE M AX L IY
fan F AE N
father F AA DH ER
feel F IY L
fifteen F IH F T IY N
fifty F IH F T IY
fill F IH L
fine F AY N
first F ER S T
fish F IH SH
five F AY V
food F UW D
fool F UW L
for F AO R
forty F AO R T IY
four F AO R
fourteen F AO R T IY N
free F R IY
fresh F R EH SH
friend F R EH N D
from F R AH M
full F UH L
get G EH T
gin JH IH N
go G OW
goat G OW T
good G UH D
great G R EY T
had HH AE D
hair HH EH R
happy HH AE P IY
hard HH AA R D
has HH AE Z
hat HH AE T
have HH AE V
he HH IY
heard HH ER D
heat HH IY T
hello HH AX L OW
help HH EH L P
her HH ER
here HH IH R
hi HH AY
his HH IH Z
hot HH AA T
hour AW ER
how HH AW
hundred HH AH N D R AX D
hut HH AH T
i AY
i'd AY D
i'll AY L
i'm AY M
ice AY S
in IH N
is IH Z
isn't IH Z AX N T
it IH T
it's IH T S
jacket JH AE K IH T
jeep JH IY P
jet JH EH T
job JH AA B
juice JH UW S
just JH AH S T
know N OW
lake L EY K
large L AA R JH
late L EY T
law L AO
lead L IY D
learn L ER N
leave L IY V
led L EH D
let L EH T
let's L EH T S
lice L AY S
light L AY T
like L AY K
live L IH V
lock L AA K
long L AO NG
look L UH K
lorry L AO R IY
love L AH V
low L OW
luck L AH K
luke L UW K
lunch L AH N CH
main M EY N
make M EY K
man M AE N
map M AE P
mat M AE T
math M AE TH
me M IY
measure M EH ZH ER
meat M IY T
meet M IY T
men M EH N
met M EH T
mice M AY S
month M AH N TH
morning M AO R N IH NG
mother M AH DH ER
mouse M AW S
mouth M AW TH
my M AY
name N EY M
near N IH R
nearest N IH R AX S T
need N IY D
news N UW Z
nice N AY S
night N AY T
nine N AY N
nineteen N AY N T IY N
ninety N AY N T IY
no N OW
north N AO R TH
not N AA T
now N AW
of AH V
old OW L D
on AA N
one W AH N
orange AO R IH N JH
other AH DH ER
our AW ER
out AW T
pan P AE N
pass P AE S
pat P AE T
path P AE TH
pen P EH N
pin P IH N
plate P L EY T
play P L EY
please P L IY Z
pleasure P L EH ZH ER
pool P UW L
practice P R AE K T IH S
price P R AY S
prize P R AY Z
pronunciation P R AX N AH N S IY EY SH AX N
pull P UH L
race R EY S
ran R AE N
rang R AE NG
read R IY D
really R IH L IY
red R EH D
rice R AY S
right R AY T
road R OW D
roll R OW L
room R UW M
rot R AA T
same S EY M
sat S AE T
saw S AO
say S EY
school S K UW L
sea S IY
seat S IY T
second S EH K AX N D
see S IY
sell S EH L
set S EH T
seven S EH V AX N
seventeen S EH V AX N T IY N
seventy S EH V AX N T IY
share SH EH R
she SH IY
she's SH IY Z
sheep SH IY P
shell SH EH L
ship SH IH P
shoe SH UW
shop SH AA P
shore SH AO R
should SH UH D
sick S IH K
sin S IH N
sing S IH NG
sink S IH NG K
sip S IH P
sit S IH T
six S IH K S
sixteen S IH K S T IY N
sixty S IH K S T IY
some S AH M
sore S AO R
sorry S AA R IY
south S AW TH
speak S P IY K
splash S P L AE SH
spread S P R EH D
spring S P R IH NG
station S T EY SH AX N
street S T R IY T
stretch S T R EH CH
strong S T R AO NG
student S T UW D AX N T
sue S UW
sum S AH M
sun S AH N
sure SH UH R
take T EY K
tank T AE NG K
tea T IY
teeth T IY TH
ten T EH N
than DH AE N
thank TH AE NG K
that DH AE T
the DH AX
their DH EH R
them DH EH M
then DH EH N
there DH EH R
these DH IY Z
they DH EY
thick TH IH K
thin TH IH N
thing TH IH NG
think TH IH NG K
third TH ER D
thirteen TH ER T IY N
thirty TH ER T IY
this DH IH S
those DH OW Z
though DH OW
thousand TH AW Z AX N D
three TH R IY
through TH R UW
tick T IH K
tie T AY
time T AY M
to T UW
today T AX D EY
together T AX G EH DH ER
tone T OW N
too T UW
town T AW N
toy T OY
travel T R AE V AX L
tree T R IY
turn T ER N
twelve T W EH L V
twenty T W EH N T IY
two T UW
up AH P
us AH S
usually Y UW ZH UW AX L IY
van V AE N
very V EH R IY
vest V EH S T
vet V EH T
video V IH D IY OW
village V IH L IH JH
vine V AY N
visit V IH Z IH T
walk W AO K
want W AA N T
was W AA Z
wash W AA SH
watch W AA CH
water W AO T ER
we W IY
weak W IY K
weather W EH DH ER
week W IY K
weekend W IY K EH N D
were W ER
west W EH S T
wet W EH T
what W AH T
what's W AH T S
when W EH N
where W EH R
whether W EH DH ER
which W IH CH
who HH UW
why W AY
will W IH L
wine W AY N
with W IH DH
won W AH N
wood W UH D
word W ER D
work W ER K
would W UH D
write R AY T
wrong R AO NG
year Y IH R
yes Y EH S
yet Y EH T
you Y UW
you're Y UH R
your Y AO R
zero Z IH R OW
zoo Z UW
''';

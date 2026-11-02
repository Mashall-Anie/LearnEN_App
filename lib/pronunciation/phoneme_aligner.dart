/// Căn chỉnh (alignment) hai dãy âm vị bằng thuật toán quy hoạch động
/// Needleman–Wunsch có trọng số: chi phí thay thế lấy từ đặc trưng ngữ âm
/// (âm càng gần nhau càng rẻ), thêm/bớt âm có chi phí cố định.
library;

import 'phoneme_inventory.dart';

enum AlignOp { match, substitution, deletion, insertion }

/// Một âm vị gắn với vị trí của nó trong câu.
class PhoneToken {
  const PhoneToken(this.symbol, this.wordIndex, this.positionInWord, this.wordLength);

  final String symbol;
  final int wordIndex;
  final int positionInWord;
  final int wordLength;

  bool get isWordFinal => positionInWord == wordLength - 1;

  @override
  String toString() => '$symbol@$wordIndex';
}

class AlignedPhone {
  const AlignedPhone(this.op, this.expected, this.actual, this.cost);

  final AlignOp op;

  /// Âm trong câu mẫu (null nếu là âm thừa – insertion).
  final PhoneToken? expected;

  /// Âm người dùng nói ra (null nếu bị bỏ sót – deletion).
  final PhoneToken? actual;
  final double cost;

  @override
  String toString() => '${op.name}(${expected?.symbol ?? '-'}→${actual?.symbol ?? '-'})';
}

class PhonemeAligner {
  const PhonemeAligner({this.gapCost = 1.0});

  final double gapCost;

  /// Chuyển danh sách từ (mỗi từ là một dãy âm vị) thành dãy [PhoneToken].
  static List<PhoneToken> flatten(List<List<String>> words) {
    final out = <PhoneToken>[];
    for (var w = 0; w < words.length; w++) {
      final phones = words[w];
      for (var p = 0; p < phones.length; p++) {
        out.add(PhoneToken(phones[p], w, p, phones.length));
      }
    }
    return out;
  }

  List<AlignedPhone> align(List<PhoneToken> expected, List<PhoneToken> actual) {
    final n = expected.length;
    final m = actual.length;
    final cols = m + 1;
    final dp = List<double>.filled((n + 1) * cols, 0);
    // 0 = chéo (khớp/thay thế), 1 = lên (xóa), 2 = trái (chèn)
    final back = List<int>.filled((n + 1) * cols, 0);

    for (var i = 1; i <= n; i++) {
      dp[i * cols] = i * gapCost;
      back[i * cols] = 1;
    }
    for (var j = 1; j <= m; j++) {
      dp[j] = j * gapCost;
      back[j] = 2;
    }

    const eps = 1e-9;
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        final diag = dp[(i - 1) * cols + j - 1] + substitutionCost(expected[i - 1].symbol, actual[j - 1].symbol);
        final up = dp[(i - 1) * cols + j] + gapCost;
        final left = dp[i * cols + j - 1] + gapCost;
        // Khi hòa điểm, ưu tiên "bỏ sót" để các âm khớp dồn về đầu câu
        // (câu nói dở thường bị thiếu phần cuối, không phải phần đầu).
        var best = up;
        var dir = 1;
        if (diag < best - eps) {
          best = diag;
          dir = 0;
        }
        if (left < best - eps) {
          best = left;
          dir = 2;
        }
        dp[i * cols + j] = best;
        back[i * cols + j] = dir;
      }
    }

    final result = <AlignedPhone>[];
    var i = n;
    var j = m;
    while (i > 0 || j > 0) {
      final dir = (i == 0) ? 2 : (j == 0 ? 1 : back[i * cols + j]);
      if (dir == 0) {
        final e = expected[i - 1];
        final a = actual[j - 1];
        final c = substitutionCost(e.symbol, a.symbol);
        result.add(AlignedPhone(c == 0 ? AlignOp.match : AlignOp.substitution, e, a, c));
        i--;
        j--;
      } else if (dir == 1) {
        result.add(AlignedPhone(AlignOp.deletion, expected[i - 1], null, gapCost));
        i--;
      } else {
        result.add(AlignedPhone(AlignOp.insertion, null, actual[j - 1], gapCost));
        j--;
      }
    }
    return result.reversed.toList();
  }
}

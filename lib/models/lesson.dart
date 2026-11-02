class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.focusPhonemes,
    required this.level,
    required this.icon,
    required this.sortOrder,
  });

  factory Lesson.fromMap(Map<String, Object?> m) => Lesson(
        id: m['id'] as int,
        title: m['title'] as String,
        description: m['description'] as String,
        focusPhonemes: (m['focus_phonemes'] as String).split(',').where((s) => s.isNotEmpty).toList(),
        level: m['level'] as String,
        icon: m['icon'] as String,
        sortOrder: m['sort_order'] as int,
      );

  final int id;
  final String title;
  final String description;
  final List<String> focusPhonemes;
  final String level;
  final String icon;
  final int sortOrder;
}

class LessonItem {
  const LessonItem({this.id, this.lessonId, required this.text, required this.meaning, this.sortOrder = 0});

  factory LessonItem.fromMap(Map<String, Object?> m) => LessonItem(
        id: m['id'] as int,
        lessonId: m['lesson_id'] as int,
        text: m['text'] as String,
        meaning: m['meaning'] as String,
        sortOrder: m['sort_order'] as int,
      );

  /// null với câu tự luyện (không thuộc bài học nào).
  final int? id;
  final int? lessonId;
  final String text;
  final String meaning;
  final int sortOrder;
}

/// Tiến độ của một người học trong một bài.
class LessonProgress {
  const LessonProgress({required this.lessonId, required this.itemCount, required this.practicedItems, this.bestAverage});

  final int lessonId;
  final int itemCount;

  /// Số câu đã luyện ít nhất một lần.
  final int practicedItems;

  /// Trung bình điểm cao nhất của từng câu đã luyện.
  final double? bestAverage;

  double get completion => itemCount == 0 ? 0 : practicedItems / itemCount;
}

class UserProfile {
  const UserProfile({
    this.id,
    required this.name,
    this.avatar = '🙂',
    this.dailyGoalMinutes = 10,
    this.reminderEnabled = true,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.speechRate = 0.45,
    this.testMode = false,
    required this.createdAt,
    this.lastActiveAt,
  });

  factory UserProfile.fromMap(Map<String, Object?> m) => UserProfile(
        id: m['id'] as int?,
        name: m['name'] as String,
        avatar: m['avatar'] as String,
        dailyGoalMinutes: m['daily_goal_minutes'] as int,
        reminderEnabled: (m['reminder_enabled'] as int) == 1,
        reminderHour: m['reminder_hour'] as int,
        reminderMinute: m['reminder_minute'] as int,
        speechRate: (m['speech_rate'] as num).toDouble(),
        testMode: (m['test_mode'] as int) == 1,
        createdAt: DateTime.parse(m['created_at'] as String),
        lastActiveAt: m['last_active_at'] == null ? null : DateTime.parse(m['last_active_at'] as String),
      );

  final int? id;
  final String name;
  final String avatar;

  /// Mục tiêu thời gian học mỗi ngày (phút).
  final int dailyGoalMinutes;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  /// Tốc độ đọc mẫu của TTS (0..1).
  final double speechRate;

  /// Chế độ kiểm thử: cho phép nhập văn bản thay cho giọng nói.
  final bool testMode;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'avatar': avatar,
        'daily_goal_minutes': dailyGoalMinutes,
        'reminder_enabled': reminderEnabled ? 1 : 0,
        'reminder_hour': reminderHour,
        'reminder_minute': reminderMinute,
        'speech_rate': speechRate,
        'test_mode': testMode ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'last_active_at': lastActiveAt?.toIso8601String(),
      };

  UserProfile copyWith({
    int? id,
    String? name,
    String? avatar,
    int? dailyGoalMinutes,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    double? speechRate,
    bool? testMode,
    DateTime? lastActiveAt,
  }) =>
      UserProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
        speechRate: speechRate ?? this.speechRate,
        testMode: testMode ?? this.testMode,
        createdAt: createdAt,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      );
}

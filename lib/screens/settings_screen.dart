import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/app_state.dart';
import 'accent_lab_screen.dart';
import 'profile_select_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser!;
    final theme = Theme.of(context);
    final time = TimeOfDay(hour: user.reminderHour, minute: user.reminderMinute);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ListTile(
            leading: CircleAvatar(radius: 24, child: Text(user.avatar, style: const TextStyle(fontSize: 24))),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('Tham gia từ ${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
            trailing: const Icon(Icons.edit),
            onTap: () => showCreateProfileDialog(context, editing: user),
          ),
          const Divider(),
          _Header('Mục tiêu & nhắc nhở'),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text('Mục tiêu mỗi ngày: ${user.dailyGoalMinutes} phút'),
            subtitle: Slider(
              value: user.dailyGoalMinutes.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              label: '${user.dailyGoalMinutes} phút',
              onChanged: (v) => state.updateUser(user.copyWith(dailyGoalMinutes: v.round())),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Nhắc nhở luyện tập hằng ngày'),
            subtitle: const Text('Tự bỏ qua hôm nay nếu bạn đã đạt mục tiêu'),
            value: user.reminderEnabled,
            onChanged: (v) async {
              if (v) await state.notifications.requestPermission();
              await state.updateUser(user.copyWith(reminderEnabled: v));
            },
          ),
          ListTile(
            enabled: user.reminderEnabled,
            leading: const Icon(Icons.schedule),
            title: const Text('Giờ nhắc'),
            trailing: Text(time.format(context), style: theme.textTheme.titleMedium),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: time);
              if (picked != null) {
                await state.updateUser(user.copyWith(reminderHour: picked.hour, reminderMinute: picked.minute));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.notification_add_outlined),
            title: const Text('Gửi thông báo thử'),
            onTap: () async {
              await state.notifications.requestPermission();
              await state.notifications.showTest(user, state.dashboard?.streak.current ?? 0);
            },
          ),
          const Divider(),
          _Header('Phát âm'),
          ListTile(
            leading: const Icon(Icons.record_voice_over_outlined),
            title: Text('Tốc độ đọc mẫu: ${(user.speechRate * 100).round()}%'),
            subtitle: Slider(
              value: user.speechRate,
              min: 0.2,
              max: 0.8,
              divisions: 12,
              onChanged: (v) => state.updateUser(user.copyWith(speechRate: v)),
              onChangeEnd: (v) => state.tts.speak('This is how I sound.', rate: v),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.keyboard_alt_outlined),
            title: const Text('Chế độ kiểm thử'),
            subtitle: const Text('Cho phép nhập văn bản mô phỏng thay cho giọng nói (dùng trên máy ảo / khi kiểm thử AI)'),
            value: user.testMode,
            onChanged: (v) => state.updateUser(user.copyWith(testMode: v)),
          ),
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('Phòng kiểm thử AI'),
            subtitle: const Text('Chạy bộ ca kiểm thử với nhiều kiểu giọng khác nhau'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AccentLabScreen())),
          ),
          const Divider(),
          _Header('Tài khoản'),
          ListTile(
            leading: const Icon(Icons.switch_account_outlined),
            title: const Text('Đổi người học'),
            onTap: state.logout,
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text('Xóa hồ sơ này', style: TextStyle(color: theme.colorScheme.error)),
            subtitle: const Text('Xóa toàn bộ lịch sử và tiến độ của người học này'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Xóa hồ sơ "${user.name}"?'),
                  content: const Text('Toàn bộ lịch sử luyện tập, streak và thống kê sẽ bị xóa vĩnh viễn.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
              if (ok == true) await state.deleteUser(user);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('LearnEN 1.0'),
            subtitle: Text('CSDL SQLite v${AppDatabase.version} · Từ điển ${state.scorer.dictionary.size} từ + quy tắc chính tả'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
    );
  }
}

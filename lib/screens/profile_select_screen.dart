import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../state/app_state.dart';

const kAvatars = ['🙂', '😎', '🦊', '🐼', '🐯', '🐸', '🦄', '🐧', '🌟', '🚀'];

/// Màn hình chọn người học – một thiết bị có thể có nhiều người dùng,
/// mỗi người có tiến độ, streak và lịch nhắc riêng.
class ProfileSelectScreen extends StatelessWidget {
  const ProfileSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 24),
            Text('🎙️', style: theme.textTheme.displayMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('LearnEN', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            Text('Luyện phát âm tiếng Anh với AI', style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Text(state.users.isEmpty ? 'Tạo hồ sơ để bắt đầu' : 'Ai đang học?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final u in state.users)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(radius: 24, child: Text(u.avatar, style: const TextStyle(fontSize: 24))),
                    title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Mục tiêu ${u.dailyGoalMinutes} phút/ngày'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.read<AppState>().selectUser(u),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => showCreateProfileDialog(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Thêm người học'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showCreateProfileDialog(BuildContext context, {UserProfile? editing}) async {
  final state = context.read<AppState>();
  final nameCtrl = TextEditingController(text: editing?.name ?? '');
  var avatar = editing?.avatar ?? kAvatars.first;
  var goal = editing?.dailyGoalMinutes ?? 10;
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(editing == null ? 'Người học mới' : 'Sửa hồ sơ'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  autofocus: editing == null,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Tên', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên người học' : null,
                ),
                const SizedBox(height: 16),
                const Text('Ảnh đại diện'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final a in kAvatars)
                      ChoiceChip(
                        label: Text(a, style: const TextStyle(fontSize: 20)),
                        selected: avatar == a,
                        onSelected: (_) => setState(() => avatar = a),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Mục tiêu mỗi ngày: $goal phút'),
                Slider(
                  value: goal.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  label: '$goal phút',
                  onChanged: (v) => setState(() => goal = v.round()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    ),
  );
  if (saved != true) return;
  if (editing == null) {
    final user = await state.createUser(name: nameCtrl.text, avatar: avatar, dailyGoalMinutes: goal);
    await state.selectUser(user);
  } else {
    await state.updateUser(editing.copyWith(name: nameCtrl.text.trim(), avatar: avatar, dailyGoalMinutes: goal));
  }
}

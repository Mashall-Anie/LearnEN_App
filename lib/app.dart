import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/profile_select_screen.dart';
import 'state/app_state.dart';

class LearnEnApp extends StatelessWidget {
  const LearnEnApp({super.key});

  static const seed = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    final user = context.select<AppState, int?>((s) => s.currentUser?.id);
    return MaterialApp(
      title: 'LearnEN – Phát âm AI',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: user == null ? const ProfileSelectScreen() : HomeShell(key: ValueKey(user)),
    );
  }

  ThemeData _theme(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}

/// Màu theo điểm số: đỏ → cam → xanh.
Color scoreColor(BuildContext context, double score) {
  if (score >= 85) return const Color(0xFF16A34A);
  if (score >= 60) return const Color(0xFFF59E0B);
  return Theme.of(context).colorScheme.error;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await AppDatabase.open();
  final notifications = NotificationService();
  await notifications.init();
  final appState = AppState(database: database, notifications: notifications);
  await appState.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const LearnEnApp(),
    ),
  );
}

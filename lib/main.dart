import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro_kanban/core/theme/theme_service.dart';
import 'package:pomodoro_kanban/core/theme/app_theme.dart';
import 'package:pomodoro_kanban/features/home/screens/home_screen.dart';
import 'package:pomodoro_kanban/features/kanban/providers/kanban_provider.dart';
import 'package:pomodoro_kanban/features/analytics/providers/analytics_provider.dart';
import 'package:pomodoro_kanban/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:pomodoro_kanban/features/sync/providers/sync_status_provider.dart';
import 'package:pomodoro_kanban/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Для веб
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  await NotificationService().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeService>(
          create: (_) => ThemeService(),
        ),
        ChangeNotifierProvider<SyncStatusProvider>(
          create: (_) => SyncStatusProvider(),
        ),
        ChangeNotifierProvider<KanbanProvider>(
          create: (context) => KanbanProvider(
            Provider.of<SyncStatusProvider>(context, listen: false)
          ),
        ),
        ChangeNotifierProvider<AnalyticsProvider>(
          create: (context) => AnalyticsProvider(
            Provider.of<KanbanProvider>(context, listen: false)
          ),
        ),
        ChangeNotifierProvider<PomodoroProvider>(
          create: (_) => PomodoroProvider(),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Pomodoro Kanban',
            theme: themeService.isDarkMode ? darkTheme : lightTheme,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro_kanban/core/theme/app_theme.dart';
import 'package:pomodoro_kanban/core/theme/theme_service.dart';
import 'package:pomodoro_kanban/features/home/screens/home_screen.dart';
import 'package:pomodoro_kanban/features/kanban/providers/kanban_provider.dart';
import 'package:pomodoro_kanban/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:pomodoro_kanban/features/analytics/providers/analytics_provider.dart';
import 'package:pomodoro_kanban/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:pomodoro_kanban/features/sync/providers/sync_status_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  
  // Инициализация базы данных для веб
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
    print('Инициализировано databaseFactoryFfiWeb для веб-платформы');
  }
  
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Caught error: ${details.exception}');
  };
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => SyncStatusProvider()),
        ChangeNotifierProvider<KanbanProvider>(
          create: (context) => KanbanProvider(
            Provider.of<SyncStatusProvider>(context, listen: false)
          ),
        ),
        ChangeNotifierProvider(create: (context) => AnalyticsProvider(
          Provider.of<KanbanProvider>(context, listen: false)
        )),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
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
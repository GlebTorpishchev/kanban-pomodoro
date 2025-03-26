import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro_kanban/core/theme/theme_service.dart';
import 'package:pomodoro_kanban/features/kanban/screens/kanban_screen.dart';
import 'package:pomodoro_kanban/features/pomodoro/screens/pomodoro_screen.dart';
import 'package:pomodoro_kanban/features/kanban/providers/kanban_provider.dart';
import 'package:pomodoro_kanban/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:pomodoro_kanban/features/analytics/screens/analytics_screen.dart';
import 'package:pomodoro_kanban/features/analytics/providers/analytics_provider.dart';
import 'package:pomodoro_kanban/features/sync/widgets/sync_status_indicator.dart';
import 'package:pomodoro_kanban/features/sync/providers/sync_status_provider.dart';
import 'package:pomodoro_kanban/features/home/widgets/animated_tab_view.dart';
import 'package:pomodoro_kanban/features/sync/widgets/sync_status_notifier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Kanban'),
        actions: [
          Consumer<SyncStatusProvider>(
            builder: (context, syncStatus, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: _getSyncIcon(syncStatus.status),
                    onPressed: syncStatus.status == SyncStatus.syncing
                        ? null
                        : () => context.read<KanbanProvider>().syncManually(),
                    tooltip: 'Синхронизировать',
                  ),
                  if (syncStatus.status == SyncStatus.error)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.error_outline, color: Colors.red, size: 16),
                    ),
                ],
              );
            },
          ),
          Consumer<ThemeService>(
            builder: (context, themeService, _) {
              return IconButton(
                icon: Icon(
                  themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () => themeService.toggleTheme(),
                tooltip: 'Сменить тему',
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          indicator: UnderlineTabIndicator(
            borderSide: const BorderSide(
              width: 3,
              color: Colors.white,
            ),
            insets: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
          tabs: const [
            Tab(text: 'Kanban'),
            Tab(text: 'Pomodoro'),
            Tab(text: 'Аналитика'),
          ],
        ),
      ),
      body: Stack(
        children: [
          AnimatedTabView(
            controller: _tabController,
            children: const [
              KanbanScreen(),
              PomodoroScreen(),
              AnalyticsScreen(),
            ],
          ),
          const SyncStatusNotifier(),
        ],
      ),
    );
  }

  Widget _getSyncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case SyncStatus.success:
        return const Icon(Icons.cloud_done, size: 20);
      case SyncStatus.error:
        return const Icon(Icons.cloud_off, color: Colors.red, size: 20);
      case SyncStatus.idle:
        return const Icon(Icons.cloud_upload, size: 20);
    }
  }
}
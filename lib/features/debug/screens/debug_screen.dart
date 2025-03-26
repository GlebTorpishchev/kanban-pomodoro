import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro_kanban/services/sync_service.dart';
import 'package:pomodoro_kanban/services/database_service.dart';
import 'package:pomodoro_kanban/services/firebase_service.dart';
import 'package:pomodoro_kanban/features/sync/providers/sync_status_provider.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Отладка')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _testFirebaseConnection(context),
              child: const Text('Проверить Firebase'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _testSQLite(context),
              child: const Text('Проверить SQLite'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _testSync(context),
              child: const Text('Проверить синхронизацию'),
            ),
          ],
        ),
      ),
    );
  }

  void _testFirebaseConnection(BuildContext context) {
    final syncService = SyncService(
      DatabaseService(),
      FirebaseService(),
      Provider.of<SyncStatusProvider>(context, listen: false),
    );
    syncService.testFirebaseConnection();
  }

  void _testSQLite(BuildContext context) {
    final syncService = SyncService(
      DatabaseService(),
      FirebaseService(),
      Provider.of<SyncStatusProvider>(context, listen: false),
    );
    syncService.testSQLite();
  }

  void _testSync(BuildContext context) {
    final syncService = SyncService(
      DatabaseService(),
      FirebaseService(),
      Provider.of<SyncStatusProvider>(context, listen: false),
    );
    syncService.testSync();
  }
} 
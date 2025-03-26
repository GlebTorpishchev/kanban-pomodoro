import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro_kanban/features/sync/providers/sync_status_provider.dart';
import 'package:pomodoro_kanban/features/kanban/providers/kanban_provider.dart';
import 'package:intl/intl.dart';

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncStatusProvider>(
      builder: (context, syncStatus, _) {
        return Tooltip(
          message: _getTooltipMessage(syncStatus),
          child: IconButton(
            icon: _getIcon(syncStatus.status),
            onPressed: syncStatus.status == SyncStatus.syncing
                ? null
                : () => context.read<KanbanProvider>().syncManually(),
          ),
        );
      },
    );
  }

  Widget _getIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.success:
        return const Icon(Icons.cloud_done, color: Colors.green);
      case SyncStatus.error:
        return const Icon(Icons.cloud_off, color: Colors.red);
      case SyncStatus.idle:
        return const Icon(Icons.cloud_upload);
      default:
        return const Icon(Icons.cloud_upload); // Default case
    }
  }

  String _getTooltipMessage(SyncStatusProvider syncStatus) {
    switch (syncStatus.status) {
      case SyncStatus.syncing:
        return 'Синхронизация...';
      case SyncStatus.success:
        return 'Синхронизировано';
      case SyncStatus.error:
        return 'Ошибка синхронизации';
      case SyncStatus.idle:
        return 'Нажмите для синхронизации';
      default:
        return 'Нажмите для синхронизации';
    }
  }
} 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_status_provider.dart';
import 'package:intl/intl.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncStatusProvider>(
      builder: (context, syncStatus, _) {
        return Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(syncStatus.status),
              const SizedBox(width: 8),
              _buildText(context, syncStatus),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green, size: 16);
      case SyncStatus.error:
        return const Icon(Icons.error, color: Colors.red, size: 16);
      case SyncStatus.idle:
        return const Icon(Icons.sync, color: Colors.grey, size: 16);
    }
  }

  Widget _buildText(BuildContext context, SyncStatusProvider syncStatus) {
    switch (syncStatus.status) {
      case SyncStatus.syncing:
        return const Text('Синхронизация...');
      case SyncStatus.success:
        final lastSync = syncStatus.lastSyncTime;
        final timeStr = lastSync != null
            ? DateFormat('HH:mm:ss').format(lastSync)
            : '';
        return Text('Синхронизировано в $timeStr');
      case SyncStatus.error:
        return Text('Ошибка: ${syncStatus.lastError}',
            style: const TextStyle(color: Colors.red));
      case SyncStatus.idle:
        return const Text('Ожидание синхронизации');
    }
  }
} 
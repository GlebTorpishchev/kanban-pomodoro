import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_status_provider.dart';

class SyncStatusNotifier extends StatelessWidget {
  const SyncStatusNotifier({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncStatusProvider>(
      builder: (context, provider, _) {
        // Use a post-frame callback to avoid showing multiple SnackBars
        // during the build phase
        if (provider.status == SyncStatus.syncing) {
          _showSnackBar(
            context, 
            'Синхронизация...', 
            Colors.blue,
            const Duration(seconds: 2),
          );
        } else if (provider.status == SyncStatus.success && 
                  provider.lastSyncTime != null) {
          _showSnackBar(
            context, 
            'Синхронизация завершена успешно', 
            Colors.green,
            const Duration(seconds: 2),
          );
        } else if (provider.status == SyncStatus.error && 
                  provider.lastError != null) {
          _showSnackBar(
            context, 
            'Ошибка: ${provider.lastError}', 
            Colors.red,
            const Duration(seconds: 3),
          );
        }
        
        // This widget doesn't render anything visible
        return const SizedBox.shrink();
      },
    );
  }
  
  void _showSnackBar(BuildContext context, String message, Color color, Duration duration) {
    // Use Future.microtask to avoid showing SnackBar during build
    Future.microtask(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: duration,
        ),
      );
    });
  }
} 
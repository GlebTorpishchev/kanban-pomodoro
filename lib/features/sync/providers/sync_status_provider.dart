import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncStatusProvider with ChangeNotifier {
  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;

  SyncStatus get status => _status;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;

  void setSyncing() {
    _status = SyncStatus.syncing;
    notifyListeners();
  }

  void setSuccess() {
    _status = SyncStatus.success;
    _lastSyncTime = DateTime.now();
    notifyListeners();
  }

  void setError(String error) {
    _status = SyncStatus.error;
    _lastError = error;
    notifyListeners();
  }

  void setIdle() {
    _status = SyncStatus.idle;
    notifyListeners();
  }
} 
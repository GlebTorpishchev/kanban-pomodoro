import 'package:pomodoro_kanban/data/models/task_model.dart';
import 'package:pomodoro_kanban/services/database_service.dart';
import 'package:pomodoro_kanban/services/firebase_service.dart';
import 'package:pomodoro_kanban/services/connectivity_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro_kanban/features/sync/providers/sync_status_provider.dart';
import 'dart:async';
import 'package:pomodoro_kanban/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  final DatabaseService _databaseService;
  final FirebaseService _firebaseService;
  final ConnectivityService _connectivityService;
  final SyncStatusProvider _syncStatus;
  final List<TaskModel> _pendingChanges = [];
  Timer? _autoSyncTimer;
  static const autoSyncInterval = Duration(minutes: 5); // Синхронизация каждые 5 минут

  SyncService(this._databaseService, this._firebaseService, this._syncStatus)
      : _connectivityService = ConnectivityService() {
    _setupConnectivityListener();
    _setupAutoSync();
  }

  void _setupConnectivityListener() {
    _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (isOnline && _pendingChanges.isNotEmpty) {
        syncPendingChanges();
      }
    });
  }

  void _setupAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(autoSyncInterval, (_) => syncData());
  }

  void dispose() {
    _autoSyncTimer?.cancel();
  }

  Future<void> syncData() async {
    try {
      _syncStatus.setSyncing();
      
      if (!await _connectivityService.checkConnectivity()) {
        _syncStatus.setError('Нет подключения к интернету');
        NotificationService().showSyncNotification(
          success: false,
          message: 'Нет подключения к интернету',
        );
        return;
      }

      final firebaseTasks = await _firebaseService.getTasks();
      final localTasks = await _databaseService.getTasks();
      final mergedTasks = _mergeTasks(localTasks, firebaseTasks);
      
      await _databaseService.saveAllTasks(mergedTasks);
      await _firebaseService.saveAllTasks(mergedTasks);
      
      await syncColumnSettings();
      
      _syncStatus.setSuccess();
      NotificationService().showSyncNotification(success: true);
    } catch (e) {
      _syncStatus.setError(e.toString());
      NotificationService().showSyncNotification(
        success: false,
        message: 'Ошибка: ${e.toString()}',
      );
    }
  }

  Future<void> addPendingChange(TaskModel task) async {
    _pendingChanges.add(task);
    await _databaseService.insertTask(task); // Сохраняем локально

    if (await _connectivityService.checkConnectivity()) {
      await syncPendingChanges();
    }
  }

  Future<void> syncPendingChanges() async {
    if (_pendingChanges.isEmpty) return;

    try {
      for (var task in _pendingChanges) {
        await _firebaseService.insertTask(task);
      }
      _pendingChanges.clear();
    } catch (e) {
      print('Ошибка синхронизации отложенных изменений: $e');
    }
  }

  List<TaskModel> _mergeTasks(List<TaskModel> local, List<TaskModel> firebase) {
    final Map<String, TaskModel> merged = {};
    
    // Добавляем задачи из Firebase
    for (var task in firebase) {
      merged[task.id] = task;
    }
    
    // Обновляем локальными задачами, если они новее
    for (var task in local) {
      final existing = merged[task.id];
      if (existing == null || task.createdAt.isAfter(existing.createdAt)) {
        merged[task.id] = task;
      }
    }
    
    return merged.values.toList();
  }
  
  // Синхронизация настроек колонок
  Future<void> syncColumnSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get column titles with default value if null
      final columnTitles = prefs.getStringList('columnTitles') ?? 
          ['Надо сделать', 'В процессе', 'Сделано'];
      
      // Get column colors with default value if null
      final colorStrings = prefs.getStringList('columnColors') ?? 
          [
            Colors.grey.shade200.value.toString(),
            Colors.grey.shade200.value.toString(),
            Colors.grey.shade200.value.toString(),
          ];

      // Create a properly structured map for Firebase
      final columnSettings = {
        'titles': columnTitles,
        'colors': colorStrings,
      };

      // Save to Firebase
      await _firebaseService.saveColumnSettings(columnSettings);

      // Save locally
      await prefs.setStringList('columnTitles', columnTitles);
      await prefs.setStringList('columnColors', colorStrings);
    } catch (e) {
      print('Ошибка синхронизации настроек колонок: $e');
      rethrow;
    }
  }

  void testFirebaseConnection() async {
    try {
      await Firebase.initializeApp();
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').add({'test': 'data'});
      print('Firebase работает корректно');
    } catch (e) {
      print('Ошибка подключения к Firebase: $e');
    }
  }

  void testSQLite() async {
    try {
      final db = await DatabaseService().database;
      await db.rawQuery('SELECT 1');
      print('SQLite работает корректно');
    } catch (e) {
      print('Ошибка работы с SQLite: $e');
    }
  }

  void testSync() async {
    final syncService = SyncService(DatabaseService(), FirebaseService(), SyncStatusProvider());
    
    // Создаем тестовую задачу
    final task = TaskModel(
      id: const Uuid().v4(),
      title: 'Тестовая задача',
      status: TaskStatus.todo,
      columnIndex: 0,
      createdAt: DateTime.now(),
      color: Colors.blue,
    );

    // Добавляем задачу в офлайн-режиме
    await syncService.addPendingChange(task);
    
    // Проверяем синхронизацию при восстановлении соединения
    await syncService.syncData();
  }
}

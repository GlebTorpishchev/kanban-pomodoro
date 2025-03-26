import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pomodoro_kanban/data/models/pomodoro_session_model.dart';
import 'package:pomodoro_kanban/services/database_service.dart';
import 'package:pomodoro_kanban/services/firebase_service.dart';
import 'package:pomodoro_kanban/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class PomodoroProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  // final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  int _workDuration = 25; // в минутах
  int _breakDuration = 5;
  int _remainingSeconds = 25 * 60;
  bool _isWorking = true;
  bool _isRunning = false;
  Timer? _timer;
  PomodoroSessionModel? _currentSession;

  int get workDuration => _workDuration;
  int get breakDuration => _breakDuration;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isWorking => _isWorking;

  void setWorkDuration(int minutes) {
    _workDuration = minutes;
    if (_isWorking) _remainingSeconds = minutes * 60;
    notifyListeners();
  }

  void setBreakDuration(int minutes) {
    _breakDuration = minutes;
    if (!_isWorking) _remainingSeconds = minutes * 60;
    notifyListeners();
  }

  void startTimer() {
    if (!_isRunning) {
      _isRunning = true;
      _currentSession = PomodoroSessionModel(
        id: const Uuid().v4(),
        startTime: DateTime.now(),
        workDuration: _workDuration,
        breakDuration: _breakDuration,
      );
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          notifyListeners();
        } else {
          _switchPhase();
        }
      });
      notifyListeners();
    }
  }

  void pauseTimer() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void resetTimer() {
    _isRunning = false;
    _timer?.cancel();
    _remainingSeconds = (_isWorking ? _workDuration : _breakDuration) * 60;
    notifyListeners();
  }

  void _switchPhase() async {
    if (_isWorking) {
      _isWorking = false;
      _remainingSeconds = _breakDuration * 60;
      _notificationService.showNotification('Break Time', 'Time to take a break!');
    } else {
      _isWorking = true;
      _remainingSeconds = _workDuration * 60;
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        isCompleted: true,
      );
      await _dbService.insertSession(_currentSession!);
      // await _firebaseService.saveSession(_currentSession!);
      _notificationService.showNotification('Work Time', 'Time to get back to work!');
    }
    notifyListeners();
  }
}
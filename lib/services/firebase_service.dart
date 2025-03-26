import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pomodoro_kanban/data/models/task_model.dart';
import 'package:pomodoro_kanban/data/models/pomodoro_session_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получение задач
  Stream<List<TaskModel>> getTasksStream() {
    return _firestore
        .collection('tasks')
        .orderBy('columnIndex')
        .orderBy('position')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получение задач (Future)
  Future<List<TaskModel>> getTasks() async {
    final snapshot = await _firestore
        .collection('tasks')
        .orderBy('columnIndex')
        .orderBy('position')
        .get();
    
    return snapshot.docs
        .map((doc) => TaskModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Добавление задачи
  Future<void> insertTask(TaskModel task) async {
    await _firestore.collection('tasks').doc(task.id).set(task.toMap());
  }

  // Обновление задачи
  Future<void> updateTask(TaskModel task) async {
    await _firestore.collection('tasks').doc(task.id).update(task.toMap());
  }

  // Удаление задачи
  Future<void> deleteTask(String id) async {
    await _firestore.collection('tasks').doc(id).delete();
  }

  // Сохранение всех задач
  Future<void> saveAllTasks(List<TaskModel> tasks) async {
    final batch = _firestore.batch();
    
    for (var task in tasks) {
      final docRef = _firestore.collection('tasks').doc(task.id);
      batch.set(docRef, task.toMap());
    }
    
    await batch.commit();
  }

  // Сохранение настроек колонок
  Future<void> saveColumnSettings(Map<String, dynamic> settings) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('settings').doc('columns');
      await docRef.set(settings);
    } catch (e) {
      print('Ошибка сохранения настроек колонок в Firebase: $e');
      rethrow;
    }
  }

  // Получение настроек колонок
  Future<Map<String, dynamic>?> getColumnSettings() async {
    try {
      final docRef = FirebaseFirestore.instance.collection('settings').doc('columns');
      final doc = await docRef.get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Ошибка получения настроек колонок из Firebase: $e');
      return null;
    }
  }

  // Работа с сессиями Помодоро
  Future<void> saveSession(PomodoroSessionModel session) async {
    await _firestore.collection('pomodoro_sessions').doc(session.id).set(session.toMap());
  }

  Stream<List<PomodoroSessionModel>> getSessions() {
    return _firestore.collection('pomodoro_sessions').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PomodoroSessionModel.fromMap(doc.data())).toList();
    });
  }
}
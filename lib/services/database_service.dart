import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'dart:html' if (dart.library.io) 'dart:io' as io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodoro_kanban/data/models/task_model.dart';
import 'package:pomodoro_kanban/data/models/pomodoro_session_model.dart';
import 'package:pomodoro_kanban/services/firebase_service.dart';


class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal() {
    print('DatabaseService._internal() инициализирован');
  }

  static Database? _database;
  final FirebaseService _firebaseService = FirebaseService();


  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kanban.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            status INTEGER NOT NULL,
            columnIndex INTEGER NOT NULL,
            deadline TEXT,
            createdAt TEXT NOT NULL,
            color INTEGER NOT NULL,
            position INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // Получение задач с упрощенной поддержкой web
  Future<List<TaskModel>> getTasks() async {
    try {
      if (kIsWeb) {
        // Для web используем Firebase напрямую
        return await _firebaseService.getTasks();
      } else {
        // Для мобильных используем SQLite
        final db = await database;
        final List<Map<String, dynamic>> maps = await db.query(
          'tasks',
          orderBy: 'columnIndex ASC, position ASC',
        );
        
        return List.generate(maps.length, (i) {
          return TaskModel.fromMap(maps[i]);
        });
      }
    } catch (e) {
      print('Ошибка получения задач: $e');
      return [];
    }
  }

  // Вставка задачи
  Future<void> insertTask(TaskModel task) async {
    try {
      if (kIsWeb) {
        // В web сохраняем напрямую в Firebase
        await _firebaseService.insertTask(task);
        print('Задача ${task.id} добавлена в Firebase');
      } else {
        // Для мобильных используем SQLite
        final db = await database;
        await db.insert(
          'tasks',
          task.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      print('Ошибка вставки задачи: $e');
    }
  }

  // Обновление задачи
  Future<void> updateTask(TaskModel task) async {
    try {
      if (kIsWeb) {
        // В web обновляем напрямую в Firebase
        await _firebaseService.updateTask(task);
        print('Задача ${task.id} обновлена в localStorage');
      } else {
        // Для мобильных используем SQLite
        final db = await database;
        await db.update(
          'tasks',
          task.toMap(),
          where: 'id = ?',
          whereArgs: [task.id],
        );
      }
    } catch (e) {
      print('Ошибка обновления задачи: $e');
    }
  }

  // Удаление задачи
  Future<void> deleteTask(String id) async {
    try {
      if (kIsWeb) {
        // В web удаляем напрямую из Firebase
        await _firebaseService.deleteTask(id);
        print('Задача $id удалена из Firebase');
      } else {
        // Для мобильных используем SQLite
        final db = await database;
        await db.delete(
          'tasks',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      print('Ошибка удаления задачи: $e');
    }
  }

  // Сохранение задачи в SharedPreferences (для web)
  Future<void> _saveTaskToSharedPrefs(TaskModel task) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Получаем текущий список задач
      final tasksJson = prefs.getStringList('localTasks') ?? [];
      
      // Ищем эту задачу в списке
      final taskIndex = tasksJson.indexWhere((json) {
        final existingTask = TaskModel.fromJson(json);
        return existingTask.id == task.id;
      });
      
      // Обновляем или добавляем задачу
      if (taskIndex != -1) {
        tasksJson[taskIndex] = task.toJson();
      } else {
        tasksJson.add(task.toJson());
      }
      
      // Сохраняем обновленный список
      await prefs.setStringList('localTasks', tasksJson);
    } catch (e) {
      print('Ошибка сохранения задачи в SharedPreferences: $e');
    }
  }

  // Удаление задачи из SharedPreferences (для web)
  Future<void> _deleteTaskFromSharedPrefs(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Получаем текущий список задач
      final tasksJson = prefs.getStringList('localTasks') ?? [];
      
      // Удаляем задачу из списка
      tasksJson.removeWhere((json) {
        final existingTask = TaskModel.fromJson(json);
        return existingTask.id == id;
      });
      
      // Сохраняем обновленный список
      await prefs.setStringList('localTasks', tasksJson);
    } catch (e) {
      print('Ошибка удаления задачи из SharedPreferences: $e');
    }
  }

  // Сохранение всех задач
  Future<void> saveAllTasks(List<TaskModel> tasks) async {
    if (kIsWeb) {
      // Для веб
      try {
        final tasksMap = tasks.map((task) => task.toMap()).toList();
        io.window.localStorage['tasks'] = jsonEncode(tasksMap);
      } catch (e) {
        print('Ошибка сохранения всех задач в localStorage: $e');
      }
    } else {
      // Для SQLite - транзакция для сохранения всех задач
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('tasks');
        for (var task in tasks) {
          await txn.insert('tasks', task.toMap());
        }
      });
    }

    // Для Firebase
    // final batch = _firestore?.batch();
    // await _firestore?.collection('tasks').get().then((snapshot) {
    //   for (var doc in snapshot.docs) {
    //     batch?.delete(doc.reference);
    //   }
    // });
    // for (var task in tasks) {
    //   final docRef = _firestore?.collection('tasks').doc(task.id);
    //   batch?.set(docRef!, task.toMap());
    // }
    // await batch?.commit();
  }

  // Аналогичные методы для Pomodoro сессий
  Future<void> insertSession(PomodoroSessionModel session) async {
    final db = await database;
    await db.insert('pomodoro_sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PomodoroSessionModel>> getSessions() async {
    final db = await database;
    final maps = await db.query('pomodoro_sessions');
    return maps.map((map) => PomodoroSessionModel.fromMap(map)).toList();
  }

  // Инициализация Firebase
  Future<void> initFirebase() async {
    // Раскомментируйте после добавления Firebase
    // await Firebase.initializeApp();
    // _firestore = FirebaseFirestore.instance;
  }

  Future<Map<String, dynamic>> getColumnSettings() async {
    if (kIsWeb) {
      try {
        final settingsJson = io.window.localStorage['columnSettings'] ?? '{}';
        return jsonDecode(settingsJson);
      } catch (e) {
        print('Ошибка получения настроек колонок из localStorage: $e');
        return {'titles': [], 'colors': []};
      }
    } else {
      final db = await database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS column_settings(
          id INTEGER PRIMARY KEY,
          titles TEXT NOT NULL,
          colors TEXT NOT NULL
        )
      ''');
      
      final List<Map<String, dynamic>> result = await db.query('column_settings');
      if (result.isEmpty) {
        return {'titles': [], 'colors': []};
      }
      return {
        'titles': jsonDecode(result.first['titles']),
        'colors': jsonDecode(result.first['colors']),
      };
    }
  }

  Future<void> saveColumnSettings(List<String> titles, List<int> colors) async {
    if (kIsWeb) {
      try {
        final settings = {
          'titles': titles,
          'colors': colors,
        };
        io.window.localStorage['columnSettings'] = jsonEncode(settings);
      } catch (e) {
        print('Ошибка сохранения настроек колонок в localStorage: $e');
      }
    } else {
      final db = await database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS column_settings(
          id INTEGER PRIMARY KEY,
          titles TEXT NOT NULL,
          colors TEXT NOT NULL
        )
      ''');
      
      await db.delete('column_settings');
      await db.insert('column_settings', {
        'titles': jsonEncode(titles),
        'colors': jsonEncode(colors),
      });
    }
  }

  // Добавьте в DatabaseService методы для работы с SharedPreferences в веб-контексте
  Future<void> saveToLocalStorage(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      } else {
        print('Неподдерживаемый тип для сохранения: ${value.runtimeType}');
      }
      print('Данные сохранены в localStorage: $key = $value');
    } catch (e) {
      print('Ошибка сохранения в localStorage: $e');
    }
  }

  Future<T?> loadFromLocalStorage<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(key)) {
        print('Ключ $key не найден в localStorage');
        return null;
      }
      
      if (T == bool) {
        return prefs.getBool(key) as T?;
      } else if (T == int) {
        return prefs.getInt(key) as T?;
      } else if (T == double) {
        return prefs.getDouble(key) as T?;
      } else if (T == String) {
        return prefs.getString(key) as T?;
      } else if (T == List<String>) {
        return prefs.getStringList(key) as T?;
      } else {
        print('Неподдерживаемый тип для загрузки: $T');
        return null;
      }
    } catch (e) {
      print('Ошибка загрузки из localStorage: $e');
      return null;
    }
  }
}
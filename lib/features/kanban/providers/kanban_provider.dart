import 'package:flutter/material.dart';
import 'package:pomodoro_kanban/data/models/task_model.dart';
import 'package:pomodoro_kanban/services/database_service.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodoro_kanban/services/firebase_service.dart';
import 'package:pomodoro_kanban/services/sync_service.dart';
import 'package:pomodoro_kanban/features/sync/providers/sync_status_provider.dart';

class KanbanProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseService _firebaseService = FirebaseService();
  late final SyncService _syncService;
  final SyncStatusProvider _syncStatus;
  List<TaskModel> _tasks = [];
  List<String> _columnTitles = ['Надо сделать', 'В процессе', 'Сделано'];
  List<Color> _columnColors = [
    Colors.grey.shade200,
    Colors.grey.shade200,
    Colors.grey.shade200,
  ];

  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  List<String> get columnTitles => List.unmodifiable(_columnTitles);
  List<Color> get columnColors => List.unmodifiable(_columnColors);

  KanbanProvider(this._syncStatus) {
    _syncService = SyncService(
      _dbService,
      _firebaseService,
      _syncStatus,
    );
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      print('Загрузка начальных данных...');
      // Загружаем локальные настройки колонок
      await _loadColumnSettings();
      
      // Загружаем задачи и обновляем UI
      await _loadTasks();
      notifyListeners();
      
      // Синхронизируем с Firebase в фоне
      Future.microtask(() async {
        try {
          await _syncService.syncData();
          await _loadTasks(); // Перезагружаем задачи после синхронизации
          notifyListeners();
        } catch (e) {
          print('Ошибка синхронизации с Firebase: $e');
        }
      });
    } catch (e) {
      print('Ошибка загрузки начальных данных: $e');
    }
  }

  Future<void> _loadColumnSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Загружаем названия колонок
      final savedTitles = prefs.getStringList('columnTitles');
      if (savedTitles != null && savedTitles.isNotEmpty) {
        _columnTitles = savedTitles;
        print('Загружены названия колонок: $_columnTitles');
      } else {
        // Сохраняем стандартные значения
        await prefs.setStringList('columnTitles', _columnTitles);
        print('Использованы стандартные названия колонок');
      }
      
      // Загружаем цвета колонок
      final colorStrings = prefs.getStringList('columnColors');
      if (colorStrings != null && colorStrings.isNotEmpty) {
        _columnColors = colorStrings.map((c) => Color(int.parse(c))).toList();
        print('Загружены цвета колонок');
      } else {
        // Сохраняем стандартные значения
        await prefs.setStringList('columnColors', 
          _columnColors.map((c) => c.value.toString()).toList());
        print('Использованы стандартные цвета колонок');
      }
    } catch (e) {
      print('Ошибка загрузки настроек колонок: $e');
    }
  }

  Future<void> _saveColumnSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('columnTitles', _columnTitles);
      await prefs.setStringList('columnColors', 
        _columnColors.map((c) => c.value.toString()).toList());
      print('Настройки колонок сохранены');
    } catch (e) {
      print('Ошибка сохранения настроек колонок: $e');
    }
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _dbService.getTasks();
      if (tasks.isNotEmpty) {
        _tasks = tasks;
        
        // Нормализуем позиции задач
        await _normalizeTaskPositions();
        
        print("Загружено задач: ${_tasks.length}");
      } else {
        print("Нет сохраненных задач");
        _tasks = [];
      }
    } catch (e) {
      print("Ошибка при загрузке задач: $e");
    }
  }

  Future<void> _normalizeTaskPositions() async {
    try {
      bool needsUpdate = false;
      
      // Для каждой колонки корректируем позиции
      for (int columnIndex = 0; columnIndex < _columnTitles.length; columnIndex++) {
        final columnTasks = _tasks
            .where((task) => task.columnIndex == columnIndex)
            .toList();
        
        // Сортируем по текущим позициям
        columnTasks.sort((a, b) => a.position.compareTo(b.position));
        
        // Обновляем позиции, чтобы они шли последовательно
        for (int i = 0; i < columnTasks.length; i++) {
          final task = columnTasks[i];
          if (task.position != i) {
            // Нашли несоответствие - требуется обновление
            needsUpdate = true;
            final index = _tasks.indexWhere((t) => t.id == task.id);
            if (index != -1) {
              final updatedTask = task.copyWith(position: i);
              _tasks[index] = updatedTask;
              await _dbService.updateTask(updatedTask);
              print('Нормализована позиция задачи ${task.id} с ${task.position} на $i');
            }
          }
        }
      }
      
      if (needsUpdate) {
        print('Позиции задач нормализованы');
      }
    } catch (e) {
      print('Ошибка при нормализации позиций задач: $e');
    }
  }

  Future<void> addTask(String title, {String? description, DateTime? deadline, Color? color, int columnIndex = 0}) async {
    final task = TaskModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      status: TaskStatus.todo,
      columnIndex: columnIndex,
      deadline: deadline,
      createdAt: DateTime.now(),
      color: color ?? Colors.blue,
    );
    
    _tasks.add(task);
    notifyListeners();
    
    await _dbService.insertTask(task);
  }

  Future<void> updateTask(TaskModel task) async {
      await _dbService.updateTask(task);
    await _firebaseService.updateTask(task); // Обновляем в Firebase
    await _loadTasks();
      notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks.removeAt(index);
      notifyListeners();
      
    await _dbService.deleteTask(id);
    }
  }

  List<TaskModel> getTasksByColumnIndex(int columnIndex) {
    final columnTasks = _tasks
        .where((task) => task.columnIndex == columnIndex)
        .toList();
    
    // Сортируем по позиции
    columnTasks.sort((a, b) => a.position.compareTo(b.position));
    return columnTasks;
  }

  Future<void> updateColumnTitle(int index, String newTitle) async {
    if (index >= 0 && index < _columnTitles.length) {
      print("Начало updateColumnTitle для колонки $index: ${_columnTitles[index]} -> $newTitle");
      
      // Сохраняем старое название на случай ошибки
      final oldTitle = _columnTitles[index];
      
      // Заменяем название
      _columnTitles[index] = newTitle;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // Проверяем содержимое списка перед сохранением
        print("Сохраняемые названия колонок: $_columnTitles");
        
        // Сохраняем в SharedPreferences
        final success = await prefs.setStringList('columnTitles', _columnTitles);
        
        if (success) {
          print("Успешно сохранено название колонки.");
          
          // Проверяем, что данные действительно сохранились
          final savedTitles = prefs.getStringList('columnTitles');
          print("Проверка сохраненных данных: $savedTitles");
        } else {
          print("ОШИБКА: Не удалось сохранить название колонки.");
          _columnTitles[index] = oldTitle;
          notifyListeners();
        }
      } catch (e) {
        print("ИСКЛЮЧЕНИЕ при сохранении названия колонки: $e");
        _columnTitles[index] = oldTitle;
        notifyListeners();
      }
    } else {
      print("ОШИБКА: Индекс $index вне диапазона ${_columnTitles.length}");
    }
  }

  void updateColumnColor(int index, Color newColor) {
    if (index >= 0 && index < _columnColors.length) {
      _columnColors[index] = newColor;
      _saveColumnSettings();
      notifyListeners();
    }
  }

  void addColumn() {
    final newIndex = _columnTitles.length;
    _columnTitles.add('Новая колонка ${newIndex + 1}');
    _columnColors.add(Colors.grey.shade200);
    _saveColumnSettings();
    notifyListeners();
  }

  Future<void> deleteColumn(int index) async {
    if (index >= 0 && index < _columnTitles.length) {
      // Удаляем сначала задачи этой колонки
      final tasksToDelete = _tasks.where((task) => task.columnIndex == index).toList();
      for (var task in tasksToDelete) {
        await _dbService.deleteTask(task.id);
      }

      // Удаляем колонку
      _columnTitles.removeAt(index);
      _columnColors.removeAt(index);
      
      // Обновляем индексы колонок для оставшихся задач
      for (var i = 0; i < _tasks.length; i++) {
        if (_tasks[i].columnIndex > index) {
          final updatedTask = _tasks[i].copyWith(columnIndex: _tasks[i].columnIndex - 1);
          _tasks[i] = updatedTask;
          await _dbService.updateTask(updatedTask);
        }
      }
      
      // Удаляем задачи из локального списка
      _tasks.removeWhere((task) => task.columnIndex == index);

      // Сохраняем изменения
      _saveColumnSettings();
      notifyListeners();
    }
  }

  Future<void> reorderColumns(int oldIndex, int newIndex) async {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

    if (oldIndex < 0 || oldIndex >= _columnTitles.length || 
        newIndex < 0 || newIndex >= _columnTitles.length) {
      return;
    }

      final title = _columnTitles.removeAt(oldIndex);
      _columnTitles.insert(newIndex, title);

      final color = _columnColors.removeAt(oldIndex);
      _columnColors.insert(newIndex, color);

    // Update task column indices
    _tasks = _tasks.map((task) {
        if (task.columnIndex == oldIndex) {
        return task.copyWith(columnIndex: newIndex);
        } else if (oldIndex < newIndex &&
            task.columnIndex > oldIndex &&
            task.columnIndex <= newIndex) {
        return task.copyWith(columnIndex: task.columnIndex - 1);
        } else if (oldIndex > newIndex &&
                 task.columnIndex < oldIndex && 
                 task.columnIndex >= newIndex) {
        return task.copyWith(columnIndex: task.columnIndex + 1);
      }
      return task;
    }).toList();
    
    await _saveColumnSettings();
    await _saveTasks();
    notifyListeners();
  }

  Future<void> moveTask(String taskId, int columnIndex) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index == -1) return;
      
      final task = _tasks[index];
      if (task.columnIndex == columnIndex) return;
      
      final oldColumnIndex = task.columnIndex;
      final oldPosition = task.position;
      
      // Получаем задачи в новой колонке
      final tasksInNewColumn = getTasksByColumnIndex(columnIndex);
      // Определяем новую позицию (в конце колонки)
      final position = tasksInNewColumn.isEmpty ? 0 : tasksInNewColumn.length;
      
      // Обновляем задачу
      final updatedTask = task.copyWith(
        columnIndex: columnIndex,
        position: position,
      );
      
      // Обновляем в памяти и сохраняем в БД
      _tasks[index] = updatedTask;
      await _dbService.updateTask(updatedTask);
      print('Задача ${task.id} перемещена из колонки $oldColumnIndex в колонку $columnIndex с позицией $position');
      
      // Вызываем обновление UI до запуска следующих операций
      notifyListeners();
      
      // Обновляем позиции в старой колонке (в фоне)
      Future.microtask(() async {
        await _updatePositionsAfterRemoval(oldColumnIndex, oldPosition);
        await _saveTasks(); // Сохраняем все задачи для надежности
      });
    } catch (e) {
      print('Ошибка при перемещении задачи: $e');
    }
  }
  
  Future<void> _updatePositionsAfterRemoval(int columnIndex, int removedPosition) async {
    try {
      // Получаем задачи, которые нужно обновить (после удаленной позиции)
      final tasksToUpdate = _tasks
          .where((t) => t.columnIndex == columnIndex && t.position > removedPosition)
          .toList();
      
      // Смещаем позиции
      for (var task in tasksToUpdate) {
        final newPosition = task.position - 1;
        final updatedTask = task.copyWith(position: newPosition);
        
        final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
        if (taskIndex != -1) {
          _tasks[taskIndex] = updatedTask;
          await _dbService.updateTask(updatedTask);
          print('Позиция задачи ${task.id} обновлена с ${task.position} на $newPosition');
        }
      }
    } catch (e) {
      print('Ошибка при обновлении позиций задач: $e');
    }
  }
  
  Future<void> reorderTasks(int columnIndex, int oldIndex, int newIndex) async {
    try {
      print('Перемещение задачи в колонке $columnIndex с позиции $oldIndex на позицию $newIndex');
      
      // Получаем задачи в колонке
      final columnTasks = getTasksByColumnIndex(columnIndex);
      
      if (oldIndex < 0 || oldIndex >= columnTasks.length || 
          newIndex < 0 || newIndex >= columnTasks.length) {
        print('Недопустимые индексы: oldIndex=$oldIndex, newIndex=$newIndex, размер=${columnTasks.length}');
        return;
      }
      
      // Для ReorderableListView.builder: если newIndex > oldIndex, его нужно уменьшить на 1
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      // Перемещаемая задача
      final movingTask = columnTasks[oldIndex];
      
      // Формируем обновленный список с новым порядком
      final reorderedTasks = List<TaskModel>.from(columnTasks);
      reorderedTasks.removeAt(oldIndex);
      reorderedTasks.insert(newIndex, movingTask);
      
      // Обновляем позиции всех задач в колонке
      for (int i = 0; i < reorderedTasks.length; i++) {
        final task = reorderedTasks[i];
        if (task.position != i) {
          // Создаем обновленную задачу с новой позицией
          final updatedTask = task.copyWith(position: i);
          // Обновляем в списке задач
          final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
          if (taskIndex != -1) {
            _tasks[taskIndex] = updatedTask;
            // Сохраняем в базе данных
            await _dbService.updateTask(updatedTask);
            print('Позиция задачи ${task.id} изменена с ${task.position} на $i');
          }
        }
      }
      
      // Вызываем обновление UI
      notifyListeners();
      
      // Дополнительно сохраняем все задачи
      print('Сохраняем все задачи после изменения порядка...');
      await _saveTasks();
    } catch (e) {
      print('Ошибка при изменении порядка задач: $e');
    }
  }
  
  Future<void> _saveTasks() async {
    try {
      print('Начало сохранения всех задач (${_tasks.length})...');
      
      for (var task in _tasks) {
        try {
          await _dbService.updateTask(task);
          print('Задача ${task.id} сохранена');
        } catch (e) {
          print('Ошибка при сохранении задачи ${task.id}: $e');
        }
      }
      
      print('Все задачи сохранены успешно: ${_tasks.length}');
    } catch (e) {
      print('Ошибка сохранения задач: $e');
    }
  }

  Future<void> addTestData() async {
    final now = DateTime.now();
    final tasks = [
      TaskModel(
        id: const Uuid().v4(),
        title: 'Тестовая задача 1',
        description: 'Описание задачи 1',
        status: TaskStatus.done,
        columnIndex: 2,
        deadline: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 30)),
        color: Colors.blue,
        position: 0,
      ),
      TaskModel(
        id: const Uuid().v4(),
        title: 'Тестовая задача 2',
        description: 'Описание задачи 2',
        status: TaskStatus.inProgress,
        columnIndex: 1,
        deadline: now.add(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 20)),
        color: Colors.green,
        position: 1,
      ),
      // Добавьте еще несколько задач с разными датами и статусами
    ];

    for (var task in tasks) {
      await _dbService.insertTask(task);
    }
    await _loadInitialData(); // Перезагружаем данные
    notifyListeners();
  }

  Future<void> syncManually() async {
    await _syncService.syncData();
    notifyListeners();
  }

  // Add this method to handle theme persistence
  Future<void> saveTheme(bool isDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', isDarkMode);
    } catch (e) {
      print('Ошибка сохранения темы: $e');
    }
  }

  // Добавьте этот метод для сохранения темы
  Future<void> saveThemePreference(bool isDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', isDarkMode);
      print('Тема сохранена: dark=${isDarkMode}');
    } catch (e) {
      print('Ошибка сохранения темы: $e');
    }
  }

  // Добавьте метод для загрузки сохраненной темы
  Future<bool?> loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isDarkMode');
    } catch (e) {
      print('Ошибка загрузки темы: $e');
      return null;
    }
  }
}
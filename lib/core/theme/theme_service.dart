import 'package:pomodoro_kanban/features/kanban/providers/kanban_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Добавляем объявление navigatorKey, если его нет
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ThemeService with ChangeNotifier {
  static const String _themeKey = 'isDarkMode'; // Единый стабильный ключ
  bool _isDarkMode = false;
  
  // Конструктор, который загружает сохраненные настройки
  ThemeService() {
    // Для синхронного конструктора сначала устанавливаем значение по умолчанию
    _loadSavedTheme();
  }
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  // Метод для переключения темы
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Обновляем UI немедленно
    _saveThemePreference(); // Асинхронно сохраняем изменения
  }
  
  // Метод для загрузки предпочтений темы
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeMode = prefs.getBool(_themeKey);
      
      if (themeMode != null) {
        _isDarkMode = themeMode;
        print('Загружена тема: dark=${_isDarkMode}');
        notifyListeners(); // Уведомляем слушателей о загрузке темы
      } else {
        // Если тема не найдена, сохраняем текущую (по умолчанию светлую)
        await prefs.setBool(_themeKey, _isDarkMode);
        print('Инициализирована тема по умолчанию: dark=${_isDarkMode}');
      }
    } catch (e) {
      print('Ошибка загрузки темы: $e');
    }
  }
  
  // Метод для сохранения предпочтений темы
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Удаляем старые значения для предотвращения конфликтов
      if (prefs.containsKey(_themeKey)) {
        await prefs.remove(_themeKey);
      }
      
      // Сохраняем новые настройки темы
      await prefs.setBool(_themeKey, _isDarkMode);
      print('Тема сохранена: dark=${_isDarkMode}');
    } catch (e) {
      print('Ошибка сохранения темы: $e');
    }
  }
  
  // Методы для получения цветов на основе текущей темы
  Color get backgroundColor => _isDarkMode ? Colors.grey[900]! : Colors.white;
  Color get textColor => _isDarkMode ? Colors.white : Colors.black;

  // В конструкторе или методе init добавьте загрузку темы
  Future<void> loadSavedTheme() async {
    final kanbanProvider = Provider.of<KanbanProvider>(navigatorKey.currentContext!, listen: false);
    final savedTheme = await kanbanProvider.loadThemePreference();
    if (savedTheme != null) {
      _isDarkMode = savedTheme;
      notifyListeners();
    }
  }
}
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import '../models/analytics_data.dart';
import '../../kanban/providers/kanban_provider.dart';
import 'package:pomodoro_kanban/data/models/task_model.dart';
import 'package:flutter/foundation.dart';

class AnalyticsProvider with ChangeNotifier {
  final KanbanProvider _kanbanProvider;
  List<TaskAnalytics> _taskAnalytics = [];
  
  AnalyticsProvider(this._kanbanProvider) {
    _loadAnalytics();
  }

  void _loadAnalytics() {
    final tasks = _kanbanProvider.tasks;
    
    // ТЕСТОВЫЕ ДАННЫЕ - УДАЛИТЬ В ПРОДАКШЕНЕ
    if (tasks.isEmpty) {
      final now = DateTime.now();
      _taskAnalytics = [
        TaskAnalytics(
          completedAt: now.subtract(const Duration(days: 30)),
          timeToComplete: const Duration(days: 5),
          columnName: 'Сделано',
          deadline: now,
          wasDeadlineMet: true,
        ),
        TaskAnalytics(
          completedAt: now.subtract(const Duration(days: 20)),
          timeToComplete: const Duration(days: 3),
          columnName: 'В процессе',
          deadline: now.add(const Duration(days: 2)),
          wasDeadlineMet: false,
        ),
        // Добавьте еще тестовых данных по желанию
      ];
      return;
    }
    
    // Обычная логика загрузки
    _taskAnalytics = tasks
        .where((task) => task.status == TaskStatus.done)
        .map((task) => TaskAnalytics(
              completedAt: task.createdAt,
              timeToComplete: task.deadline?.difference(task.createdAt) ?? Duration.zero,
              columnName: _kanbanProvider.columnTitles[task.columnIndex],
              deadline: task.deadline,
              wasDeadlineMet: task.deadline == null ? true : DateTime.now().isBefore(task.deadline!),
            ))
        .toList();
  }

  // Получение данных для графика прогнозирования
  LineChartData getPredictionData() {
    final spots = _taskAnalytics
        .mapIndexed((index, task) => FlSpot(
              index.toDouble(),
              task.timeToComplete.inDays.toDouble(),
            ))
        .toList();

    return LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(show: true),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: true),
        ),
      ],
    );
  }

  // Получение данных для круговой диаграммы распределения задач
  PieChartData getTaskDistributionData() {
    final distribution = groupBy(_taskAnalytics, (TaskAnalytics ta) => ta.columnName);
    final sections = distribution.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.length.toDouble(),
        title: '${entry.key}\n${entry.value.length}',
        radius: 100,
        color: Colors.primaries[distribution.keys.toList().indexOf(entry.key) % Colors.primaries.length],
      );
    }).toList();

    return PieChartData(sections: sections);
  }

  // Получение данных для столбчатой диаграммы времени выполнения
  BarChartData getCompletionTimeData() {
    // Группируем задачи по месяцам
    final monthlyData = groupBy(
      _taskAnalytics,
      (TaskAnalytics ta) => DateTime(ta.completedAt.year, ta.completedAt.month),
    );

    // Создаем данные для каждого месяца
    final List<BarChartGroupData> barGroups = monthlyData.entries
        .mapIndexed((index, entry) {
          final avgTime = entry.value
              .map((ta) => ta.timeToComplete.inDays)
              .reduce((a, b) => a + b) /
              entry.value.length;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                fromY: 0,
                toY: avgTime,
                color: Colors.blue,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            showingTooltipIndicators: [0],
          );
        })
        .toList();

    return BarChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final date = monthlyData.keys.elementAt(value.toInt());
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${date.month}/${date.year}',
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()} дн.',
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: true),
      barGroups: barGroups,
    );
  }

  // Добавим метод для получения подробной статистики по колонкам
  List<ColumnAnalytics> getColumnStatistics() {
    final columnStats = <String, ColumnAnalytics>{};
    
    for (var task in _taskAnalytics) {
      final stats = columnStats[task.columnName] ?? ColumnAnalytics(
        name: task.columnName,
        taskCount: 0,
        averageTime: Duration.zero,
      );
      
      columnStats[task.columnName] = ColumnAnalytics(
        name: task.columnName,
        taskCount: stats.taskCount + 1,
        averageTime: Duration(days: (stats.averageTime.inDays * stats.taskCount + 
            task.timeToComplete.inDays) ~/ (stats.taskCount + 1)),
      );
    }
    
    return columnStats.values.toList();
  }

  // Улучшенный метод прогнозирования
  Duration predictCompletionTime(String title, String? description) {
    if (_taskAnalytics.isEmpty) return const Duration(days: 7);

    // Учитываем последние тенденции (последние 5 задач)
    final recentTasks = _taskAnalytics
        .sorted((a, b) => b.completedAt.compareTo(a.completedAt))
        .take(5);

    final recentAverage = recentTasks
        .map((ta) => ta.timeToComplete.inDays)
        .reduce((a, b) => a + b) /
        recentTasks.length;

    // Общее среднее время
    final totalAverage = _taskAnalytics
        .map((ta) => ta.timeToComplete.inDays)
        .reduce((a, b) => a + b) /
        _taskAnalytics.length;

    // Взвешенное среднее (отдаем предпочтение последним тенденциям)
    final weightedAverage = (recentAverage * 0.7 + totalAverage * 0.3);

    return Duration(days: weightedAverage.round());
  }

  // Расширенный метод генерации отчета
  Map<String, dynamic> generateReport() {
    if (_taskAnalytics.isEmpty) {
      return {
        'totalTasks': 0,
        'completedOnTime': 0,
        'completionRate': 0.0,
        'averageCompletionTime': 0,
        'trendingUp': false,
        'efficiency': 0.0,
      };
    }

    final totalTasks = _taskAnalytics.length;
    final tasksOnTime = _taskAnalytics.where((ta) => ta.wasDeadlineMet).length;
    
    // Расчет тренда эффективности
    final recentTasks = _taskAnalytics
        .sorted((a, b) => b.completedAt.compareTo(a.completedAt))
        .take(5);
    final oldTasks = _taskAnalytics
        .sorted((a, b) => b.completedAt.compareTo(a.completedAt))
        .skip(5)
        .take(5);

    final recentAvg = recentTasks
        .map((ta) => ta.timeToComplete.inDays)
        .reduce((a, b) => a + b) /
        recentTasks.length;
    final oldAvg = oldTasks.isEmpty ? recentAvg : oldTasks
        .map((ta) => ta.timeToComplete.inDays)
        .reduce((a, b) => a + b) /
        oldTasks.length;

    final trendingUp = recentAvg < oldAvg;
    final efficiency = tasksOnTime / totalTasks * 100;

    return {
      'totalTasks': totalTasks,
      'completedOnTime': tasksOnTime,
      'completionRate': (tasksOnTime / totalTasks * 100),
      'averageCompletionTime': _taskAnalytics
          .map((ta) => ta.timeToComplete.inDays)
          .reduce((a, b) => a + b) ~/
          totalTasks,
      'trendingUp': trendingUp,
      'efficiency': efficiency,
      'recentPerformance': recentAvg,
      'performanceTrend': ((oldAvg - recentAvg) / oldAvg * 100).round(),
    };
  }
} 
class TaskAnalytics {
  final DateTime completedAt;
  final Duration timeToComplete;
  final String columnName;
  final DateTime? deadline;
  final bool wasDeadlineMet;

  TaskAnalytics({
    required this.completedAt,
    required this.timeToComplete,
    required this.columnName,
    this.deadline,
    required this.wasDeadlineMet,
  });
}

class ColumnAnalytics {
  final String name;
  final int taskCount;
  final Duration averageTime;

  ColumnAnalytics({
    required this.name,
    required this.taskCount,
    required this.averageTime,
  });
} 
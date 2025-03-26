import 'package:flutter/material.dart';
import 'package:pomodoro_kanban/data/models/task_model.dart';
import 'package:pomodoro_kanban/features/kanban/widgets/task_card.dart';

class TaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  final int columnIndex;
  final Function(TaskModel) onTaskUpdate;
  final Function(String) onTaskDelete;
  final Function(int, int) onReorder;

  const TaskList({
    Key? key,
    required this.tasks,
    required this.columnIndex,
    required this.onTaskUpdate,
    required this.onTaskDelete,
    required this.onReorder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: tasks.isEmpty
          ? _buildEmptyColumn(context)
          : ReorderableListView.builder(
              itemCount: tasks.length,
              onReorder: onReorder,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskCard(
                  key: Key(task.id),
                  task: task,
                  onTaskUpdate: onTaskUpdate,
                  onDelete: () => onTaskDelete(task.id),
                );
              },
            ),
    );
  }

  Widget _buildEmptyColumn(BuildContext context) {
    return Center(
      child: Text(
        'Нет задач',
        style: TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
} 
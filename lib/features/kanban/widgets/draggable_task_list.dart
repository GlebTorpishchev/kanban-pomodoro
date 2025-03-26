import 'package:flutter/material.dart';
import 'package:pomodoro_kanban/data/models/task_model.dart';
import 'package:pomodoro_kanban/features/kanban/widgets/task_card.dart';

class DraggableTaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  final Function(TaskModel) onTaskUpdate;
  final Function(String) onTaskDelete;
  final Function(TaskModel, int)? onDragComplete;

  const DraggableTaskList({
    Key? key,
    required this.tasks,
    required this.onTaskUpdate,
    required this.onTaskDelete,
    this.onDragComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        
        return Draggable<TaskModel>(
          data: task,
          feedback: SizedBox(
            width: 260,
            child: TaskCard(
              task: task,
              onTaskUpdate: onTaskUpdate,
              onDelete: () => onTaskDelete(task.id),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: TaskCard(
              task: task,
              onTaskUpdate: onTaskUpdate,
              onDelete: () => onTaskDelete(task.id),
            ),
          ),
          child: TaskCard(
            task: task,
            onTaskUpdate: onTaskUpdate,
            onDelete: () => onTaskDelete(task.id),
          ),
        );
      },
    );
  }
} 
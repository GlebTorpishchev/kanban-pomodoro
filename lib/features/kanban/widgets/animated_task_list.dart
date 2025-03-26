import 'package:flutter/material.dart';
import 'package:pomodoro_kanban/data/models/task_model.dart';
import 'package:pomodoro_kanban/features/kanban/widgets/task_card.dart';

class AnimatedTaskList extends StatefulWidget {
  final List<TaskModel> tasks;
  final Function(TaskModel) onTaskUpdate;
  final Function(String) onTaskDelete;
  final Function(int, int) onReorder;

  const AnimatedTaskList({
    Key? key, 
    required this.tasks,
    required this.onTaskUpdate,
    required this.onTaskDelete,
    required this.onReorder,
  }) : super(key: key);

  @override
  State<AnimatedTaskList> createState() => _AnimatedTaskListState();
}

class _AnimatedTaskListState extends State<AnimatedTaskList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<TaskModel> _tasks;
  
  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.tasks);
  }
  
  @override
  void didUpdateWidget(AnimatedTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Обработка изменений в списке задач
    if (widget.tasks.length > _tasks.length) {
      // Добавлена новая задача
      final newTasks = widget.tasks.where((task) => 
        !_tasks.any((oldTask) => oldTask.id == task.id)).toList();
      
      for (var task in newTasks) {
        _insertTask(task);
      }
    } else if (widget.tasks.length < _tasks.length) {
      // Удалена задача
      final removedTasks = _tasks.where((task) => 
        !widget.tasks.any((newTask) => newTask.id == task.id)).toList();
      
      for (var task in removedTasks) {
        _removeTask(task);
      }
    } else {
      // Возможно, изменились данные или порядок
      setState(() {
        _tasks = List.from(widget.tasks);
      });
    }
  }
  
  void _insertTask(TaskModel task) {
    final index = widget.tasks.indexOf(task);
    if (index != -1) {
      _tasks.insert(index, task);
      _listKey.currentState?.insertItem(index, duration: Duration(milliseconds: 300));
    }
  }
  
  void _removeTask(TaskModel task) {
    final index = _tasks.indexOf(task);
    if (index != -1) {
      final removedTask = _tasks.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildTaskItem(context, removedTask, animation),
        duration: Duration(milliseconds: 300),
      );
    }
  }
  
  Widget _buildTaskItem(BuildContext context, TaskModel task, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          child: TaskCard(
            task: task,
            onTaskUpdate: widget.onTaskUpdate,
            onDelete: () => widget.onTaskDelete(task.id),
            isDraggable: true,
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _tasks.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index, animation) {
        return _buildTaskItem(context, _tasks[index], animation);
      },
    );
  }
} 
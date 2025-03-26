import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:pomodoro_kanban/data/models/task_model.dart';
import 'package:pomodoro_kanban/features/kanban/providers/kanban_provider.dart';
import 'package:pomodoro_kanban/features/kanban/widgets/column_header.dart';
import 'package:pomodoro_kanban/features/kanban/widgets/task_card.dart';
import 'dart:math' show max;
import 'package:pomodoro_kanban/features/kanban/widgets/animated_task_list.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:pomodoro_kanban/features/kanban/widgets/draggable_task_list.dart';

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({Key? key}) : super(key: key);

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  int? _hoveredColumnIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<KanbanProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...List.generate(provider.columnTitles.length, (index) {
                        return DragTarget<int>(
                          onAccept: (sourceIndex) {
                            if (sourceIndex != index) {
                              provider.reorderColumns(sourceIndex, index);
                            }
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              width: 320,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: provider.columnColors[index],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Draggable<int>(
                                    data: index,
                                    feedback: Material(
                                      type: MaterialType.transparency,
                                      elevation: 4,
                                      child: Container(
                                        width: 320,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: provider.columnColors[index],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: ColumnHeader(
                                          title: provider.columnTitles[index],
                                          initialColor: provider.columnColors[index],
                                          onTitleChanged: (newTitle) => 
                                            provider.updateColumnTitle(index, newTitle),
                                          onColorChanged: (color) => 
                                            provider.updateColumnColor(index, color),
                                          onDelete: () => 
                                            _showDeleteConfirmation(context, index, provider),
                                          index: index,
                                          showDragHandle: true,
                                        ),
                                      ),
                                    ),
                                    child: ColumnHeader(
                            title: provider.columnTitles[index],
                                      initialColor: provider.columnColors[index],
                                      onTitleChanged: (newTitle) => 
                                        provider.updateColumnTitle(index, newTitle),
                                      onColorChanged: (color) => 
                                        provider.updateColumnColor(index, color),
                                      onDelete: () => 
                                        _showDeleteConfirmation(context, index, provider),
                                      index: index,
                                      showDragHandle: true,
                                    ),
                                  ),
                                  Expanded(
                                    child: DragTarget<TaskModel>(
                                      onAccept: (task) {
                                        if (task.columnIndex != index) {
                                          provider.moveTask(task.id, index);
                                        }
                                      },
                                      onWillAccept: (data) => true,
                                      builder: (context, candidateData, rejectedData) {
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          decoration: BoxDecoration(
                                            color: candidateData.isNotEmpty
                                                ? Colors.black.withOpacity(0.2)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: ReorderableListView.builder(
                                            shrinkWrap: true,
                                            itemCount: provider.getTasksByColumnIndex(index).length,
                                            onReorder: (oldIndex, newIndex) {
                                              provider.reorderTasks(index, oldIndex, newIndex);
                                            },
                                            itemBuilder: (context, taskIndex) {
                                              final task = provider.getTasksByColumnIndex(index)[taskIndex];
                                              return Draggable<TaskModel>(
                                                key: ValueKey(task.id),
                                                data: task,
                                                feedback: Material(
                                                  elevation: 4.0,
                                                  color: Colors.transparent,
                                                  shadowColor: Colors.black.withOpacity(0.3),
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: SizedBox(
                                                    width: 300,
                                                    child: TaskCard(
                                                      task: task,
                                                      onTaskUpdate: provider.updateTask,
                                                      onDelete: () => provider.deleteTask(task.id),
                                                      isDraggable: false,
                                                    ),
                                                  ),
                                                ),
                                                childWhenDragging: Opacity(
                                                  opacity: 0.5,
                                                  child: TaskCard(
                                                    task: task,
                                                    onTaskUpdate: provider.updateTask,
                                                    onDelete: () => provider.deleteTask(task.id),
                                                    isDraggable: false,
                                                  ),
                                                ),
                                                child: TaskCard(
                                                  task: task,
                                                  onTaskUpdate: provider.updateTask,
                                                  onDelete: () => provider.deleteTask(task.id),
                                                  isDraggable: true,
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // Кнопка добавления задачи
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.add_circle_outline),
                                      label: const Text('Добавить задачу'),
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      onPressed: () {
                                        _showTaskDialog(context, columnIndex: index, provider: provider);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }),

                      Container(
                        margin: const EdgeInsets.all(8),
                        child: IconButton(
                          icon: const Icon(Icons.add_circle, size: 40),
                          color: Colors.grey.shade400,
                          onPressed: () {
                            provider.addColumn();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, int columnIndex, KanbanProvider provider) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Удалить колонку?'),
          content: Text('Все задачи в этой колонке будут удалены.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.deleteColumn(columnIndex);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Удалить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTaskDialog(BuildContext context, {required int columnIndex, required KanbanProvider provider}) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    Color selectedColor = Colors.blue;
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Новая задача'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Название задачи',
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Описание',
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Срок: '),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          child: Text(
                            selectedDate != null
                                ? '${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}'
                                : 'Выбрать дату'
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Цвет: '),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Выберите цвет карточки'),
                                content: SingleChildScrollView(
                                  child: BlockPicker(
                                    pickerColor: selectedColor,
                                    onColorChanged: (color) {
                                      setState(() {
                                        selectedColor = color;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      provider.addTask(
                        titleController.text,
                        description: descriptionController.text,
                        deadline: selectedDate,
                        color: selectedColor,
                        columnIndex: columnIndex,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Добавить'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pomodoro_kanban/data/models/task_model.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final Function(TaskModel) onTaskUpdate;
  final VoidCallback onDelete;
  final bool isDraggable;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTaskUpdate,
    required this.onDelete,
    this.isDraggable = false,
  }) : super(key: key);

  // Определяем, должен ли текст быть темным на основе яркости фона
  Color getTextColor(Color backgroundColor) {
    // Формула для определения яркости цвета (от 0 до 255)
    final brightness = (backgroundColor.red * 299 + 
                    backgroundColor.green * 587 + 
                    backgroundColor.blue * 114) / 1000;
    
    // Если яркость > 125, возвращаем черный цвет, иначе белый
    return brightness > 125 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = getTextColor(task.color);
    
    return Card(
      color: task.color,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Название задачи
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                ),
                
                // Кнопки справа
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: textColor),
                      onPressed: () => _showEditDialog(context),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.delete, color: textColor),
                      onPressed: () => _showDeleteConfirmation(context),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            
            // Остальное содержимое карточки без изменений
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  task.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
            
            if (task.deadline != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Срок: ${DateFormat('dd.MM.yyyy').format(task.deadline!)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final updatedTask = task.copyWith(deadline: null);
                        onTaskUpdate(updatedTask);
                      },
                      icon: Icon(Icons.close, size: 18, color: textColor),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Диалог удаления задачи с подтверждением
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить задачу?'),
          content: Text('Вы действительно хотите удалить задачу "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                onDelete();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description ?? '');
    Color selectedColor = task.color;
    DateTime? selectedDate = task.deadline;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Редактировать задачу'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Название задачи'),
                    ),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Описание'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Срок: '),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                            );
                            if (date != null) {
                              setState(() => selectedDate = date);
                            }
                          },
                          child: Text(selectedDate != null 
                            ? DateFormat('dd.MM.yyyy').format(selectedDate!)
                            : 'Выбрать дату'),
                        ),
                        if (selectedDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => selectedDate = null),
                            tooltip: 'Убрать дату',
                            iconSize: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Цвет: '),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Выберите цвет'),
                                content: SingleChildScrollView(
                                  child: BlockPicker(
                                    pickerColor: selectedColor,
                                    onColorChanged: (color) {
                                      setState(() => selectedColor = color);
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final updatedTask = task.copyWith(
                        title: titleController.text,
                        description: descriptionController.text,
                        deadline: selectedDate,
                        color: selectedColor,
                      );
                      onTaskUpdate(updatedTask);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColumnHeader extends StatefulWidget {
  final String title;
  final Color initialColor;
  final Function(String) onTitleChanged;
  final Function(Color) onColorChanged;
  final VoidCallback onDelete;
  final int index;
  final bool showDragHandle;

  const ColumnHeader({
    Key? key,
    required this.title,
    required this.initialColor,
    required this.onTitleChanged,
    required this.onColorChanged,
    required this.onDelete,
    required this.index,
    this.showDragHandle = true,
  }) : super(key: key);

  @override
  State<ColumnHeader> createState() => _ColumnHeaderState();
}

class _ColumnHeaderState extends State<ColumnHeader> {
  late TextEditingController _titleController;
  bool _isEditing = false;
  String _tempTitle = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _tempTitle = widget.title;
      _titleController.text = widget.title;
      _isEditing = true;
    });
  }

  void _saveTitle() {
    if (_titleController.text.trim().isNotEmpty) {
      widget.onTitleChanged(_titleController.text.trim());
    } else {
      // Если пустое поле, возвращаем предыдущее название
      _titleController.text = _tempTitle;
    }
    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _titleController.text = _tempTitle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.showDragHandle)
            Icon(
              Icons.drag_indicator,
              color: _getContrastColor(widget.initialColor),
            ),
          Expanded(
            child: _isEditing
                ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: TextStyle(
                      color: _getContrastColor(widget.initialColor),
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _saveTitle(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.check,
                    color: _getContrastColor(widget.initialColor),
                  ),
                  onPressed: _saveTitle,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: _getContrastColor(widget.initialColor),
                  ),
                  onPressed: _cancelEditing,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            )
                : GestureDetector(
              onTap: _startEditing,
              child: Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _getContrastColor(widget.initialColor),
                ),
              ),
            ),
          ),
          if (!_isEditing)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.color_lens,
                    color: _getContrastColor(widget.initialColor),
                  ),
                  onPressed: _showColorPicker,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: _getContrastColor(widget.initialColor),
                  ),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
        ],
      ),
    );
  }

Widget _buildHeaderContent() {
    return Container(
      decoration: BoxDecoration(
        color: widget.initialColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: _isEditing
                ? TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getContrastColor(widget.initialColor),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Название колонки',
                      hintStyle: TextStyle(
                        color: _getContrastColor(widget.initialColor)
                            .withOpacity(0.5),
                      ),
                    ),
                    onSubmitted: (value) {
                      widget.onTitleChanged(value);
                      setState(() => _isEditing = false);
                    },
                    autofocus: true,
                  )
                : InkWell(
                    onTap: () => setState(() => _isEditing = true),
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getContrastColor(widget.initialColor),
                      ),
                    ),
                  ),
          ),
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: _getContrastColor(widget.initialColor),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Изменить цвет'),
                onTap: _showColorPicker,
              ),
              PopupMenuItem(
                child: const Text('Удалить колонку'),
                onTap: widget.onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Определяем контрастный цвет для текста
  Color _getContrastColor(Color backgroundColor) {
    final brightness = (backgroundColor.red * 299 +
        backgroundColor.green * 587 +
        backgroundColor.blue * 114) / 1000;
    return brightness > 125 ? Colors.black : Colors.white;
  }

  // Метод для отображения выбора цвета
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите цвет'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: widget.initialColor,
            onColorChanged: (color) {
              widget.onColorChanged(color);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }
}
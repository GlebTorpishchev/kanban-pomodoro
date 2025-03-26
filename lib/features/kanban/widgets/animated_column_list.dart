import 'package:flutter/material.dart';
import 'package:pomodoro_kanban/features/kanban/providers/kanban_provider.dart';
import 'package:provider/provider.dart';

class AnimatedColumnList extends StatefulWidget {
  final List<Widget> columns;
  final Function(int, int) onReorder;

  const AnimatedColumnList({
    Key? key,
    required this.columns,
    required this.onReorder,
  }) : super(key: key);

  @override
  State<AnimatedColumnList> createState() => _AnimatedColumnListState();
}

class _AnimatedColumnListState extends State<AnimatedColumnList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<Widget> _columns;

  @override
  void initState() {
    super.initState();
    _columns = List.from(widget.columns);
  }

  @override
  void didUpdateWidget(AnimatedColumnList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Обработка изменений в списке колонок
    if (widget.columns.length > _columns.length) {
      // Добавлена новая колонка
      final newColumnsCount = widget.columns.length - _columns.length;
      final startIndex = _columns.length;
      
      for (var i = 0; i < newColumnsCount; i++) {
        _insertColumn(startIndex + i);
      }
    } else if (widget.columns.length < _columns.length) {
      // Удалена колонка
      final removedCount = _columns.length - widget.columns.length;
      
      for (var i = 0; i < removedCount; i++) {
        _removeColumn(_columns.length - 1 - i);
      }
    } else {
      // Возможно, изменились данные или порядок
      setState(() {
        _columns = List.from(widget.columns);
      });
    }
  }
  
  void _insertColumn(int index) {
    if (index >= 0 && index < widget.columns.length) {
      _columns.insert(index, widget.columns[index]);
      _listKey.currentState?.insertItem(index, duration: const Duration(milliseconds: 300));
    }
  }
  
  void _removeColumn(int index) {
    if (index >= 0 && index < _columns.length) {
      final removedColumn = _columns.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: FadeTransition(
            opacity: animation,
            child: removedColumn,
          ),
        ),
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _columns.length,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index, animation) {
        return SizeTransition(
          sizeFactor: animation,
          child: FadeTransition(
            opacity: animation,
            child: _columns[index],
          ),
        );
      },
    );
  }
} 
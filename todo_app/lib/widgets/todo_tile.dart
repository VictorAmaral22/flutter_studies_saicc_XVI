import 'package:flutter/material.dart';

import '../models/todo.dart';

class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  final Todo todo;
  final void Function(Todo todo) onToggle;
  final void Function(Todo todo) onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      decoration: todo.isDone ? TextDecoration.lineThrough : null,
      color: todo.isDone ? colorScheme.onSurfaceVariant : null,
    );

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () => onToggle(todo),
        leading: Checkbox(value: todo.isDone, onChanged: (_) => onToggle(todo)),
        title: Text(
          todo.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
        trailing: IconButton(
          tooltip: 'Remover tarefa',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => onDelete(todo),
        ),
      ),
    );
  }

}
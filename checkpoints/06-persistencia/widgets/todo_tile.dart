import 'package:flutter/material.dart';

import '../models/todo.dart';

/// Item da lista: checkbox, título e botão de remover.
///
/// O widget não guarda estado. Ele apenas avisa o pai (via callbacks)
/// quando o usuário interage.
class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

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
        onTap: onToggle,
        leading: Checkbox(value: todo.isDone, onChanged: (_) => onToggle()),
        title: Text(
          todo.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
        trailing: IconButton(
          tooltip: 'Remover tarefa',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../state/todo_controller.dart';
import '../widgets/add_todo_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/todo_tile.dart';

/// Tela principal: lista de tarefas + FAB + resumo no rodapé.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final TodoController controller;

  Future<void> _addTodo(BuildContext context) async {
    final title = await showAddTodoSheet(context);
    if (title == null || title.isEmpty) return;
    controller.add(title);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Tarefa adicionada')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        actions: [
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final hasCompleted =
                  controller.todos.any((todo) => todo.isDone);
              return IconButton(
                tooltip: 'Limpar concluídas',
                onPressed: hasCompleted ? controller.clearCompleted : null,
                icon: const Icon(Icons.cleaning_services_outlined),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final todos = controller.todos;

          if (todos.isEmpty) {
            return const EmptyState();
          }

          // Layout responsivo: limita largura em tablet / web / desktop.
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: todos.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return TodoTile(
                    todo: todo,
                    onToggle: () => controller.toggle(todo.id),
                    onDelete: () {
                      controller.remove(todo.id);
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          SnackBar(
                            content: Text('"${todo.title}" removida'),
                          ),
                        );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTodo(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova'),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final pending = controller.pendingCount;
          final total = controller.todos.length;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                total == 0
                    ? 'Comece adicionando uma tarefa'
                    : '$pending pendente(s) · $total no total',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../widgets/add_todo_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/todo_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Todo> _todos = [];

  Future<void> _addTodo() async {
    final title = await AddTodoSheet.show(context);
    if (title == null) return;

    setState(() => _todos = [Todo.create(title), ..._todos]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas tarefas')),
      body: SafeArea(child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTodo,
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
    );
  }

  Widget _buildBody() {
    if (_todos.isEmpty) {
      return const EmptyState();
    }

    return ListView.separated(
      // Espaço extra embaixo para o botão flutuante não cobrir o último item.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: _todos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final todo = _todos[index];
        return TodoTile(todo: todo, onToggle: () {}, onDelete: () {});
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/todo_storage.dart';
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
  final _storage = TodoStorage();

  List<Todo> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final todos = await _storage.load();
    // O widget pode ter saído da tela enquanto esperávamos o disco.
    if (!mounted) return;
    setState(() {
      _todos = todos;
      _isLoading = false;
    });
  }

  void _saveTodos() {
    unawaited(_storage.save(_todos));
  }

  Future<void> _addTodo() async {
    final title = await AddTodoSheet.show(context);
    if (title == null) return;

    setState(() => _todos = [Todo.create(title), ..._todos]);
    _saveTodos();
  }

  void _toggleTodo(Todo todo) {
    setState(() {
      _todos = [
        for (final item in _todos)
          if (item.id == todo.id) item.copyWith(isDone: !item.isDone) else item,
      ];
    });
    _saveTodos();
  }

  void _deleteTodo(Todo todo) {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) return;

    setState(() => _todos = [..._todos]..removeAt(index));
    _saveTodos();

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('"${todo.title}" removida'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => _restoreTodo(todo, index),
          ),
        ),
      );
  }

  void _restoreTodo(Todo todo, int index) {
    setState(() {
      _todos = [..._todos]..insert(index.clamp(0, _todos.length), todo);
    });
    _saveTodos();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
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
        return TodoTile(
          key: ValueKey(todo.id),
          todo: todo,
          onToggle: () => _toggleTodo(todo),
          onDelete: () => _deleteTodo(todo),
        );
      },
    );
  }
}

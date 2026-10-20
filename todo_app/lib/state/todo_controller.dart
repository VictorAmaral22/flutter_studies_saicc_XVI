import 'package:flutter/foundation.dart';

import '../models/todo.dart';

/// Gerencia a lista de tarefas e notifica a UI quando algo muda.
///
/// Abordagem nativa do Flutter (`ChangeNotifier`) — sem pacotes externos.
/// Ideal para introduzir gerenciamento de estado no mini-curso.
class TodoController extends ChangeNotifier {
  final List<Todo> _todos = [];

  List<Todo> get todos => List.unmodifiable(_todos);

  int get pendingCount => _todos.where((todo) => !todo.isDone).length;

  int get completedCount => _todos.where((todo) => todo.isDone).length;

  void add(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    _todos.insert(
      0,
      Todo(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: trimmed,
      ),
    );
    notifyListeners();
  }

  void toggle(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index < 0) return;

    final todo = _todos[index];
    _todos[index] = todo.copyWith(isDone: !todo.isDone);
    notifyListeners();
  }

  void remove(String id) {
    _todos.removeWhere((todo) => todo.id == id);
    notifyListeners();
  }

  void clearCompleted() {
    _todos.removeWhere((todo) => todo.isDone);
    notifyListeners();
  }
}

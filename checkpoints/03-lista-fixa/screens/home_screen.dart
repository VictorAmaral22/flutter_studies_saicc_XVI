import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../widgets/todo_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Dados de exemplo, só para ver a lista na tela.
  static const _todos = [
    Todo(id: '1', title: 'Instalar o Flutter', isDone: true),
    Todo(id: '2', title: 'Assistir à apresentação'),
    Todo(id: '3', title: 'Construir o app de tarefas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas tarefas')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _todos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, index) =>
              TodoTile(todo: _todos[index], onToggle: () {}, onDelete: () {}),
        ),
      ),
    );
  }
}

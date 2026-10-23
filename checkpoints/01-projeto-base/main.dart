import 'package:flutter/material.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Minhas tarefas',
      home: Scaffold(body: Center(child: Text('Olá, SAICC!'))),
    );
  }
}

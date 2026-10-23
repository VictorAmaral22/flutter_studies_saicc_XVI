import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo.dart';

/// Salva e carrega as tarefas no armazenamento local do dispositivo.
class TodoStorage {
  static const _key = 'todos';

  Future<List<Todo>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];

    final items = jsonDecode(raw) as List<dynamic>;
    return items
        .map((item) => Todo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(todos.map((todo) => todo.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}

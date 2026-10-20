/// Modelo imutável de uma tarefa.
class Todo {
  Todo({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  final String id;
  final String title;
  final bool isDone;

  Todo copyWith({
    String? title,
    bool? isDone,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}

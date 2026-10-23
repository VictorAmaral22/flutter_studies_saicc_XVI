/// Uma tarefa da lista.
///
/// A classe é imutável: para alterar um campo usamos [copyWith], que devolve
/// uma nova instância. Isso deixa as mudanças de estado previsíveis.
class Todo {
  const Todo({required this.id, required this.title, this.isDone = false});

  /// Cria uma tarefa nova com um id único baseado no horário atual.
  factory Todo.create(String title) {
    return Todo(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
    );
  }

  final String id;
  final String title;
  final bool isDone;

  Todo copyWith({String? title, bool? isDone}) {
    return Todo(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}

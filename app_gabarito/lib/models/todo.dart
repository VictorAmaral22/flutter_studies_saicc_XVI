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

  /// Recria a tarefa a partir do JSON salvo no disco.
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      isDone: json['isDone'] as bool? ?? false,
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

  /// Converte a tarefa em um mapa que pode virar JSON.
  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'isDone': isDone};
  }
}

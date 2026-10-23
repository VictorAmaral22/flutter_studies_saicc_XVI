class Todo {
  const Todo({required this.id, required this.title, this.isDone = false});
  
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
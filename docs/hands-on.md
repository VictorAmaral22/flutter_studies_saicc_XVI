# Hands-on — TODO List com Flutter

Roteiro guiado do mini-curso **SAICC XVI**.  
Siga as etapas na ordem. O código completo está em [`../todo_app/`](../todo_app/).

---

## Objetivo

Construir um app de tarefas com:

- Tema Material 3 (via [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/))
- Adicionar, listar, concluir e excluir tarefas
- Estado com `ChangeNotifier`
- Layout responsivo e empty state

---

## Etapa 0 — Ambiente

```bash
flutter doctor
flutter create todo_app
cd todo_app
flutter run
```

Se o contador padrão (demo) abrir, o ambiente está ok.

Organize as pastas:

```bash
mkdir -p lib/theme lib/models lib/state lib/screens lib/widgets
```

---

## Etapa 1 — Tema com Material Theme Builder (10 min)

1. Abra https://material-foundation.github.io/material-theme-builder/
2. Escolha uma **cor semente** (ex.: `#006A6A`)
3. Alterne Light / Dark e observe o `ColorScheme`
4. No Flutter, o equivalente mais simples é `ColorScheme.fromSeed`

Crie `lib/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

/// Tema gerado a partir de uma cor semente.
/// Regenerar em: https://material-foundation.github.io/material-theme-builder/
abstract final class AppTheme {
  static const Color seed = Color(0xFF006A6A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surfaceContainer,
        foregroundColor: scheme.onSurface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surfaceContainer,
        foregroundColor: scheme.onSurface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
```

> **Conceito:** uma cor semente gera um esquema harmônico completo (primary, secondary, surface…).

---

## Etapa 2 — Model `Todo` (5 min)

Arquivo: `lib/models/todo.dart`

```dart
class Todo {
  Todo({
    required this.id,
    required this.title,
    this.isDone = false,
  });

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
```

> **Boas práticas:** modelos imutáveis + `copyWith` facilitam UI previsível.

---

## Etapa 3 — `TodoController` (10 min)

Arquivo: `lib/state/todo_controller.dart`

```dart
import 'package:flutter/foundation.dart';

import '../models/todo.dart';

class TodoController extends ChangeNotifier {
  final List<Todo> _todos = [];

  List<Todo> get todos => List.unmodifiable(_todos);

  int get pendingCount => _todos.where((t) => !t.isDone).length;

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
    final index = _todos.indexWhere((t) => t.id == id);
    if (index < 0) return;
    final todo = _todos[index];
    _todos[index] = todo.copyWith(isDone: !todo.isDone);
    notifyListeners();
  }

  void remove(String id) {
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void clearCompleted() {
    _todos.removeWhere((t) => t.isDone);
    notifyListeners();
  }
}
```

> **Conceito:** a UI escuta `notifyListeners()` e reconstrói só o necessário.

---

## Etapa 4 — Widgets auxiliares (15 min)

### `lib/widgets/empty_state.dart`

```dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_rtl, size: 72, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              'Nenhuma tarefa ainda',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Toque em + para adicionar a primeira.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

### `lib/widgets/todo_tile.dart`

```dart
import 'package:flutter/material.dart';

import '../models/todo.dart';

class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: colors.errorContainer,
        child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
      ),
      child: ListTile(
        leading: Checkbox(
          value: todo.isDone,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isDone ? TextDecoration.lineThrough : null,
            color: todo.isDone ? colors.onSurfaceVariant : null,
          ),
        ),
        trailing: IconButton(
          tooltip: 'Excluir',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        onTap: onToggle,
      ),
    );
  }
}
```

### `lib/widgets/add_todo_sheet.dart`

```dart
import 'package:flutter/material.dart';

Future<String?> showAddTodoSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _AddTodoSheet(),
  );
}

class _AddTodoSheet extends StatefulWidget {
  const _AddTodoSheet();

  @override
  State<_AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<_AddTodoSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nova tarefa',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'O que você precisa fazer?',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite um título';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Etapa 5 — `HomeScreen` (15 min)

Arquivo: `lib/screens/home_screen.dart`

```dart
import 'package:flutter/material.dart';

import '../state/todo_controller.dart';
import '../widgets/add_todo_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/todo_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final TodoController controller;

  Future<void> _addTodo(BuildContext context) async {
    final title = await showAddTodoSheet(context);
    if (title == null || title.isEmpty) return;
    controller.add(title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        actions: [
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final hasCompleted = controller.todos.any((t) => t.isDone);
              return IconButton(
                tooltip: 'Limpar concluídas',
                onPressed: hasCompleted ? controller.clearCompleted : null,
                icon: const Icon(Icons.cleaning_services_outlined),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final todos = controller.todos;

          if (todos.isEmpty) return const EmptyState();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: todos.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return TodoTile(
                    todo: todo,
                    onToggle: () => controller.toggle(todo.id),
                    onDelete: () => controller.remove(todo.id),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTodo(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova'),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final pending = controller.pendingCount;
          final total = controller.todos.length;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                total == 0
                    ? 'Comece adicionando uma tarefa'
                    : '$pending pendente(s) · $total no total',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        },
      ),
    );
  }
}
```

> **Responsividade:** `ConstrainedBox(maxWidth: 720)` evita lista esticada em tablet/web.

---

## Etapa 6 — `main.dart` (5 min)

```dart
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'state/todo_controller.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  final _controller = TodoController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO · SAICC XVI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: HomeScreen(controller: _controller),
    );
  }
}
```

Rode:

```bash
flutter run
```

---

## Checklist final

- [ ] Tema light/dark aplicado (mude o tema do sistema)
- [ ] Adicionar tarefa pelo FAB
- [ ] Concluir com checkbox ou tap
- [ ] Excluir pelo ícone ou swipe
- [ ] Empty state quando a lista zera
- [ ] Em janela larga (web/desktop), conteúdo centralizado

---

## Desafios extras (se sobrar tempo)

1. Filtro: Todas / Pendentes / Concluídas (`SegmentedButton`)
2. Persistência com `shared_preferences`
3. Reordenar com `ReorderableListView`
4. Exportar o tema completo do Theme Builder (tokens JSON) e mapear cores manualmente

---

## Referências

- [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/)
- [Flutter — State management](https://docs.flutter.dev/data-and-backend/state-mgmt/intro)
- [Material 3 in Flutter](https://docs.flutter.dev/ui/design/material)
|

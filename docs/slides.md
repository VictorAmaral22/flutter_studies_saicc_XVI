---
marp: true
theme: default
paginate: true
size: 16:9
title: Introdução ao Flutter — SAICC XVI
description: Mini-curso de desenvolvimento mobile com Flutter
author: SAICC XVI · FURG
---

<!-- _class: lead -->

# Introdução ao Flutter
### Desenvolvimento Mobile com Dart

**SAICC XVI** · Semana Acadêmica da Computação  
Universidade Federal do Rio Grande (FURG)

⏱ 2 horas · Teoria + Hands-on

---

# Agenda

| Bloco | Conteúdo | Tempo |
|-------|----------|-------|
| 1 | Dart em 10 minutos | ~10 min |
| 2 | Flutter: arquitetura e Widgets | ~15 min |
| 3 | Estado, layout e boas práticas | ~15 min |
| 4 | Tema com Material Theme Builder | ~5 min |
| 5 | Hands-on: app TODO List | ~70 min |
| — | Perguntas e encerramento | ~5 min |

---

# O que vamos construir

Um **TODO List** mobile com:

- UI Material Design 3
- Tema gerado no [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/)
- CRUD de tarefas (criar, listar, concluir, excluir)
- Gerenciamento de estado reativo
- Layout responsivo
- Código limpo e organizado

---

<!-- _class: lead -->

# Parte 1
## A linguagem Dart

---

# Por que Dart?

- Linguagem **otimizada para UI** (Google)
- Compila para **nativo** (AOT) e para **JS/WASM**
- Tipagem estática + null safety
- Sintaxe familiar (Java / C# / TypeScript)
- Ecossistema unificado com Flutter

> Um único código → Android, iOS, Web, Desktop

---

# Dart — fundamentos rápidos

```dart
// Variáveis e tipagem
final String nome = 'SAICC';
var contador = 0;          // inferência
const pi = 3.1415;         // compile-time

// Null safety
String? opcional;          // pode ser null
String obrigatorio = 'ok'; // nunca null

// Funções
int soma(int a, int b) => a + b;

// Classes
class Tarefa {
  final String titulo;
  bool concluida;

  Tarefa({required this.titulo, this.concluida = false});
}
```

---

# Dart — coleções e async

```dart
final tarefas = <String>['Estudar', 'Codar'];
tarefas.add('Apresentar');

final filtradas = tarefas
    .where((t) => t.startsWith('E'))
    .toList();

// Assíncrono
Future<String> buscarDados() async {
  await Future.delayed(const Duration(seconds: 1));
  return 'pronto';
}
```

**Hot tip:** no Flutter, `async/await` aparece em I/O, rede e persistência.

---

<!-- _class: lead -->

# Parte 2
## Flutter: o framework

---

# O que é Flutter?

Framework **declarativo** de UI multiplataforma.

```
┌─────────────────────────────────────┐
│           Seu código Dart           │
├─────────────────────────────────────┤
│         Widgets (árvore de UI)      │
├─────────────────────────────────────┤
│     Rendering / Composition         │
├─────────────────────────────────────┤
│   Skia / Impeller (motor gráfico)   │
├─────────────────────────────────────┤
│     Android · iOS · Web · Desktop   │
└─────────────────────────────────────┘
```

- **Hot Reload** → iterações em milissegundos
- Performance próxima do nativo
- UI consistente entre plataformas

---

# Tudo é Widget

No Flutter, **tudo** que você vê (e muito do que não vê) é um Widget:

| Tipo | Exemplos | Função |
|------|----------|--------|
| Estrutura | `Scaffold`, `AppBar`, `Column` | Layout / navegação |
| Visuais | `Text`, `Icon`, `Image` | Conteúdo |
| Interação | `ElevatedButton`, `TextField` | Input do usuário |
| Estilo | `Padding`, `Container`, `Theme` | Espaçamento / tema |

> Widgets são **imutáveis**. A UI muda reconstruindo a árvore.

---

# StatelessWidget vs StatefulWidget

```dart
// Sem estado interno — só depende de parâmetros
class Titulo extends StatelessWidget {
  const Titulo({super.key, required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Text(texto);
}

// Com estado interno que pode mudar
class Contador extends StatefulWidget {
  const Contador({super.key});
  @override
  State<Contador> createState() => _ContadorState();
}
```

**Regra prática:** comece com `StatelessWidget`. Só use `Stateful` quando o widget precisar **guardar** estado.

---

# Árvore de Widgets (exemplo)

```dart
MaterialApp
 └─ Scaffold
     ├─ AppBar → Text('TODO')
     └─ body: Column
         ├─ TextField
         └─ Expanded
             └─ ListView
                 ├─ ListTile (tarefa 1)
                 └─ ListTile (tarefa 2)
```

O Flutter **diff** a árvore antiga com a nova e redesenha só o necessário.

---

# Material Design 3

Flutter traz Material 3 pronto:

- `ColorScheme` gerado a partir de uma **cor semente**
- Tipografia, elevação, shapes padronizados
- Dark / Light mode

**Ferramenta do mini-curso:**

🔗 [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/)

1. Escolha a cor semente  
2. Exporte / copie o esquema  
3. Aplique no `ThemeData` do app

---

<!-- _class: lead -->

# Parte 3
## Estado, layout e qualidade

---

# Gerenciamento de estado

**Problema:** dados mudam → UI precisa reagir.

| Abordagem | Quando usar |
|-----------|-------------|
| `setState` | Estado local e simples |
| `ValueNotifier` / `ChangeNotifier` | Estado compartilhado leve |
| Provider / Riverpod / Bloc | Apps maiores |

Neste mini-curso usaremos **`ChangeNotifier` + `ListenableBuilder`**  
(API nativa do Flutter, sem pacotes extras).

---

# ChangeNotifier — ideia

```dart
class TodoController extends ChangeNotifier {
  final List<Todo> _todos = [];
  List<Todo> get todos => List.unmodifiable(_todos);

  void add(String titulo) {
    _todos.add(Todo(titulo: titulo));
    notifyListeners(); // avisa a UI
  }
}

// Na UI:
ListenableBuilder(
  listenable: controller,
  builder: (context, _) => ListView(...),
);
```

**Separação:** lógica no controller · UI nos widgets.

---

# Layout responsivo

Conceitos essenciais:

- **`MediaQuery`** — tamanho da tela, padding do sistema
- **`LayoutBuilder`** — constraints do pai
- **`Flexible` / `Expanded`** — espaço flexível
- **`ConstrainedBox` / `maxWidth`** — limitar largura em tablets/web

```dart
final width = MediaQuery.sizeOf(context).width;
final isWide = width >= 600;

return Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 720),
    child: /* conteúdo */,
  ),
);
```

---

# Código limpo no Flutter

1. **Uma responsabilidade por arquivo** (`models/`, `widgets/`, `screens/`)
2. **Widgets pequenos** e reutilizáveis
3. **Nomes claros** (`TodoTile`, não `Item1`)
4. **`const` constructors** sempre que possível
5. **Evitar lógica de negócio no `build()`**
6. Extrair strings/cores para tema e constantes

```
lib/
 ├── main.dart
 ├── theme/app_theme.dart
 ├── models/todo.dart
 ├── state/todo_controller.dart
 ├── screens/home_screen.dart
 └── widgets/...
```

---

# Hot Reload vs Hot Restart

| | Hot Reload | Hot Restart |
|---|------------|-------------|
| Atalho | `r` | `R` |
| Mantém estado? | Sim | Não |
| Quando usar | Ajustes de UI | Mudança de `main`, enums, init |

---

<!-- _class: lead -->

# Parte 4
## Mãos à obra 🛠️

---

# Pré-requisitos

```bash
flutter doctor          # verificar ambiente
flutter create todo_app
cd todo_app
flutter run             # emulador, device ou Chrome
```

**Editor:** VS Code / Android Studio / Cursor  
**SDK:** Flutter 3.x + Dart 3.x

---

# Fluxo do hands-on

1. Gerar tema no Material Theme Builder  
2. Modelar a entidade `Todo`  
3. Criar `TodoController` (estado)  
4. Montar a `HomeScreen`  
5. Widgets: lista, tile, formulário, empty state  
6. Polir: responsividade, dark mode, feedback visual

Código de referência: pasta `todo_app/` deste repositório.

---

# Recursos oficiais

- [docs.flutter.dev](https://docs.flutter.dev)
- [api.flutter.dev](https://api.flutter.dev)
- [dart.dev/language](https://dart.dev/language)
- [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/)
- [Flutter Widget Catalog](https://docs.flutter.dev/ui/widgets)

---

<!-- _class: lead -->

# Vamos codar!
### Dúvidas durante o hands-on são bem-vindas 🚀

**SAICC XVI** · FURG
|

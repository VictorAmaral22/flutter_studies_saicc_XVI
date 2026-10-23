import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/main.dart';

Future<void> _addTodo(WidgetTester tester, String title) async {
  await tester.tap(find.text('Nova tarefa'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField), title);
  await tester.tap(find.text('Adicionar'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('mostra o estado vazio no início', (tester) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma tarefa por aqui'), findsOneWidget);
  });

  testWidgets('adiciona e conclui uma tarefa', (tester) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();

    await _addTodo(tester, 'Estudar Flutter');

    expect(find.text('Estudar Flutter'), findsOneWidget);
    expect(find.text('Nenhuma tarefa por aqui'), findsNothing);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('não aceita título vazio', (tester) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();

    await _addTodo(tester, '   ');

    expect(find.text('Digite um título para a tarefa'), findsOneWidget);
  });

  testWidgets('remove e desfaz a remoção', (tester) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();
    await _addTodo(tester, 'Tarefa temporária');

    await tester.tap(find.byTooltip('Remover tarefa'));
    await tester.pumpAndSettle();
    expect(find.text('Tarefa temporária'), findsNothing);

    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(find.text('Tarefa temporária'), findsOneWidget);
  });

  testWidgets('carrega as tarefas salvas', (tester) async {
    SharedPreferences.setMockInitialValues({
      'todos': '[{"id":"1","title":"Salva antes","isDone":true}]',
    });

    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();

    expect(find.text('Salva antes'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });
}

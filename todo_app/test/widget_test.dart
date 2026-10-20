import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_app/main.dart';

void main() {
  testWidgets('mostra empty state e adiciona tarefa', (tester) async {
    await tester.pumpWidget(const TodoApp());

    expect(find.text('Nenhuma tarefa ainda'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Estudar Flutter');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Estudar Flutter'), findsOneWidget);
    expect(find.text('Nenhuma tarefa ainda'), findsNothing);
  });
}

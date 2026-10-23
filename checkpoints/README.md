# Checkpoints

Cada subpasta contém **o que a pasta `lib/` do app possui ao final de uma etapa** do minicurso. Se você se perder, copie o checkpoint para o seu `lib/` e continue dali.

| Pasta | Ao final desta etapa o app... |
|-------|-------------------------------|
| [`01-projeto-base`](01-projeto-base) | mostra "Olá, SAICC!" |
| [`02-tema`](02-tema) | tem tema Material 3 claro e escuro |
| [`03-lista-fixa`](03-lista-fixa) | mostra uma lista fixa de tarefas |
| [`04-adicionar-tarefas`](04-adicionar-tarefas) | adiciona tarefas por um formulário (`setState`) |
| [`05-concluir-e-remover`](05-concluir-e-remover) | conclui, remove e desfaz |
| [`06-persistencia`](06-persistencia) | salva as tarefas no aparelho (igual ao [`todo_app/`](../todo_app)) |

Os checkpoints são cumulativos: cada um só adiciona ou altera arquivos em relação ao anterior.

## Como restaurar um checkpoint

Na raiz do repositório clonado (exemplo com o 3):

```bash
cp -r checkpoints/03-lista-fixa/* /caminho/do/seu/todo_app/lib/
```

```powershell
# Windows (PowerShell)
Copy-Item -Recurse -Force checkpoints\03-lista-fixa\* C:\caminho\do\seu\todo_app\lib\
```

Depois rode `flutter run`, ou aperte `R` (hot restart) se o app já estiver aberto.

O checkpoint `06-persistencia` usa o pacote `shared_preferences`. Rode `flutter pub add shared_preferences` no projeto antes de restaurá-lo e reinicie o app com `flutter run`.

O roteiro completo, com explicações, está em [`docs/hands-on.md`](../docs/hands-on.md).

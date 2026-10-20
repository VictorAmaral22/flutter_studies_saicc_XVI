# Cronograma — Mini-curso Flutter · SAICC XVI

**Duração total:** 2 horas  
**Formato:** apresentação rápida + implementação guiada  
**Público:** estudantes de Computação (qualquer nível; ideal ter noção de OOP)

---

## Visão geral

| # | Bloco | Duração | Tipo |
|---|--------|---------|------|
| 0 | Abertura e setup | 5 min | Organização |
| 1 | Dart em 10 minutos | 10 min | Slides |
| 2 | Flutter, Widgets e Material 3 | 15 min | Slides |
| 3 | Estado, layout responsivo e código limpo | 15 min | Slides |
| 4 | Material Theme Builder | 5 min | Demo ao vivo |
| 5 | Hands-on: TODO List | 70 min | Codificação |
| 6 | Encerramento e Q&A | 5 min | Debate |

---

## Bloco 0 — Abertura (5 min)

- Apresentação do instrutor e do mini-curso
- Objetivo: sair com um app TODO funcional e uma base sólida de Flutter
- Checklist rápido: `flutter doctor`, emulador/device, editor aberto
- Link do repositório e slides

---

## Bloco 1 — Dart (10 min)

- Por que Dart existe no ecossistema Flutter
- Variáveis, tipagem, null safety
- Classes, coleções, `async/await` (visão geral)
- **Não aprofundar:** generics avançados, isolates, FFI

---

## Bloco 2 — Flutter e Widgets (15 min)

- Arquitetura (Dart → Widgets → Engine → plataformas)
- “Tudo é Widget”
- `StatelessWidget` vs `StatefulWidget`
- Árvore de widgets e rebuild
- Material Design 3 no Flutter

---

## Bloco 3 — Estado, layout e qualidade (15 min)

- Por que precisamos de gerenciamento de estado
- `setState` vs `ChangeNotifier` + `ListenableBuilder`
- Layout responsivo: `MediaQuery`, `LayoutBuilder`, `maxWidth`
- Estrutura de pastas e boas práticas
- Hot Reload vs Hot Restart

---

## Bloco 4 — Material Theme Builder (5 min)

Ferramenta: https://material-foundation.github.io/material-theme-builder/

1. Abrir o site e escolher uma cor semente
2. Visualizar light/dark
3. Explicar como o seed vira `ColorScheme` no Flutter
4. Mostrar o arquivo `todo_app/lib/theme/app_theme.dart` como destino

---

## Bloco 5 — Hands-on (70 min)

Seguir o guia em [`hands-on.md`](./hands-on.md).

| Etapa | Conteúdo | Tempo sugerido |
|-------|----------|----------------|
| 5.1 | Projeto + tema | 10 min |
| 5.2 | Model `Todo` | 5 min |
| 5.3 | `TodoController` | 10 min |
| 5.4 | `HomeScreen` + Scaffold | 10 min |
| 5.5 | Lista, tile e empty state | 15 min |
| 5.6 | Adicionar / concluir / excluir | 15 min |
| 5.7 | Responsividade e polish | 5 min |

**Estratégia do instrutor:**
- Codar junto no projetor
- Pausar a cada etapa para quem travou
- Ter o código final da pasta `todo_app/` como referência

---

## Bloco 6 — Encerramento (5 min)

- Recapitular: Dart → Widgets → Estado → Tema → App
- Próximos passos: persistência (`shared_preferences` / Hive), navegação, testes
- Links e repositório
- Perguntas

---

## Materiais do repositório

| Arquivo | Uso |
|---------|-----|
| [`slides.md`](./slides.md) | Apresentação (Marp) |
| [`hands-on.md`](./hands-on.md) | Roteiro guiado para alunos |
| [`guia-instrutor.md`](./guia-instrutor.md) | Dicas e troubleshooting |
| [`../todo_app/`](../todo_app/) | Código de referência do app |
|

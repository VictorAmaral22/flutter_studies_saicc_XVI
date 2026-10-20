# Flutter Intro — SAICC XVI

Mini-curso introdutório de **Flutter** para a **Semana Acadêmica da Computação (SAICC XVI)** da Universidade Federal do Rio Grande (FURG).

**Duração:** 2 horas  
**Formato:** slides rápidos + implementação guiada de um app **TODO List**

---

## Conteúdo

| Material | Descrição |
|----------|-----------|
| [`docs/slides.md`](docs/slides.md) | Apresentação (Marp) — Dart, Flutter, Widgets, estado, layout |
| [`docs/cronograma.md`](docs/cronograma.md) | Cronograma detalhado das 2h |
| [`docs/hands-on.md`](docs/hands-on.md) | Roteiro passo a passo do app |
| [`docs/guia-instrutor.md`](docs/guia-instrutor.md) | Dicas, troubleshooting e critérios de sucesso |
| [`todo_app/`](todo_app/) | Código de referência do TODO List |

### Tópicos abordados

- Linguagem **Dart** (fundamentos)
- Arquitetura do **Flutter** e árvore de **Widgets**
- `StatelessWidget` vs `StatefulWidget`
- Gerenciamento de estado com `ChangeNotifier` + `ListenableBuilder`
- **Material Design 3** e tema via [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/)
- Código limpo e organização de pastas
- Layout responsivo (`MediaQuery`, `ConstrainedBox`)

---

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x
- Editor (VS Code, Android Studio ou Cursor)
- Emulador Android, dispositivo físico ou Chrome (`flutter run -d chrome`)

```bash
flutter doctor
```

### Laboratório (Ubuntu 22.04)

Instalação automatizada de Flutter + Android Studio (perfil leve) + AVD otimizado:

```bash
chmod +x scripts/linux/install-lab.sh
sudo ./scripts/linux/install-lab.sh --system   # compartilhado em /opt
# ou
sudo ./scripts/linux/install-lab.sh            # no $HOME do usuário (sudo obrigatório)
```

Detalhes: [`scripts/linux/README.md`](scripts/linux/README.md).

### Laboratório (Windows 10/11)

O instalador exige PowerShell **como Administrador** (equivalente ao sudo):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\install-lab.ps1 -System
```

Detalhes: [`scripts/windows/README.md`](scripts/windows/README.md).

### Laboratório (macOS)

O instalador exige **sudo**. No Apple Silicon a imagem do emulador é `arm64-v8a`; no Intel, `x86_64`.

```bash
chmod +x scripts/macos/install-lab.sh
sudo ./scripts/macos/install-lab.sh --system
```

Detalhes: [`scripts/macos/README.md`](scripts/macos/README.md).

---

## Rodar o app de referência

```bash
cd todo_app
flutter pub get
flutter run
```

### Tema (Material Theme Builder)

1. Abra o [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/)
2. Escolha uma cor semente
3. Atualize `seed` em [`todo_app/lib/theme/app_theme.dart`](todo_app/lib/theme/app_theme.dart)
4. Faça **Hot Restart** (`R`) para aplicar

---

## Apresentar os slides

Os slides estão em formato [Marp](https://marp.app/). No VS Code/Cursor, use a extensão Marp, ou:

```bash
npx @marp-team/marp-cli docs/slides.md --pdf -o docs/slides.pdf
npx @marp-team/marp-cli docs/slides.md --html -o docs/slides.html
```

---

## Estrutura do app

```
todo_app/lib/
├── main.dart                 # MaterialApp + tema
├── theme/app_theme.dart      # ColorScheme.fromSeed (Theme Builder)
├── models/todo.dart          # Modelo imutável
├── state/todo_controller.dart# ChangeNotifier
├── screens/home_screen.dart  # Tela principal
└── widgets/
    ├── todo_tile.dart
    ├── add_todo_sheet.dart
    └── empty_state.dart
```

---

## Cronograma resumido

| Bloco | Tempo |
|-------|-------|
| Abertura + Dart | ~15 min |
| Flutter, Widgets, estado, layout | ~30 min |
| Material Theme Builder | ~5 min |
| Hands-on TODO List | ~70 min |
| Q&A | ~5 min |

Detalhes em [`docs/cronograma.md`](docs/cronograma.md).

---

## Licença

Veja [LICENSE](LICENSE).
|

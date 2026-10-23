# Flutter na prática: minicurso SAICC XVI

Material do minicurso de **Flutter para desenvolvimento mobile** (2 horas): uma apresentação rápida sobre Dart e Flutter, seguida da construção guiada de um app de lista de tarefas com tema Material 3, formulário, estado com `setState` e persistência local.

Repositório: <https://github.com/mathyc0de/flutter_intro>

## Conteúdo

| Pasta | O que tem |
|-------|-----------|
| [`slides/`](slides) | Slides em reveal.js (43 slides + 23 slides dos checkpoints) e versão compilada em `slides/dist/` (HTML e PDF) |
| [`docs/cronograma.md`](docs/cronograma.md) | Cronograma minuto a minuto das 2 horas |
| [`docs/hands-on.md`](docs/hands-on.md) | Roteiro passo a passo para construir o app (6 checkpoints) |
| [`docs/tema-material.md`](docs/tema-material.md) | Como gerar o tema no [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/) |
| [`docs/guia-instrutor.md`](docs/guia-instrutor.md) | Falas, armadilhas, plano B e cortes de tempo |
| [`checkpoints/`](checkpoints) | O que a pasta `lib/` possui ao final de cada etapa do curso (6 checkpoints) |
| [`todo_app/`](todo_app) | App final (gabarito, igual ao último checkpoint) |
| [`scripts/`](scripts) | Instalação do ambiente (Flutter, Android Studio, emulador) para Linux, Windows e macOS |

## O app

Lista de tarefas com adicionar (bottom sheet com validação), concluir, remover com desfazer, tema claro e escuro e dados salvos com `shared_preferences`. O estado é gerenciado apenas com `setState`.

```
todo_app/lib/
  main.dart
  data/todo_storage.dart
  models/todo.dart
  screens/home_screen.dart
  theme/{app_theme,color_scheme}.dart
  widgets/{add_todo_sheet,empty_state,todo_tile}.dart
```

O curso é feito em **checkpoints**: cada subpasta de [`checkpoints/`](checkpoints) tem o conteúdo de `lib/` ao final de uma etapa (`01-projeto-base` até `06-persistencia`). Quem se perder copia o checkpoint para o próprio `lib/` e segue. Veja [`checkpoints/README.md`](checkpoints/README.md).

Para rodar:

```bash
cd todo_app
flutter pub get
flutter run            # emulador ou celular
flutter run -d chrome  # navegador
flutter analyze && flutter test
```

## Slides

Abra `slides/dist/index.html` no navegador (setas para navegar, `S` para notas do apresentador, `?print-pdf` para impressão) ou use o PDF em `slides/dist/slides.pdf`.

Há também uma segunda apresentação, com **um slide de visão geral, ilustração do resultado esperado e código para cada checkpoint**: `slides/dist/checkpoints.html` (PDF em `slides/dist/checkpoints.pdf`).

Para recompilar após editar `slides/src/index.html` ou `slides/src/checkpoints.html`:

```bash
cd slides
npm install
npm run build   # dist/index.html e dist/checkpoints.html
npm run pdf     # HTML + dist/slides.pdf e dist/checkpoints.pdf (requer Chrome via puppeteer)
```

Se o Chrome do puppeteer não estiver instalado: `npx puppeteer browsers install chrome`.

---

## Instalação do ambiente

Scripts para instalar o **Flutter** e o toolchain necessário para compilar apps.

| Sistema | Script | O que instala |
|---------|--------|----------------|
| Windows 10/11 | [`scripts/windows/install-lab.ps1`](scripts/windows/install-lab.ps1) | Git (se faltar), Flutter, Android Studio enxuto, Android SDK 36, BuildTools 28.0.3, AVD, extensões Dart/Flutter no VS Code |
| Ubuntu 22.04 | [`scripts/linux/install-lab.sh`](scripts/linux/install-lab.sh) | Flutter, Android Studio, Android SDK, AVD, KVM, extensões do VS Code |
| macOS | [`scripts/macos/install-lab.sh`](scripts/macos/install-lab.sh) | Flutter, Android Studio, Android SDK, AVD, extensões do VS Code |

Windows e Linux exigem administrador (`PowerShell como administrador` / `sudo`). A flag de instalação compartilhada é `-System` no Windows e `--system` no Linux e no macOS.

### Instalação direta pela web

Rode em um terminal **com privilégio de administrador**.

Windows (PowerShell como administrador):

```powershell
iex (irm https://raw.githubusercontent.com/mathyc0de/flutter_intro/main/scripts/windows/install-web.ps1)
```

Linux (no macOS, troque o caminho por `scripts/macos/install-web.sh`):

```bash
curl -fsSL https://raw.githubusercontent.com/mathyc0de/flutter_intro/main/scripts/linux/install-web.sh | sudo bash
```

### Instalação a partir do clone

```bash
git clone https://github.com/mathyc0de/flutter_intro.git
cd flutter_intro
```

```powershell
# Windows
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\install-lab.ps1 -System
```

```bash
# Linux
sudo ./scripts/linux/install-lab.sh --system

# macOS
sudo ./scripts/macos/install-lab.sh --system
```

No Apple Silicon a imagem do emulador é `arm64-v8a`. No Intel, `x86_64`.

### Depois de instalar

Abra um terminal novo:

```bash
flutter doctor -v
saicc-emulator   # Windows e Linux
```

Detalhes de cada sistema: [Windows](scripts/windows/README.md), [Linux](scripts/linux/README.md), [macOS](scripts/macos/README.md).

## Autor

Matheus Silveira: <https://www.linkedin.com/in/matheuspsilveira/>

## Licença

Veja [LICENSE](LICENSE).

# Setup do laboratório — macOS

Equivalente macOS de [`../linux/install-lab.sh`](../linux/install-lab.sh). Serve para Mac Intel e Apple Silicon.

## O que é instalado

| Componente | Detalhe |
|------------|---------|
| Dependências | Git via Command Line Tools da Apple |
| Aceleração | Hypervisor.framework (HVF) — já vem no macOS; o script só confere |
| Flutter | Stable da arquitetura da máquina (`arm64` ou `x86_64`) |
| Android Studio | Zip oficial em `/Applications` (modo `--system`) + heap ~1.5 GB |
| Android SDK | platform-tools, **build-tools 28.0.3**, **platform API 36**, emulator |
| Imagem do AVD | `arm64-v8a` no Apple Silicon, `x86_64` no Intel (`google_apis`) |
| AVD | `SAICC_API36` — 1.5 GB RAM, 2 cores, GPU host, sem SD card |
| Licenças | `sdkmanager --licenses` + `flutter doctor --android-licenses` |
| VS Code | App em `/Applications` + extensões `Dart-Code.dart` e `Dart-Code.flutter` |

## Requisitos

- macOS 12 ou mais novo
- Usuário administrador (o script **exige sudo**)
- Ideal: **≥ 8 GB RAM**
- Disco livre: **~15–20 GB**

## Uso

```bash
chmod +x scripts/macos/install-lab.sh
sudo ./scripts/macos/install-lab.sh --system
```

Sem `--system`, Flutter e SDK ficam no home de quem rodou o `sudo`. O Android Studio do modo sistema vai para `/Applications/Android Studio.app`. O SDK compartilhado fica em `/opt/saicc`, com permissão de escrita para o grupo `staff`.

Se as Command Line Tools não estiverem instaladas, o script abre o instalador da Apple e pede para rodar de novo.

Depois, abra um **novo** Terminal:

```bash
flutter doctor -v
saicc-emulator
flutter run
```

## Flags

```bash
sudo ./scripts/macos/install-lab.sh --skip-studio
sudo ./scripts/macos/install-lab.sh --skip-emulator
sudo ./scripts/macos/install-lab.sh --skip-hypervisor
sudo ./scripts/macos/install-lab.sh --skip-vscode
sudo ./scripts/macos/install-lab.sh --help
```

```bash
sudo FLUTTER_VERSION=3.47.7 \
  ANDROID_STUDIO_VERSION=2024.3.2.14 \
  ANDROID_API=36 \
  BUILD_TOOLS=28.0.3 \
  ./scripts/macos/install-lab.sh --system
```

## Conferência

```bash
./scripts/macos/verify-lab.sh
```

## Troubleshooting

| Problema | Ação |
|----------|------|
| "precisa ser executado com sudo" | Rode com `sudo` a partir do usuário do lab |
| `kern.hv_support=0` | Mac físico deveria ter HVF. Em VM, ligue a virtualização aninhada |
| Emulador lento no Apple Silicon | Confirme a imagem `arm64-v8a` (o script já escolhe essa) |
| `Flutter requires Android SDK 36` | Rode o instalador de novo |
| Licenças pendentes | `flutter doctor --android-licenses` |
| Link 404 do Android Studio | Atualize `ANDROID_STUDIO_VERSION` |

## Relação com o mini-curso

Código do app: [`../../todo_app/`](../../todo_app/)  
Roteiro: [`../../docs/hands-on.md`](../../docs/hands-on.md)

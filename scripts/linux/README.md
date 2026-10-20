# Setup do laboratório — Flutter + Android Studio

Ubuntu 22.04: este arquivo. Windows: [`../windows/README.md`](../windows/README.md). macOS: [`../macos/README.md`](../macos/README.md).

Scripts para preparar os PCs do lab da **SAICC XVI** com instalação enxuta, KVM e emulador leve.

## O que é instalado

| Componente | Detalhe |
|------------|---------|
| Dependências | JDK 17, git, clang/cmake (Linux desktop), KVM |
| Flutter | Canal stable (versão pinada no script) |
| Android Studio | Tarball oficial + `studio64.vmoptions` com heap ~1.5 GB |
| Android SDK | platform-tools, **build-tools 28.0.3**, **platform API 36**, emulator |
| AVD | `SAICC_API36` — Pixel 5, **1.5 GB RAM**, **2 cores**, GPU host, sem SD card |
| Licenças Android | Aceite automático via `sdkmanager --licenses` + `flutter doctor --android-licenses` |
| VS Code | Extensões `Dart-Code.dart` e `Dart-Code.flutter` (se o comando `code` existir) |

## Requisitos dos PCs

- Ubuntu **22.04** x86_64
- Ideal: **≥ 8 GB RAM** (16 GB confortável com Studio + emulador)
- Virtualização habilitada no BIOS (**VT-x / AMD-V**)
- Disco livre: **~15–20 GB** por máquina
- Rede para baixar SDKs (primeira instalação)

## Uso rápido (por máquina / imagem)

> O instalador **exige sudo** (rode sempre com `sudo`).

### Instalação no home do usuário (demo / aluno)

```bash
cd /caminho/para/flutter_intro
chmod +x scripts/lab/install-lab.sh scripts/lab/start-emulator.sh
sudo ./scripts/lab/install-lab.sh
```

Depois, **abra um novo terminal** (ou `source ~/.saicc-flutter-env.sh`) e rode:

```bash
flutter doctor -v
saicc-emulator &
flutter run
```

### Instalação compartilhada em `/opt` (recomendado no lab)

```bash
sudo ./scripts/lab/install-lab.sh --system
```

- Flutter / Studio → `/opt/saicc/`
- SDK → `/opt/saicc/Android/Sdk`
- Ambiente → `/etc/profile.d/saicc-flutter.sh`
- Grupo `saicc` com permissão de escrita no SDK
- **Re-login** do usuário para aplicar grupos `kvm` e `saicc`

## Flags úteis

```bash
sudo ./scripts/lab/install-lab.sh --skip-studio     # só Flutter + SDK + AVD
sudo ./scripts/lab/install-lab.sh --skip-emulator   # sem imagem/AVD
sudo ./scripts/lab/install-lab.sh --skip-kvm        # sem pacotes KVM
sudo ./scripts/lab/install-lab.sh --skip-vscode     # sem extensões do VS Code
```

> As licenças Android são aceitas automaticamente no fim da instalação.  
> Para o VS Code, o binário `code` precisa estar no PATH (instale o VS Code antes ou depois e rode o script de novo).

Variáveis de ambiente:

```bash
sudo FLUTTER_VERSION=3.47.7 \
  ANDROID_STUDIO_VERSION=2024.3.2.14 \
  ANDROID_API=36 \
  BUILD_TOOLS=28.0.3 \
  ./scripts/lab/install-lab.sh
```

## Otimizações aplicadas

### Android Studio

- Heap limitado (`-Xmx1536m`) em [`configs/studio64.vmoptions`](configs/studio64.vmoptions)
- Menos background/update em [`configs/idea.properties`](configs/idea.properties)
- Plugins nativos pesados desabilitados quando presentes (NDK/C++)
- Launcher `.desktop`: **Android Studio (SAICC)**

### Emulador

- Imagem `google_apis` (sem Play Store → mais leve)
- 1536 MB RAM · 2 vCPUs · partição 2 GB · GPU **host**
- Script [`start-emulator.sh`](start-emulator.sh) → comando `saicc-emulator`:
  - `-no-audio`
  - `-no-boot-anim`
  - `-gpu host`

## Checklist do técnico do lab

1. [ ] BIOS: virtualização ligada  
2. [ ] `sudo ./scripts/lab/install-lab.sh --system` em um PC piloto  
3. [ ] `./scripts/lab/verify-lab.sh` (e `flutter doctor` limpo no Android toolchain)  
4. [ ] `saicc-emulator` sobe e o `todo_app` roda  
5. [ ] Clonar a imagem / repetir o script nos demais PCs  
6. [ ] Orientar alunos: **re-login** após a 1ª instalação (grupos kvm)

## Troubleshooting

| Problema | Ação |
|----------|------|
| Emulador lento / “software” GPU | Confirmar KVM (`kvm-ok`), usuário no grupo `kvm`, re-login |
| Studio consome muita RAM | Feche o emulador ao editar, ou use VS Code/Cursor + `flutter run` |
| Link 404 do Android Studio | Atualize `ANDROID_STUDIO_VERSION` no script (veja [developer.android.com/studio](https://developer.android.com/studio)) |
| Licenças Android | `flutter doctor --android-licenses` (responda `y`) |
| Sem espaço em disco | Apague `~/.cache/saicc-install` após instalar; use `--skip-studio` se já houver IDE |

## Relação com o mini-curso

Código do app: [`../../todo_app/`](../../todo_app/)  
Roteiro hands-on: [`../../docs/hands-on.md`](../../docs/hands-on.md)

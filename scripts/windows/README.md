# Setup do laboratório — Windows 10/11

Equivalente Windows de [`../linux/install-lab.sh`](../linux/install-lab.sh). Prepara os PCs com Flutter, Android Studio enxuto, SDK API 36 e um AVD leve.

## O que é instalado

| Componente | Detalhe |
|------------|---------|
| Dependências | Git (só instala se ainda não existir), long paths, modo de desenvolvedor, JDK 17 se o Studio for pulado |
| Aceleração | Windows Hypervisor Platform + Virtual Machine Platform (no lugar do KVM) |
| Flutter | Canal stable (versão pinada no script) |
| Android Studio | Zip oficial + `studio64.exe.vmoptions` com heap ~1.5 GB |
| Android SDK | platform-tools, **build-tools 28.0.3**, **platform API 36**, emulator |
| AVD | `SAICC_API36` — 1.5 GB RAM, 2 cores, GPU host, sem SD card |
| Licenças | `sdkmanager --licenses` + `flutter doctor --android-licenses` |
| VS Code | `Dart-Code.dart` e `Dart-Code.flutter` (instala o VS Code via winget se faltar) |

## Requisitos

- Windows 10 ou 11, 64 bits
- PowerShell 5.1 (já vem no Windows)
- `winget` (App Installer)
- Ideal: **≥ 8 GB RAM**, virtualização ligada no BIOS (**VT-x / AMD-V**)
- Disco livre: **~15–20 GB**
- Conta com permissão de administrador

## Uso

O script **exige Administrador**. Sem isso, ele encerra e mostra como rodar de novo.

PowerShell → botão direito → **Executar como administrador**:

```powershell
cd C:\caminho\para\flutter_intro
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\lab\windows\install-lab.ps1
```

Instalação compartilhada (recomendado no lab), em `C:\SAICC`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\lab\windows\install-lab.ps1 -System
```

Ou dê dois cliques em `install-lab.cmd` **como administrador** (ele recusa se não estiver elevado).

Depois, abra um **novo** terminal:

```powershell
flutter doctor -v
saicc-emulator
flutter run
```

Se o hypervisor acabou de ser ligado, **reinicie** o PC antes de abrir o emulador.

### Onde cada modo grava

| | Usuário (padrão) | `-System` |
|--|------------------|-----------|
| Flutter / Studio | `%LOCALAPPDATA%\saicc-dev` | `C:\SAICC` |
| Android SDK | `%LOCALAPPDATA%\Android\Sdk` | `C:\SAICC\Android\Sdk` |
| Variáveis | usuário atual | máquina (todos os logins) |
| Atalho | área de trabalho do usuário | área de trabalho pública |

No modo `-System`, o grupo Usuários recebe permissão de escrita em `C:\SAICC` (o Flutter precisa gravar cache).

## Flags

```powershell
.\install-lab.ps1 -SkipStudio       # só Flutter + SDK + AVD
.\install-lab.ps1 -SkipEmulator     # sem imagem/AVD
.\install-lab.ps1 -SkipHypervisor   # não mexe no WHPX
.\install-lab.ps1 -SkipVSCode       # sem extensões
.\install-lab.ps1 -Help
```

Variáveis (mesmo nome do script Linux):

```powershell
$env:FLUTTER_VERSION = '3.47.7'
$env:ANDROID_STUDIO_VERSION = '2024.3.2.14'
$env:ANDROID_API = '36'
$env:BUILD_TOOLS = '28.0.3'
.\install-lab.ps1 -System
```

## Emulador

`saicc-emulator` (instalado no PATH) sobe o AVD com:

- `-no-audio`
- `-no-boot-anim`
- `-gpu host`
- 1536 MB RAM, 2 núcleos

Equivalente manual: [`start-emulator.ps1`](start-emulator.ps1).

Se a GPU falhar no lab, edite o `.cmd` e troque `-gpu host` por `-gpu angle_indirect`.

## Conferência

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\lab\windows\verify-lab.ps1
```

## Troubleshooting

| Problema | Ação |
|----------|------|
| "precisa ser executado como Administrador" | Reabra o PowerShell com Executar como administrador |
| Emulador lento | Confirme WHPX em "Ativar ou desativar recursos do Windows" e reinicie |
| `Flutter requires Android SDK 36` | Rode de novo o instalador (ele instala `platforms;android-36` e `build-tools;28.0.3`) |
| Licenças pendentes | `flutter doctor --android-licenses` |
| Link 404 do Android Studio | Atualize `ANDROID_STUDIO_VERSION` |
| `winget` ausente | Instale o App Installer pela Microsoft Store |

## Relação com o mini-curso

Código do app: [`../../../todo_app/`](../../../todo_app/)  
Roteiro: [`../../../docs/hands-on.md`](../../../docs/hands-on.md)

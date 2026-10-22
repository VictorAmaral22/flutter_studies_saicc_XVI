# Flutter — instalação das dependências

Scripts para instalar o **Flutter** e o toolchain necessário para compilar apps. O repositório não contém o material do curso.

| Sistema | Script | O que instala |
|---------|--------|----------------|
| Windows 10/11 | [`scripts/windows/install-lab.ps1`](scripts/windows/install-lab.ps1) | Git (se faltar), Flutter, Android Studio enxuto, Android SDK 36, BuildTools 28.0.3, AVD, extensões Dart/Flutter no VS Code |
| Ubuntu 22.04 | [`scripts/linux/install-lab.sh`](scripts/linux/install-lab.sh) | Flutter, Android Studio, Android SDK, AVD, KVM, extensões do VS Code |
| macOS | [`scripts/macos/install-lab.sh`](scripts/macos/install-lab.sh) | Flutter, Android Studio, Android SDK, AVD, extensões do VS Code |

Windows e Linux exigem administrador (`PowerShell como administrador` / `sudo`). A flag de instalação compartilhada é `-System` no Windows e `--system` no Linux e no macOS.

Repositório: <https://github.com/mathyc0de/flutter_intro>

---

## Instalação direta pela web

Os comandos baixam o branch `main`, extraem e executam o instalador. Rode em um terminal **com privilégio de administrador**.

### Windows

PowerShell como administrador:

```powershell
iex (irm https://raw.githubusercontent.com/mathyc0de/flutter_intro/main/scripts/windows/install-web.ps1)
```

Isso instala em `C:\SAICC` (`-System`). Sem a flag compartilhada, use o script local descrito abaixo.

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/mathyc0de/flutter_intro/main/scripts/linux/install-web.sh | sudo bash
```

Equivalente no macOS, trocando o caminho por `scripts/macos/install-web.sh`.

---

## Instalação a partir do clone

```bash
git clone https://github.com/mathyc0de/flutter_intro.git
cd flutter_intro
```

### Windows

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\install-lab.ps1 -System
```

### Linux

```bash
sudo ./scripts/linux/install-lab.sh --system
```

### macOS

```bash
sudo ./scripts/macos/install-lab.sh --system
```

No Apple Silicon a imagem do emulador é `arm64-v8a`. No Intel, `x86_64`.

---

## Depois de instalar

Abra um terminal novo:

```bash
flutter doctor -v
```

No Windows e no Linux com emulador:

```bash
saicc-emulator
```

Detalhes de cada sistema:

- [Windows](scripts/windows/README.md)
- [Linux](scripts/linux/README.md)
- [macOS](scripts/macos/README.md)

## Licença

Veja [LICENSE](LICENSE).

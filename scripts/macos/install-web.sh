#!/usr/bin/env bash
# Baixa este repositório e executa o instalador macOS em modo compartilhado.
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Execute com sudo:" >&2
  echo "  curl -fsSL https://raw.githubusercontent.com/mathyc0de/flutter_intro/main/scripts/macos/install-web.sh | sudo bash" >&2
  exit 1
fi
if [[ -z "${SUDO_USER:-}" || "$SUDO_USER" == "root" ]]; then
  echo "Use sudo a partir de um usuário comum, não como root puro." >&2
  exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "Baixando flutter_intro (main)..."
curl -fsSL "https://github.com/mathyc0de/flutter_intro/archive/refs/heads/main.tar.gz" | tar -xz -C "$workdir"

installer="${workdir}/flutter_intro-main/scripts/macos/install-lab.sh"
if [[ ! -f "$installer" ]]; then
  echo "Instalador não encontrado em ${installer}" >&2
  exit 1
fi

bash "$installer" --system

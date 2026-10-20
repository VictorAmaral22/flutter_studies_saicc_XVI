#!/usr/bin/env bash
# =============================================================================
# SAICC XVI — Instalação Flutter + Android Studio (Ubuntu 22.04 · laboratório)
# =============================================================================
# Instala e configura, de forma idempotente:
#   - Dependências do sistema + KVM (aceleração do emulador)
#   - Flutter SDK (stable)
#   - Android Studio (tarball oficial, perfil de memória reduzido)
#   - Android SDK mínimo (platform-tools, build-tools, platform API 36, emulator)
#   - AVD leve (API 36, google_apis x86_64, 1.5 GB RAM, 2 cores, GPU host)
#   - Extensões Flutter + Dart no VS Code
#   - Aceite automático das licenças Android (sdkmanager + flutter doctor)
#
# Uso (sudo obrigatório):
#   chmod +x scripts/lab/install-lab.sh
#   sudo ./scripts/lab/install-lab.sh              # instalação no $HOME do usuário
#   sudo ./scripts/lab/install-lab.sh --system     # instalação compartilhada em /opt
#
# Variáveis úteis:
#   INSTALL_MODE=user|system
#   FLUTTER_VERSION=3.47.7
#   ANDROID_STUDIO_VERSION=2024.3.2.14
#   ANDROID_API=36
#   BUILD_TOOLS=28.0.3
#   SKIP_ANDROID_STUDIO=1
#   SKIP_EMULATOR=1
#   SKIP_KVM=1
#   SKIP_VSCODE=1
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/configs"

# ---- Versões (podem ser sobrescritas) ---------------------------------------
FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.7}"
# Android Studio Meerkat Feature Drop — ajuste se o link 404
ANDROID_STUDIO_VERSION="${ANDROID_STUDIO_VERSION:-2024.3.2.14}"
CMDLINE_TOOLS_ZIP="${CMDLINE_TOOLS_ZIP:-commandlinetools-linux-13114758_latest.zip}"
# Flutter doctor exige platforms;android-36 e build-tools;28.0.3
ANDROID_API="${ANDROID_API:-36}"
BUILD_TOOLS="${BUILD_TOOLS:-28.0.3}"
AVD_NAME="${AVD_NAME:-SAICC_API36}"
SYSTEM_IMAGE="${SYSTEM_IMAGE:-system-images;android-${ANDROID_API};google_apis;x86_64}"
VSCODE_FLUTTER_EXT="${VSCODE_FLUTTER_EXT:-Dart-Code.flutter}"
VSCODE_DART_EXT="${VSCODE_DART_EXT:-Dart-Code.dart}"

INSTALL_MODE="${INSTALL_MODE:-user}"
SKIP_ANDROID_STUDIO="${SKIP_ANDROID_STUDIO:-0}"
SKIP_EMULATOR="${SKIP_EMULATOR:-0}"
SKIP_KVM="${SKIP_KVM:-0}"
SKIP_VSCODE="${SKIP_VSCODE:-0}"

for arg in "$@"; do
  case "$arg" in
    --system) INSTALL_MODE=system ;;
    --user) INSTALL_MODE=user ;;
    --skip-studio) SKIP_ANDROID_STUDIO=1 ;;
    --skip-emulator) SKIP_EMULATOR=1 ;;
    --skip-kvm) SKIP_KVM=1 ;;
    --skip-vscode) SKIP_VSCODE=1 ;;
    -h|--help)
      sed -n '2,40p' "$0"
      exit 0
      ;;
    *)
      echo "Argumento desconhecido: $arg" >&2
      exit 1
      ;;
  esac
done

# ---- Root obrigatório -------------------------------------------------------
if [[ "$(id -u)" -ne 0 ]]; then
  echo "Este script precisa ser executado com sudo." >&2
  echo "  sudo $0 $*" >&2
  exit 1
fi
if [[ -z "${SUDO_USER:-}" || "$SUDO_USER" == "root" ]]; then
  echo "Execute com sudo a partir de um usuário comum do lab (não como root puro)." >&2
  echo "  sudo -u <usuario> não é necessário — use: sudo $0" >&2
  echo "Exemplo: sudo ./scripts/lab/install-lab.sh --system" >&2
  exit 1
fi

# ---- Cores / log ------------------------------------------------------------
if [[ -t 1 ]]; then
  C_BLUE='\033[1;34m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'
  C_RED='\033[1;31m'; C_RESET='\033[0m'
else
  C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_RESET=''
fi

log()  { echo -e "${C_BLUE}==>${C_RESET} $*"; }
ok()   { echo -e "${C_GREEN}✓${C_RESET} $*"; }
warn() { echo -e "${C_YELLOW}!${C_RESET} $*"; }
err()  { echo -e "${C_RED}✗${C_RESET} $*" >&2; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Comando obrigatório não encontrado: $1"; exit 1; }
}

# ---- Paths ------------------------------------------------------------------
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
if [[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]]; then
  REAL_HOME="$HOME"
fi

if [[ "$INSTALL_MODE" == "system" ]]; then
  if [[ "$(id -u)" -ne 0 ]]; then
    err "Modo --system exige root (sudo)."
    exit 1
  fi
  OPT_ROOT="/opt/saicc"
  FLUTTER_HOME="${OPT_ROOT}/flutter"
  ANDROID_STUDIO_HOME="${OPT_ROOT}/android-studio"
  ANDROID_SDK_ROOT="${OPT_ROOT}/Android/Sdk"
  ENV_FILE="/etc/profile.d/saicc-flutter.sh"
  DOWNLOAD_DIR="/var/tmp/saicc-install"
  SHARE_GROUP="${SHARE_GROUP:-saicc}"
else
  if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
    warn "Rodando com sudo em modo user — instalando no home de ${REAL_USER}."
  fi
  OPT_ROOT="${REAL_HOME}/saicc-dev"
  FLUTTER_HOME="${OPT_ROOT}/flutter"
  ANDROID_STUDIO_HOME="${OPT_ROOT}/android-studio"
  ANDROID_SDK_ROOT="${REAL_HOME}/Android/Sdk"
  ENV_FILE="${REAL_HOME}/.saicc-flutter-env.sh"
  DOWNLOAD_DIR="${REAL_HOME}/.cache/saicc-install"
fi

JAVA_HOME_CANDIDATE="/usr/lib/jvm/java-17-openjdk-amd64"
mkdir -p "$DOWNLOAD_DIR" "$OPT_ROOT"

# ---- Pré-checagens ----------------------------------------------------------
need_cmd curl
need_cmd tar
need_cmd unzip
need_cmd xz

if [[ "$(uname -m)" != "x86_64" ]]; then
  err "Este script foi feito para x86_64 (emulador Android)."
  exit 1
fi

. /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
  warn "SO detectado: ${ID:-desconhecido}. Testado em Ubuntu 22.04."
fi
if [[ "${VERSION_ID:-}" != "22.04" ]]; then
  warn "Versão ${VERSION_ID:-?} — otimizado para 22.04; continue com cuidado."
fi

run_as_user() {
  if [[ "$(id -u)" -eq 0 && "$INSTALL_MODE" == "user" ]]; then
    sudo -u "$REAL_USER" -- "$@"
  elif [[ "$(id -u)" -eq 0 && "$INSTALL_MODE" == "system" && -n "${SUDO_USER:-}" ]]; then
    # Em system, alguns passos (AVD) ficam no home do usuário do lab
    sudo -u "$REAL_USER" -- "$@"
  else
    "$@"
  fi
}

apt_install() {
  log "Instalando pacotes apt..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y --no-install-recommends \
    curl wget unzip xz-utils zip git ca-certificates \
    openjdk-17-jdk \
    libglu1-mesa \
    clang cmake ninja-build pkg-config libgtk-3-dev \
    libstdc++6 lib32z1 mesa-utils \
    || apt-get install -y --no-install-recommends \
      curl wget unzip xz-utils zip git ca-certificates \
      openjdk-17-jdk libglu1-mesa clang cmake ninja-build \
      pkg-config libgtk-3-dev mesa-utils

  if [[ "$SKIP_KVM" != "1" ]]; then
    apt-get install -y --no-install-recommends \
      qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils \
      cpu-checker || warn "Falha ao instalar pacotes KVM (seguindo)."
  fi
  ok "Pacotes apt instalados"
}

ensure_kvm() {
  if [[ "$SKIP_KVM" == "1" ]]; then
    warn "KVM ignorado (--skip-kvm)."
    return 0
  fi

  log "Configurando KVM (aceleração do emulador)..."
  if command -v kvm-ok >/dev/null 2>&1; then
    if kvm-ok 2>/dev/null | grep -qi "can be used"; then
      ok "Virtualização / KVM disponível"
    else
      warn "kvm-ok não confirmou KVM. Emulador pode ficar lento."
      warn "No BIOS/UEFI: habilite VT-x/AMD-V. Em VMs: nested virtualization."
    fi
  fi

  if getent group kvm >/dev/null 2>&1; then
    usermod -aG kvm "$REAL_USER" 2>/dev/null || true
    usermod -aG libvirt "$REAL_USER" 2>/dev/null || true
    ok "Usuário ${REAL_USER} adicionado aos grupos kvm/libvirt (re-login necessário)"
  fi
}

ensure_share_group() {
  [[ "$INSTALL_MODE" == "system" ]] || return 0
  if ! getent group "$SHARE_GROUP" >/dev/null; then
    groupadd --system "$SHARE_GROUP"
  fi
  usermod -aG "$SHARE_GROUP" "$REAL_USER" 2>/dev/null || true
  chown -R root:"$SHARE_GROUP" "$OPT_ROOT"
  chmod -R g+rwX "$OPT_ROOT"
  find "$OPT_ROOT" -type d -exec chmod g+s {} +
  ok "Permissões de grupo '${SHARE_GROUP}' em ${OPT_ROOT}"
}

write_env_file() {
  log "Escrevendo variáveis de ambiente em ${ENV_FILE}"
  cat > "$ENV_FILE" <<EOF
# Gerado por SAICC XVI install-lab.sh — $(date -Iseconds)
export JAVA_HOME="${JAVA_HOME_CANDIDATE}"
export FLUTTER_HOME="${FLUTTER_HOME}"
export ANDROID_STUDIO_HOME="${ANDROID_STUDIO_HOME}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}"
export ANDROID_HOME="\${ANDROID_SDK_ROOT}"
export PATH="\${FLUTTER_HOME}/bin:\${ANDROID_STUDIO_HOME}/bin:\${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:\${ANDROID_SDK_ROOT}/platform-tools:\${ANDROID_SDK_ROOT}/emulator:\${JAVA_HOME}/bin:\${PATH}"
EOF
  chmod 644 "$ENV_FILE"

  if [[ "$INSTALL_MODE" == "user" ]]; then
    local bashrc="${REAL_HOME}/.bashrc"
    local marker="# >>> saicc-flutter >>>"
    if [[ -f "$bashrc" ]] && ! grep -qF "$marker" "$bashrc"; then
      cat >> "$bashrc" <<EOF

${marker}
[[ -f "${ENV_FILE}" ]] && source "${ENV_FILE}"
# <<< saicc-flutter <<<
EOF
      # Ajuste dono se rodou via sudo
      chown "$REAL_USER":"$REAL_USER" "$bashrc" "$ENV_FILE" 2>/dev/null || true
    fi
  fi
  ok "Ambiente configurado"
}

download() {
  local url="$1" dest="$2"
  if [[ -f "$dest" ]]; then
    ok "Já baixado: $(basename "$dest")"
    return 0
  fi
  log "Baixando $(basename "$dest")..."
  curl -fL --retry 3 --retry-delay 2 -o "${dest}.partial" "$url"
  mv "${dest}.partial" "$dest"
}

install_flutter() {
  log "Instalando Flutter ${FLUTTER_VERSION}..."
  local archive="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  local url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${archive}"
  local tarball="${DOWNLOAD_DIR}/${archive}"

  if [[ -x "${FLUTTER_HOME}/bin/flutter" ]]; then
    ok "Flutter já presente em ${FLUTTER_HOME}"
  else
    download "$url" "$tarball"
    rm -rf "${FLUTTER_HOME}"
    mkdir -p "$(dirname "$FLUTTER_HOME")"
    tar -xJf "$tarball" -C "$(dirname "$FLUTTER_HOME")"
    # O tarball extrai para "flutter/"
    if [[ "$(dirname "$FLUTTER_HOME")/flutter" != "$FLUTTER_HOME" ]]; then
      mv "$(dirname "$FLUTTER_HOME")/flutter" "$FLUTTER_HOME"
    fi
  fi

  if [[ "$INSTALL_MODE" == "system" ]]; then
    chown -R root:"$SHARE_GROUP" "$FLUTTER_HOME"
    chmod -R g+rwX "$FLUTTER_HOME"
  elif [[ "$(id -u)" -eq 0 ]]; then
    chown -R "$REAL_USER":"$REAL_USER" "$FLUTTER_HOME"
  fi

  # Prefetch para evitar download na 1ª execução do aluno
  run_as_user env \
    HOME="$REAL_HOME" \
    PATH="${FLUTTER_HOME}/bin:$PATH" \
    flutter precache --android || warn "flutter precache falhou (pode rodar depois)"

  ok "Flutter OK"
}

install_android_studio() {
  if [[ "$SKIP_ANDROID_STUDIO" == "1" ]]; then
    warn "Android Studio ignorado."
    return 0
  fi

  log "Instalando Android Studio ${ANDROID_STUDIO_VERSION} (otimizado)..."
  local archive="android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz"
  local url="https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${ANDROID_STUDIO_VERSION}/${archive}"
  local tarball="${DOWNLOAD_DIR}/${archive}"

  if [[ -x "${ANDROID_STUDIO_HOME}/bin/studio.sh" ]]; then
    ok "Android Studio já presente em ${ANDROID_STUDIO_HOME}"
  else
    download "$url" "$tarball"
    rm -rf "${ANDROID_STUDIO_HOME}"
    local extract_tmp="${DOWNLOAD_DIR}/studio-extract"
    rm -rf "$extract_tmp"
    mkdir -p "$extract_tmp"
    tar -xzf "$tarball" -C "$extract_tmp"
    mv "$extract_tmp"/android-studio "$ANDROID_STUDIO_HOME"
    rm -rf "$extract_tmp"
  fi

  # Perfil de memória / propriedades para lab
  if [[ -f "${CONFIG_DIR}/studio64.vmoptions" ]]; then
    cp "${CONFIG_DIR}/studio64.vmoptions" "${ANDROID_STUDIO_HOME}/bin/studio64.vmoptions"
    ok "studio64.vmoptions (heap ~1.5 GB) aplicado"
  fi
  if [[ -f "${CONFIG_DIR}/idea.properties" ]]; then
    # Anexa sem sobrescrever defaults críticos
    if ! grep -q "SAICC lab properties" "${ANDROID_STUDIO_HOME}/bin/idea.properties" 2>/dev/null; then
      {
        echo ""
        echo "# SAICC lab properties"
        cat "${CONFIG_DIR}/idea.properties"
      } >> "${ANDROID_STUDIO_HOME}/bin/idea.properties"
    fi
    ok "idea.properties de laboratório aplicado"
  fi

  # Desabilita plugins pesados / pouco úteis no mini-curso (se existirem)
  local disable_dir="${ANDROID_STUDIO_HOME}/plugins"
  local heavy_plugins=(
    "android-ndk-support"
    "c-plugin"
    "hpp"
    "cidr-debugger"
  )
  for p in "${heavy_plugins[@]}"; do
    if [[ -d "${disable_dir}/${p}" ]]; then
      mv "${disable_dir}/${p}" "${disable_dir}/${p}.disabled" 2>/dev/null || true
    fi
  done

  # Launcher .desktop
  local apps_dir
  if [[ "$INSTALL_MODE" == "system" ]]; then
    apps_dir="/usr/share/applications"
  else
    apps_dir="${REAL_HOME}/.local/share/applications"
    mkdir -p "$apps_dir"
  fi
  cat > "${apps_dir}/saicc-android-studio.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Android Studio (SAICC)
Comment=Android Studio otimizado para laboratório
Exec=${ANDROID_STUDIO_HOME}/bin/studio.sh
Icon=${ANDROID_STUDIO_HOME}/bin/studio.png
Terminal=false
Categories=Development;IDE;
StartupWMClass=jetbrains-studio
EOF
  if [[ "$INSTALL_MODE" == "user" && "$(id -u)" -eq 0 ]]; then
    chown -R "$REAL_USER":"$REAL_USER" "$ANDROID_STUDIO_HOME" "$apps_dir" 2>/dev/null || true
  fi

  ok "Android Studio OK"
}

install_android_sdk() {
  log "Instalando Android SDK mínimo em ${ANDROID_SDK_ROOT}..."
  mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools"
  export JAVA_HOME="${JAVA_HOME_CANDIDATE}"
  export ANDROID_SDK_ROOT ANDROID_HOME="$ANDROID_SDK_ROOT"

  local zip_path="${DOWNLOAD_DIR}/${CMDLINE_TOOLS_ZIP}"
  local url="https://dl.google.com/android/repository/${CMDLINE_TOOLS_ZIP}"

  if [[ ! -x "${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager" ]]; then
    download "$url" "$zip_path"
    local tmp="${DOWNLOAD_DIR}/cmdline-tools-unpack"
    rm -rf "$tmp"
    mkdir -p "$tmp"
    unzip -q "$zip_path" -d "$tmp"
    rm -rf "${ANDROID_SDK_ROOT}/cmdline-tools/latest"
    mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools"
    mv "$tmp/cmdline-tools" "${ANDROID_SDK_ROOT}/cmdline-tools/latest"
    rm -rf "$tmp"
  fi

  local SDKMANAGER="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager"
  # Flutter exige platforms;android-36 e build-tools;28.0.3 (mensagem do doctor).
  local packages=(
    "cmdline-tools;latest"
    "platform-tools"
    "emulator"
    "platforms;android-${ANDROID_API}"
    "build-tools;${BUILD_TOOLS}"
  )

  if [[ "$SKIP_EMULATOR" != "1" ]]; then
    packages+=("${SYSTEM_IMAGE}")
  fi

  yes | "$SDKMANAGER" --sdk_root="${ANDROID_SDK_ROOT}" --licenses >/dev/null || true
  log "Instalando pacotes SDK: ${packages[*]}"
  "$SDKMANAGER" --sdk_root="${ANDROID_SDK_ROOT}" --install "${packages[@]}"

  # Aceitar licenças de novo após install
  yes | "$SDKMANAGER" --sdk_root="${ANDROID_SDK_ROOT}" --licenses >/dev/null || true

  if [[ "$INSTALL_MODE" == "system" ]]; then
    chown -R root:"$SHARE_GROUP" "$ANDROID_SDK_ROOT"
    chmod -R g+rwX "$ANDROID_SDK_ROOT"
  elif [[ "$(id -u)" -eq 0 ]]; then
    chown -R "$REAL_USER":"$REAL_USER" "$ANDROID_SDK_ROOT"
  fi

  ok "Android SDK OK"
}

create_avd() {
  if [[ "$SKIP_EMULATOR" == "1" ]]; then
    warn "AVD/emulador ignorado."
    return 0
  fi

  log "Criando AVD otimizado '${AVD_NAME}'..."
  export JAVA_HOME="${JAVA_HOME_CANDIDATE}"
  export ANDROID_SDK_ROOT ANDROID_HOME="$ANDROID_SDK_ROOT"
  local AVDMANAGER="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/avdmanager"
  local AVD_DIR="${REAL_HOME}/.android/avd/${AVD_NAME}.avd"

  # AVD fica no home do usuário (padrão Android)
  if run_as_user env HOME="$REAL_HOME" ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
      "$AVDMANAGER" list avd 2>/dev/null | grep -q "Name: ${AVD_NAME}"; then
    ok "AVD ${AVD_NAME} já existe"
  else
    echo no | run_as_user env HOME="$REAL_HOME" ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
      "$AVDMANAGER" create avd \
        --name "$AVD_NAME" \
        --package "$SYSTEM_IMAGE" \
        --device "pixel_5" \
        --force
    ok "AVD criado"
  fi

  # Aplica perfil leve
  if [[ -f "${AVD_DIR}/config.ini" ]]; then
    apply_avd_tweaks "${AVD_DIR}/config.ini"
    ok "Tweaks de desempenho aplicados ao AVD"
  else
    warn "config.ini do AVD não encontrado em ${AVD_DIR}"
  fi

  # Helper no PATH do usuário
  local helper_src="${SCRIPT_DIR}/start-emulator.sh"
  local helper_dst
  if [[ "$INSTALL_MODE" == "system" ]]; then
    helper_dst="/usr/local/bin/saicc-emulator"
    cp "$helper_src" "$helper_dst"
    chmod 755 "$helper_dst"
  else
    helper_dst="${REAL_HOME}/.local/bin/saicc-emulator"
    mkdir -p "$(dirname "$helper_dst")"
    cp "$helper_src" "$helper_dst"
    chmod 755 "$helper_dst"
    [[ "$(id -u)" -eq 0 ]] && chown "$REAL_USER":"$REAL_USER" "$helper_dst" || true
  fi
  ok "Comando 'saicc-emulator' instalado"
}

apply_avd_tweaks() {
  local ini="$1"
  set_ini() {
    local key="$1" value="$2"
    if grep -q "^${key}=" "$ini"; then
      sed -i "s|^${key}=.*|${key}=${value}|" "$ini"
    else
      echo "${key}=${value}" >> "$ini"
    fi
  }
  set_ini hw.ramSize 1536
  set_ini hw.heapSize 256
  set_ini hw.cpu.ncore 2
  set_ini hw.gpu.enabled yes
  set_ini hw.gpu.mode host
  set_ini hw.keyboard yes
  set_ini hw.sdCard no
  set_ini disk.dataPartition.size 2048M
  set_ini vm.heapSize 256
  set_ini fastboot.forceColdBoot no
  set_ini fastboot.forceFastBoot yes
  set_ini showDeviceFrame no
}

accept_android_licenses() {
  log "Aceitando licenças Android (sdkmanager + flutter doctor)..."
  export JAVA_HOME="${JAVA_HOME_CANDIDATE}"
  export ANDROID_SDK_ROOT ANDROID_HOME="$ANDROID_SDK_ROOT"

  local sdkmanager="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager"
  local flutter_bin="${FLUTTER_HOME}/bin/flutter"
  local licenses_log="${DOWNLOAD_DIR}/android-licenses.log"
  mkdir -p "$DOWNLOAD_DIR"

  if [[ -x "$sdkmanager" ]]; then
    # Primeiro aceite via sdkmanager (cobre pacotes do SDK)
    set +o pipefail
    yes 2>/dev/null | "$sdkmanager" --sdk_root="${ANDROID_SDK_ROOT}" --licenses \
      >"$licenses_log" 2>&1 || true
    set -o pipefail
  else
    warn "sdkmanager não encontrado; tentando só via flutter doctor"
  fi

  # Aceite via flutter doctor (é o que o doctor valida depois)
  set +o pipefail
  yes 2>/dev/null | run_as_user env HOME="$REAL_HOME" \
    JAVA_HOME="$JAVA_HOME" \
    PATH="${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${PATH}" \
    ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
    ANDROID_HOME="$ANDROID_SDK_ROOT" \
    "$flutter_bin" doctor --android-licenses \
    >>"$licenses_log" 2>&1 || true
  set -o pipefail

  # Verificação: doctor não deve pedir licenças pendentes
  local doctor_out
  doctor_out="$(
    run_as_user env HOME="$REAL_HOME" \
      JAVA_HOME="$JAVA_HOME" \
      PATH="${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}" \
      ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
      ANDROID_HOME="$ANDROID_SDK_ROOT" \
      "$flutter_bin" doctor 2>&1 || true
  )"

  if echo "$doctor_out" | grep -Eiq 'license.*(not accepted|pending|agree)|Android license status unknown'; then
    warn "Ainda há licenças pendentes. Log: ${licenses_log}"
    warn "Tente manualmente: yes | flutter doctor --android-licenses"
  elif echo "$doctor_out" | grep -Eiq 'All SDK package licenses accepted|\[✓\].*Android toolchain'; then
    ok "Licenças Android aceitas"
  else
    # Sem mensagem explícita de falha — trate como ok (SDK pode estar parcial)
    ok "Licenças Android processadas (veja ${licenses_log} se necessário)"
  fi
}

find_code_cli() {
  # Retorna o binário do VS Code disponível (stdout), ou vazio.
  local candidates=()
  if command -v code >/dev/null 2>&1; then
    candidates+=("$(command -v code)")
  fi
  # Caminhos comuns no Ubuntu / Snap / .deb Microsoft
  candidates+=(
    "/usr/bin/code"
    "/usr/share/code/bin/code"
    "/snap/bin/code"
    "${REAL_HOME}/.local/bin/code"
  )

  local c
  for c in "${candidates[@]}"; do
    if [[ -x "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

install_vscode_extensions() {
  if [[ "$SKIP_VSCODE" == "1" ]]; then
    warn "Extensões VS Code ignoradas (--skip-vscode)."
    return 0
  fi

  log "Instalando extensões Flutter/Dart no VS Code..."

  local code_bin
  if ! code_bin="$(find_code_cli)"; then
    warn "VS Code (comando 'code') não encontrado — extensões não instaladas."
    warn "Instale o VS Code e rode de novo, ou:"
    warn "  code --install-extension ${VSCODE_DART_EXT} --force"
    warn "  code --install-extension ${VSCODE_FLUTTER_EXT} --force"
    return 0
  fi

  # Extensões ficam no home do usuário do lab
  run_as_user env HOME="$REAL_HOME" \
    "$code_bin" --install-extension "$VSCODE_DART_EXT" --force
  run_as_user env HOME="$REAL_HOME" \
    "$code_bin" --install-extension "$VSCODE_FLUTTER_EXT" --force

  local listed
  listed="$(run_as_user env HOME="$REAL_HOME" "$code_bin" --list-extensions 2>/dev/null || true)"
  if echo "$listed" | grep -qx "$VSCODE_FLUTTER_EXT"; then
    ok "VS Code: ${VSCODE_FLUTTER_EXT} (+ ${VSCODE_DART_EXT}) instalada(s) via ${code_bin}"
  else
    warn "Não confirmei a extensão Flutter em --list-extensions; verifique o VS Code."
  fi
}

configure_flutter() {
  log "Configurando Flutter (SDK / Studio / licenças)..."
  export JAVA_HOME="${JAVA_HOME_CANDIDATE}"
  # shellcheck disable=SC1090
  source "$ENV_FILE"

  run_as_user env HOME="$REAL_HOME" \
    JAVA_HOME="$JAVA_HOME" \
    PATH="${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${PATH}" \
    ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
    ANDROID_HOME="$ANDROID_SDK_ROOT" \
    flutter config --android-sdk "$ANDROID_SDK_ROOT" >/dev/null

  if [[ "$SKIP_ANDROID_STUDIO" != "1" && -d "$ANDROID_STUDIO_HOME" ]]; then
    run_as_user env HOME="$REAL_HOME" \
      PATH="${FLUTTER_HOME}/bin:${PATH}" \
      flutter config --android-studio-dir "$ANDROID_STUDIO_HOME" >/dev/null
  fi

  accept_android_licenses
  ok "Flutter configurado"
}

print_summary() {
  echo
  echo "============================================================"
  echo " Instalação SAICC concluída"
  echo "============================================================"
  echo " Flutter:        ${FLUTTER_HOME}"
  echo " Android Studio: ${ANDROID_STUDIO_HOME}"
  echo " Android SDK:    ${ANDROID_SDK_ROOT}"
  echo " AVD:            ${AVD_NAME}"
  echo " Env file:       ${ENV_FILE}"
  echo " VS Code ext:    ${VSCODE_FLUTTER_EXT} (+ ${VSCODE_DART_EXT})"
  echo
  echo " Próximos passos (em cada sessão / após re-login):"
  if [[ "$INSTALL_MODE" == "system" ]]; then
    echo "   source /etc/profile.d/saicc-flutter.sh"
    echo "   # ou abra um novo terminal (e re-login por causa do grupo kvm)"
  else
    echo "   source ${ENV_FILE}"
    echo "   # ou abra um novo terminal"
  fi
  echo
  echo "   flutter doctor -v"
  echo "   saicc-emulator &          # sobe o AVD leve"
  echo "   code todo_app             # VS Code com extensão Flutter"
  echo "   flutter run"
  echo
  echo " Dicas de lab:"
  echo "   - Prefira saicc-emulator (sem áudio / sem boot anim / GPU host)"
  echo "   - Feche o emulador entre turmas para liberar RAM"
  echo "   - Se o Studio estiver pesado, use VS Code + extensão Flutter"
  echo "============================================================"

  run_as_user env HOME="$REAL_HOME" \
    PATH="${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}" \
    ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
    ANDROID_HOME="$ANDROID_SDK_ROOT" \
    JAVA_HOME="$JAVA_HOME_CANDIDATE" \
    flutter doctor || true
}

# ---- Main -------------------------------------------------------------------
main() {
  log "Modo: ${INSTALL_MODE} | usuário: ${REAL_USER} | Ubuntu setup SAICC XVI (sudo)"

  apt_install
  ensure_kvm
  write_env_file
  install_flutter
  install_android_studio
  install_android_sdk
  create_avd
  if [[ "$INSTALL_MODE" == "system" ]]; then
    ensure_share_group
  fi
  configure_flutter
  install_vscode_extensions
  print_summary
}

main "$@"

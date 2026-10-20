#!/usr/bin/env bash
# =============================================================================
# SAICC XVI — Instalação Flutter + Android Studio (macOS · laboratório)
# =============================================================================
# Instala e configura, de forma idempotente:
#   - Git (Command Line Tools) e checagem do Hypervisor.framework (HVF)
#   - Flutter SDK (stable, Intel ou Apple Silicon)
#   - Android Studio (zip oficial, heap ~1.5 GB)
#   - Android SDK: platform-tools, platforms;android-36, build-tools;28.0.3, emulator
#   - AVD leve SAICC_API36 (1.5 GB RAM, 2 cores, GPU host)
#   - Extensões Flutter + Dart no VS Code
#   - Aceite das licenças Android (sdkmanager + flutter doctor)
#
# Uso (sudo obrigatório):
#   chmod +x scripts/macos/install-lab.sh
#   sudo ./scripts/macos/install-lab.sh              # no $HOME de quem chamou o sudo
#   sudo ./scripts/macos/install-lab.sh --system     # compartilhado em /opt/saicc
#
# Variáveis úteis:
#   INSTALL_MODE=user|system
#   FLUTTER_VERSION=3.47.7
#   ANDROID_STUDIO_VERSION=2024.3.2.14
#   ANDROID_API=36
#   BUILD_TOOLS=28.0.3
#   SKIP_ANDROID_STUDIO=1
#   SKIP_EMULATOR=1
#   SKIP_HYPERVISOR=1
#   SKIP_VSCODE=1
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../linux/configs"

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.7}"
ANDROID_STUDIO_VERSION="${ANDROID_STUDIO_VERSION:-2024.3.2.14}"
CMDLINE_TOOLS_ZIP="${CMDLINE_TOOLS_ZIP:-commandlinetools-mac-13114758_latest.zip}"
ANDROID_API="${ANDROID_API:-36}"
BUILD_TOOLS="${BUILD_TOOLS:-28.0.3}"
AVD_NAME="${AVD_NAME:-SAICC_API${ANDROID_API}}"
VSCODE_FLUTTER_EXT="${VSCODE_FLUTTER_EXT:-Dart-Code.flutter}"
VSCODE_DART_EXT="${VSCODE_DART_EXT:-Dart-Code.dart}"

INSTALL_MODE="${INSTALL_MODE:-user}"
SKIP_ANDROID_STUDIO="${SKIP_ANDROID_STUDIO:-0}"
SKIP_EMULATOR="${SKIP_EMULATOR:-0}"
SKIP_HYPERVISOR="${SKIP_HYPERVISOR:-${SKIP_KVM:-0}}"
SKIP_VSCODE="${SKIP_VSCODE:-0}"

for arg in "$@"; do
  case "$arg" in
    --system) INSTALL_MODE=system ;;
    --user) INSTALL_MODE=user ;;
    --skip-studio) SKIP_ANDROID_STUDIO=1 ;;
    --skip-emulator) SKIP_EMULATOR=1 ;;
    --skip-hypervisor|--skip-kvm) SKIP_HYPERVISOR=1 ;;
    --skip-vscode) SKIP_VSCODE=1 ;;
    -h|--help)
      sed -n '2,36p' "$0"
      exit 0
      ;;
    *)
      echo "Argumento desconhecido: $arg" >&2
      exit 1
      ;;
  esac
done

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Este script precisa ser executado com sudo." >&2
  echo "  sudo $0 $*" >&2
  exit 1
fi
if [[ -z "${SUDO_USER:-}" || "$SUDO_USER" == "root" ]]; then
  echo "Execute com sudo a partir de um usuário comum do lab (não como root puro)." >&2
  echo "Exemplo: sudo ./scripts/macos/install-lab.sh --system" >&2
  exit 1
fi

if [[ -t 1 ]]; then
  C_BLUE=$'\033[1;34m'; C_GREEN=$'\033[1;32m'; C_YELLOW=$'\033[1;33m'
  C_RED=$'\033[1;31m'; C_RESET=$'\033[0m'
else
  C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_RESET=''
fi

log()  { echo "${C_BLUE}==>${C_RESET} $*"; }
ok()   { echo "${C_GREEN}OK${C_RESET}  $*"; }
warn() { echo "${C_YELLOW}!${C_RESET}   $*"; }
err()  { echo "${C_RED}X${C_RESET}   $*" >&2; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  err "Este script é para macOS."
  exit 1
fi

ARCH="$(uname -m)"
case "$ARCH" in
  arm64)
    FLUTTER_ARCHIVE="flutter_macos_arm64_${FLUTTER_VERSION}-stable.zip"
    STUDIO_ZIP="android-studio-${ANDROID_STUDIO_VERSION}-mac_arm.zip"
    IMAGE_ABI="arm64-v8a"
    VSCODE_OS="darwin-arm64"
    TEMURIN_ARCH="aarch64"
    ;;
  x86_64)
    FLUTTER_ARCHIVE="flutter_macos_${FLUTTER_VERSION}-stable.zip"
    STUDIO_ZIP="android-studio-${ANDROID_STUDIO_VERSION}-mac.zip"
    IMAGE_ABI="x86_64"
    VSCODE_OS="darwin"
    TEMURIN_ARCH="x64"
    ;;
  *)
    err "Arquitetura não suportada: $ARCH"
    exit 1
    ;;
esac
SYSTEM_IMAGE="${SYSTEM_IMAGE:-system-images;android-${ANDROID_API};google_apis;${IMAGE_ABI}}"

REAL_USER="$SUDO_USER"
REAL_HOME="$(sudo -u "$REAL_USER" -H /bin/bash -c 'printf %s "$HOME"')"
if [[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]]; then
  err "Não achei o home de ${REAL_USER}."
  exit 1
fi

if [[ "$INSTALL_MODE" == "system" ]]; then
  OPT_ROOT="/opt/saicc"
  FLUTTER_HOME="${OPT_ROOT}/flutter"
  ANDROID_STUDIO_HOME="/Applications/Android Studio.app"
  ANDROID_SDK_ROOT="${OPT_ROOT}/Android/Sdk"
  ENV_FILE="/etc/saicc/flutter-env.sh"
  DOWNLOAD_DIR="${OPT_ROOT}/cache"
  LAUNCHER_DIR="/usr/local/bin"
else
  OPT_ROOT="${REAL_HOME}/saicc-dev"
  FLUTTER_HOME="${OPT_ROOT}/flutter"
  ANDROID_STUDIO_HOME="${REAL_HOME}/Applications/Android Studio.app"
  ANDROID_SDK_ROOT="${REAL_HOME}/Android/Sdk"
  ENV_FILE="${REAL_HOME}/.saicc-flutter-env.sh"
  DOWNLOAD_DIR="${REAL_HOME}/Library/Caches/saicc-install"
  LAUNCHER_DIR="${REAL_HOME}/.local/bin"
fi

JAVA_HOME_CANDIDATE=""
mkdir -p "$DOWNLOAD_DIR" "$OPT_ROOT" "$LAUNCHER_DIR"

run_as_user() {
  sudo -u "$REAL_USER" -H -- "$@"
}

agree() {
  local i
  for i in $(seq 1 160); do echo y; done
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

own_user_tree() {
  local path="$1"
  if [[ "$INSTALL_MODE" == "user" && -e "$path" ]]; then
    chown -R "$REAL_USER":staff "$path"
  fi
}

share_tree() {
  local path="$1"
  [[ "$INSTALL_MODE" == "system" && -e "$path" ]] || return 0
  chgrp -R staff "$path"
  chmod -R g+rwX "$path"
  find "$path" -type d -exec chmod g+s {} +
}

ensure_git() {
  log "Verificando Git / Command Line Tools..."
  if xcode-select -p >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
    ok "Git disponível"
    return 0
  fi
  warn "Command Line Tools ausentes. Abrindo o instalador da Apple..."
  xcode-select --install >/dev/null 2>&1 || true
  err "Conclua a instalação das Command Line Tools e rode este script de novo."
  exit 1
}

ensure_hypervisor() {
  if [[ "$SKIP_HYPERVISOR" == "1" ]]; then
    warn "Checagem de hypervisor ignorada."
    return 0
  fi
  log "Checando Hypervisor.framework (HVF, aceleração do emulador)..."
  local hv
  hv="$(sysctl -n kern.hv_support 2>/dev/null || echo 0)"
  if [[ "$hv" == "1" ]]; then
    ok "HVF disponível"
  else
    warn "kern.hv_support=${hv}. O emulador pode ficar lento."
    warn "Em Mac físico isso deveria estar ligado. Em VM, habilite virtualização aninhada."
  fi
}

install_flutter() {
  log "Instalando Flutter ${FLUTTER_VERSION} (${ARCH})..."
  if [[ -x "${FLUTTER_HOME}/bin/flutter" ]]; then
    ok "Flutter já presente em ${FLUTTER_HOME}"
  else
    local zip="${DOWNLOAD_DIR}/${FLUTTER_ARCHIVE}"
    download "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/${FLUTTER_ARCHIVE}" "$zip"
    rm -rf "$FLUTTER_HOME"
    unzip -q "$zip" -d "$OPT_ROOT"
  fi
  share_tree "$FLUTTER_HOME"
  own_user_tree "$FLUTTER_HOME"
  run_as_user env HOME="$REAL_HOME" PATH="${FLUTTER_HOME}/bin:${PATH}" \
    "${FLUTTER_HOME}/bin/flutter" precache --android || warn "flutter precache falhou (pode rodar depois)"
  ok "Flutter OK"
}

install_android_studio() {
  if [[ "$SKIP_ANDROID_STUDIO" == "1" ]]; then
    warn "Android Studio ignorado."
    return 0
  fi
  log "Instalando Android Studio ${ANDROID_STUDIO_VERSION}..."
  if [[ -d "$ANDROID_STUDIO_HOME" ]]; then
    ok "Android Studio já presente em ${ANDROID_STUDIO_HOME}"
  else
    local zip="${DOWNLOAD_DIR}/${STUDIO_ZIP}"
    local url="https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${ANDROID_STUDIO_VERSION}/${STUDIO_ZIP}"
    download "$url" "$zip"
    local extract="${DOWNLOAD_DIR}/studio-extract"
    rm -rf "$extract"
    mkdir -p "$extract"
    unzip -q "$zip" -d "$extract"
    mkdir -p "$(dirname "$ANDROID_STUDIO_HOME")"
    rm -rf "$ANDROID_STUDIO_HOME"
    mv "$extract/Android Studio.app" "$ANDROID_STUDIO_HOME"
    rm -rf "$extract"
  fi

  local vm_src="${CONFIG_DIR}/studio64.vmoptions"
  local vm_dst="${ANDROID_STUDIO_HOME}/Contents/bin/studio.vmoptions"
  if [[ -f "$vm_src" && -d "${ANDROID_STUDIO_HOME}/Contents/bin" ]]; then
    cp "$vm_src" "$vm_dst"
    ok "studio.vmoptions (heap ~1.5 GB) aplicado"
  fi
  local idea_dst="${ANDROID_STUDIO_HOME}/Contents/bin/idea.properties"
  if [[ -f "${CONFIG_DIR}/idea.properties" && -f "$idea_dst" ]]; then
    if ! grep -q "SAICC lab properties" "$idea_dst"; then
      {
        echo ""
        echo "# SAICC lab properties"
        cat "${CONFIG_DIR}/idea.properties"
      } >> "$idea_dst"
    fi
    ok "idea.properties de laboratório aplicado"
  fi

  local plugins="${ANDROID_STUDIO_HOME}/Contents/plugins"
  local name
  for name in android-ndk-support c-plugin hpp cidr-debugger; do
    if [[ -d "${plugins}/${name}" && ! -d "${plugins}/${name}.disabled" ]]; then
      mv "${plugins}/${name}" "${plugins}/${name}.disabled"
    fi
  done

  local studio_bin="${ANDROID_STUDIO_HOME}/Contents/MacOS/studio"
  if [[ -x "$studio_bin" ]]; then
    ln -sfn "$studio_bin" "${LAUNCHER_DIR}/android-studio"
  fi

  local jbr="${ANDROID_STUDIO_HOME}/Contents/jbr/Contents/Home"
  if [[ -x "${jbr}/bin/java" ]]; then
    JAVA_HOME_CANDIDATE="$jbr"
  fi
  share_tree "$ANDROID_STUDIO_HOME"
  own_user_tree "$ANDROID_STUDIO_HOME"
  ok "Android Studio OK"
}

install_temurin_if_needed() {
  if [[ -n "$JAVA_HOME_CANDIDATE" && -x "${JAVA_HOME_CANDIDATE}/bin/java" ]]; then
    return 0
  fi
  log "JDK do Android Studio ausente — baixando Temurin 17..."
  local dest="${OPT_ROOT}/jdk"
  local tarball="${DOWNLOAD_DIR}/temurin17.tar.gz"
  local url="https://api.adoptium.net/v3/binary/latest/17/ga/mac/${TEMURIN_ARCH}/jdk/hotspot/normal/eclipse?project=jdk"
  download "$url" "$tarball"
  rm -rf "$dest"
  mkdir -p "$dest"
  tar -xzf "$tarball" -C "$dest"
  JAVA_HOME_CANDIDATE="$(find "$dest" -type d -path '*/Contents/Home' | head -n 1)"
  if [[ -z "$JAVA_HOME_CANDIDATE" ]]; then
    err "Não achei o JAVA_HOME do Temurin."
    exit 1
  fi
  share_tree "$dest"
  own_user_tree "$dest"
  ok "JDK em ${JAVA_HOME_CANDIDATE}"
}

install_android_sdk() {
  log "Instalando Android SDK (API ${ANDROID_API}, build-tools ${BUILD_TOOLS})..."
  install_temurin_if_needed
  export JAVA_HOME="$JAVA_HOME_CANDIDATE"
  export ANDROID_SDK_ROOT ANDROID_HOME="$ANDROID_SDK_ROOT"
  mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools"

  local sdkmanager="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager"
  if [[ ! -x "$sdkmanager" ]]; then
    local zip="${DOWNLOAD_DIR}/${CMDLINE_TOOLS_ZIP}"
    download "https://dl.google.com/android/repository/${CMDLINE_TOOLS_ZIP}" "$zip"
    local tmp="${DOWNLOAD_DIR}/cmdline-unpack"
    rm -rf "$tmp"
    mkdir -p "$tmp"
    unzip -q "$zip" -d "$tmp"
    rm -rf "${ANDROID_SDK_ROOT}/cmdline-tools/latest"
    mv "$tmp/cmdline-tools" "${ANDROID_SDK_ROOT}/cmdline-tools/latest"
    rm -rf "$tmp"
  fi

  local packages=(
    "cmdline-tools;latest"
    "platform-tools"
    "emulator"
    "platforms;android-${ANDROID_API}"
    "build-tools;${BUILD_TOOLS}"
  )
  if [[ "$SKIP_EMULATOR" != "1" ]]; then
    packages+=("$SYSTEM_IMAGE")
  fi

  set +o pipefail
  agree | "$sdkmanager" --sdk_root="${ANDROID_SDK_ROOT}" --licenses >/dev/null 2>&1 || true
  set -o pipefail
  log "Instalando pacotes SDK: ${packages[*]}"
  "$sdkmanager" --sdk_root="${ANDROID_SDK_ROOT}" --install "${packages[@]}"
  set +o pipefail
  agree | "$sdkmanager" --sdk_root="${ANDROID_SDK_ROOT}" --licenses >/dev/null 2>&1 || true
  set -o pipefail

  share_tree "$ANDROID_SDK_ROOT"
  own_user_tree "$ANDROID_SDK_ROOT"
  ok "Android SDK OK"
}

set_ini() {
  local ini="$1" key="$2" value="$3"
  if grep -q "^${key}=" "$ini"; then
    sed -i '' "s|^${key}=.*|${key}=${value}|" "$ini"
  else
    echo "${key}=${value}" >> "$ini"
  fi
}

create_avd() {
  if [[ "$SKIP_EMULATOR" == "1" ]]; then
    warn "AVD/emulador ignorado."
    return 0
  fi
  log "Criando AVD otimizado '${AVD_NAME}'..."
  export JAVA_HOME="$JAVA_HOME_CANDIDATE"
  export ANDROID_SDK_ROOT ANDROID_HOME="$ANDROID_SDK_ROOT"
  local avdmanager="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/avdmanager"
  local emulator="${ANDROID_SDK_ROOT}/emulator/emulator"
  local avd_dir="${REAL_HOME}/.android/avd/${AVD_NAME}.avd"

  if [[ ! -x "$emulator" ]]; then
    err "Emulador não encontrado em ${emulator}"
    exit 1
  fi

  if run_as_user env HOME="$REAL_HOME" ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" JAVA_HOME="$JAVA_HOME" \
      "$emulator" -list-avds 2>/dev/null | grep -qx "$AVD_NAME"; then
    ok "AVD ${AVD_NAME} já existe"
  else
    if ! echo no | run_as_user env HOME="$REAL_HOME" ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" JAVA_HOME="$JAVA_HOME" \
        "$avdmanager" create avd --name "$AVD_NAME" --package "$SYSTEM_IMAGE" --device pixel_5 --force; then
      warn "Criação com pixel_5 falhou; tentando sem device..."
      echo no | run_as_user env HOME="$REAL_HOME" ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" JAVA_HOME="$JAVA_HOME" \
        "$avdmanager" create avd --name "$AVD_NAME" --package "$SYSTEM_IMAGE" --force
    fi
    ok "AVD criado"
  fi

  if [[ -f "${avd_dir}/config.ini" ]]; then
    set_ini "${avd_dir}/config.ini" hw.ramSize 1536
    set_ini "${avd_dir}/config.ini" hw.heapSize 256
    set_ini "${avd_dir}/config.ini" hw.cpu.ncore 2
    set_ini "${avd_dir}/config.ini" hw.gpu.enabled yes
    set_ini "${avd_dir}/config.ini" hw.gpu.mode host
    set_ini "${avd_dir}/config.ini" hw.keyboard yes
    set_ini "${avd_dir}/config.ini" hw.sdCard no
    set_ini "${avd_dir}/config.ini" disk.dataPartition.size 2048M
    set_ini "${avd_dir}/config.ini" vm.heapSize 256
    set_ini "${avd_dir}/config.ini" fastboot.forceColdBoot no
    set_ini "${avd_dir}/config.ini" fastboot.forceFastBoot yes
    set_ini "${avd_dir}/config.ini" showDeviceFrame no
    chown "$REAL_USER":staff "${avd_dir}/config.ini" || true
    ok "Tweaks de desempenho aplicados ao AVD"
  else
    warn "config.ini não encontrado em ${avd_dir}"
  fi

  cat > "${LAUNCHER_DIR}/saicc-emulator" <<EOF
#!/bin/bash
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}"
export ANDROID_HOME="${ANDROID_SDK_ROOT}"
export JAVA_HOME="${JAVA_HOME_CANDIDATE}"
exec "\${ANDROID_SDK_ROOT}/emulator/emulator" \\
  -avd ${AVD_NAME} -no-audio -no-boot-anim -gpu host -memory 1536 -cores 2 "\$@"
EOF
  chmod 755 "${LAUNCHER_DIR}/saicc-emulator"
  own_user_tree "${LAUNCHER_DIR}/saicc-emulator"
  ok "Comando saicc-emulator instalado"
}

append_snippet() {
  local file="$1"
  local marker="# >>> saicc-flutter >>>"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if grep -qF "$marker" "$file"; then
    return 0
  fi
  cat >> "$file" <<EOF

${marker}
if [ -f "${ENV_FILE}" ]; then
  . "${ENV_FILE}"
fi
# <<< saicc-flutter <<<
EOF
}

write_env() {
  log "Gravando ambiente em ${ENV_FILE}"
  mkdir -p "$(dirname "$ENV_FILE")"
  cat > "$ENV_FILE" <<EOF
# Gerado por SAICC XVI install-lab.sh (macOS)
export JAVA_HOME="${JAVA_HOME_CANDIDATE}"
export FLUTTER_HOME="${FLUTTER_HOME}"
export ANDROID_STUDIO_HOME="${ANDROID_STUDIO_HOME}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}"
export ANDROID_HOME="\${ANDROID_SDK_ROOT}"
export PATH="${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator:${LAUNCHER_DIR}:\${JAVA_HOME}/bin:\${PATH}"
EOF
  chmod 644 "$ENV_FILE"

  if [[ "$INSTALL_MODE" == "system" ]]; then
    mkdir -p /etc/paths.d
    cat > /etc/paths.d/saicc <<EOF
${FLUTTER_HOME}/bin
${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin
${ANDROID_SDK_ROOT}/platform-tools
${ANDROID_SDK_ROOT}/emulator
${LAUNCHER_DIR}
EOF
    append_snippet /etc/zprofile
    append_snippet /etc/zshrc
    append_snippet /etc/profile
  else
    append_snippet "${REAL_HOME}/.zprofile"
    append_snippet "${REAL_HOME}/.zshrc"
    append_snippet "${REAL_HOME}/.bash_profile"
    chown "$REAL_USER":staff "$ENV_FILE" "${REAL_HOME}/.zprofile" "${REAL_HOME}/.zshrc" "${REAL_HOME}/.bash_profile" 2>/dev/null || true
  fi
  ok "Ambiente configurado"
}

accept_android_licenses() {
  log "Aceitando licenças Android (sdkmanager + flutter doctor)..."
  export JAVA_HOME="$JAVA_HOME_CANDIDATE"
  export ANDROID_SDK_ROOT ANDROID_HOME="$ANDROID_SDK_ROOT"
  local sdkmanager="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager"
  local flutter_bin="${FLUTTER_HOME}/bin/flutter"
  local licenses_log="${DOWNLOAD_DIR}/android-licenses.log"
  local user_path="${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${JAVA_HOME}/bin:${PATH}"

  set +o pipefail
  if [[ -x "$sdkmanager" ]]; then
    agree | "$sdkmanager" --sdk_root="${ANDROID_SDK_ROOT}" --licenses >"$licenses_log" 2>&1 || true
  fi
  agree | run_as_user env HOME="$REAL_HOME" JAVA_HOME="$JAVA_HOME" \
    ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" ANDROID_HOME="$ANDROID_SDK_ROOT" \
    PATH="$user_path" \
    "$flutter_bin" doctor --android-licenses >>"$licenses_log" 2>&1 || true
  set -o pipefail

  local doctor_out
  doctor_out="$(run_as_user env HOME="$REAL_HOME" JAVA_HOME="$JAVA_HOME" \
    ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" ANDROID_HOME="$ANDROID_SDK_ROOT" \
    PATH="$user_path" \
    "$flutter_bin" doctor 2>&1 || true)"
  if echo "$doctor_out" | grep -Eiq 'license.*(not accepted|pending|agree)|Android license status unknown'; then
    warn "Ainda há licenças pendentes. Log: ${licenses_log}"
  elif echo "$doctor_out" | grep -Eiq 'Flutter requires Android SDK'; then
    warn "flutter doctor ainda pede outro SDK/BuildTools."
  else
    ok "Licenças Android processadas"
  fi
}

find_code() {
  if [[ -x /usr/local/bin/code ]]; then
    echo /usr/local/bin/code
    return 0
  fi
  if [[ -x "${LAUNCHER_DIR}/code" ]]; then
    echo "${LAUNCHER_DIR}/code"
    return 0
  fi
  local app="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  if [[ -x "$app" ]]; then
    echo "$app"
    return 0
  fi
  return 1
}

install_vscode() {
  if [[ "$SKIP_VSCODE" == "1" ]]; then
    warn "Extensões VS Code ignoradas."
    return 0
  fi
  log "Instalando VS Code e extensões Flutter/Dart..."
  local code_bin=""
  if ! code_bin="$(find_code)"; then
    local zip="${DOWNLOAD_DIR}/vscode.zip"
    download "https://code.visualstudio.com/sha/download?build=stable&os=${VSCODE_OS}" "$zip"
    local extract="${DOWNLOAD_DIR}/vscode-extract"
    rm -rf "$extract"
    mkdir -p "$extract"
    unzip -q "$zip" -d "$extract"
    rm -rf "/Applications/Visual Studio Code.app"
    mv "$extract/Visual Studio Code.app" "/Applications/Visual Studio Code.app"
    rm -rf "$extract"
    code_bin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    ln -sfn "$code_bin" "${LAUNCHER_DIR}/code"
    code_bin="${LAUNCHER_DIR}/code"
  fi

  run_as_user env HOME="$REAL_HOME" "$code_bin" --install-extension "$VSCODE_DART_EXT" --force
  run_as_user env HOME="$REAL_HOME" "$code_bin" --install-extension "$VSCODE_FLUTTER_EXT" --force
  if run_as_user env HOME="$REAL_HOME" "$code_bin" --list-extensions 2>/dev/null | grep -qx "$VSCODE_FLUTTER_EXT"; then
    ok "VS Code: ${VSCODE_FLUTTER_EXT} (+ ${VSCODE_DART_EXT})"
  else
    warn "Não confirmei a extensão Flutter. Abra o VS Code e confira."
  fi
}

configure_flutter() {
  log "Apontando o Flutter para o SDK e o Android Studio..."
  local flutter_bin="${FLUTTER_HOME}/bin/flutter"
  local user_path="${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${PATH}"
  run_as_user env HOME="$REAL_HOME" PATH="$user_path" \
    "$flutter_bin" config --android-sdk "$ANDROID_SDK_ROOT" >/dev/null
  if [[ "$SKIP_ANDROID_STUDIO" != "1" && -d "$ANDROID_STUDIO_HOME" ]]; then
    run_as_user env HOME="$REAL_HOME" PATH="$user_path" \
      "$flutter_bin" config --android-studio-dir "$ANDROID_STUDIO_HOME" >/dev/null
  fi
  ok "Flutter configurado"
}

print_summary() {
  echo
  echo "============================================================"
  echo " Instalação SAICC (macOS) concluída"
  echo "============================================================"
  echo " Flutter:        ${FLUTTER_HOME}"
  echo " Android Studio: ${ANDROID_STUDIO_HOME}"
  echo " Android SDK:    ${ANDROID_SDK_ROOT}"
  echo " Java:           ${JAVA_HOME_CANDIDATE}"
  echo " AVD:            ${AVD_NAME}  (${SYSTEM_IMAGE})"
  echo " Env file:       ${ENV_FILE}"
  echo
  echo " Abra um NOVO Terminal e rode:"
  echo "   flutter doctor -v"
  echo "   saicc-emulator"
  echo "   flutter run"
  echo "============================================================"
  run_as_user env HOME="$REAL_HOME" \
    PATH="${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${PATH}" \
    ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" ANDROID_HOME="$ANDROID_SDK_ROOT" \
    JAVA_HOME="$JAVA_HOME_CANDIDATE" \
    "${FLUTTER_HOME}/bin/flutter" doctor || true
}

log "Modo: ${INSTALL_MODE} | usuário: ${REAL_USER} | macOS ${ARCH} | SAICC XVI (sudo)"
ensure_git
ensure_hypervisor
install_flutter
install_android_studio
install_android_sdk
create_avd
write_env
configure_flutter
accept_android_licenses
install_vscode
print_summary

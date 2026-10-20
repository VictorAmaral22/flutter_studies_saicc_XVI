#!/usr/bin/env bash
# Verificação rápida pós-instalação (SAICC XVI lab)
set -euo pipefail

C_GREEN='\033[1;32m'; C_RED='\033[1;31m'; C_YELLOW='\033[1;33m'; C_RESET='\033[0m'
pass=0; fail=0; warn=0

check() {
  local name="$1"; shift
  if "$@"; then
    echo -e "${C_GREEN}[OK]${C_RESET} $name"
    pass=$((pass + 1))
  else
    echo -e "${C_RED}[FAIL]${C_RESET} $name"
    fail=$((fail + 1))
  fi
}

soft() {
  local name="$1"; shift
  if "$@"; then
    echo -e "${C_GREEN}[OK]${C_RESET} $name"
    pass=$((pass + 1))
  else
    echo -e "${C_YELLOW}[WARN]${C_RESET} $name"
    warn=$((warn + 1))
  fi
}

echo "=== SAICC lab verify ==="

# Ambiente
for f in "$HOME/.saicc-flutter-env.sh" /etc/profile.d/saicc-flutter.sh; do
  if [[ -f "$f" ]]; then
    # shellcheck disable=SC1090
    source "$f"
    break
  fi
done

check "flutter no PATH" command -v flutter >/dev/null
check "adb no PATH" command -v adb >/dev/null
soft  "Java 17" bash -c 'java -version 2>&1 | grep -q "17\|21\|11"'
soft  "KVM device" test -e /dev/kvm
soft  "usuário no grupo kvm" id -nG | grep -qw kvm
soft  "Android Studio" test -x "${ANDROID_STUDIO_HOME:-/nonexistent}/bin/studio.sh"
soft  "AVD SAICC_API36" bash -c 'command -v emulator >/dev/null && emulator -list-avds 2>/dev/null | grep -qx SAICC_API36'
soft  "saicc-emulator" command -v saicc-emulator >/dev/null
soft  "VS Code CLI (code)" command -v code >/dev/null
soft  "extensão Flutter no VS Code" bash -c 'command -v code >/dev/null && code --list-extensions 2>/dev/null | grep -qx Dart-Code.flutter'

if command -v flutter >/dev/null; then
  echo
  flutter doctor || true
  if flutter doctor 2>&1 | grep -Eiq 'license.*(not accepted|pending|agree)|Android license status unknown'; then
    echo -e "${C_RED}[FAIL]${C_RESET} licenças Android ainda pendentes"
    echo "       Rode: yes | flutter doctor --android-licenses"
    fail=$((fail + 1))
  else
    echo -e "${C_GREEN}[OK]${C_RESET} licenças Android (sem aviso pendente no doctor)"
    pass=$((pass + 1))
  fi
fi

echo
echo "Resultado: ${pass} ok · ${warn} avisos · ${fail} falhas"
[[ "$fail" -eq 0 ]]

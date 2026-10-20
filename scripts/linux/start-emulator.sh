#!/usr/bin/env bash
# Inicia o AVD do laboratório com flags leves.
set -euo pipefail

AVD_NAME="${AVD_NAME:-SAICC_API36}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
EMULATOR_BIN="${ANDROID_SDK_ROOT}/emulator/emulator"

if [[ ! -x "$EMULATOR_BIN" ]]; then
  echo "Emulador não encontrado em: $EMULATOR_BIN" >&2
  echo "Defina ANDROID_SDK_ROOT ou rode o install-lab.sh primeiro." >&2
  exit 1
fi

if ! "$EMULATOR_BIN" -list-avds | grep -qx "$AVD_NAME"; then
  echo "AVD '$AVD_NAME' não existe. Disponíveis:" >&2
  "$EMULATOR_BIN" -list-avds >&2 || true
  exit 1
fi

# -no-audio / -no-boot-anim / -gpu host: menos overhead em lab
# -memory e -cores reforçam o perfil leve mesmo se o AVD for alterado
exec "$EMULATOR_BIN" \
  -avd "$AVD_NAME" \
  -no-audio \
  -no-boot-anim \
  -gpu host \
  -memory 1536 \
  -cores 2 \
  "$@"

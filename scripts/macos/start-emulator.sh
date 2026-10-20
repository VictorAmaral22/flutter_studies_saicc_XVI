#!/usr/bin/env bash
# Inicia o AVD do laboratório com flags leves (macOS).
set -euo pipefail

AVD_NAME="${AVD_NAME:-SAICC_API36}"
if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
  SDK="$ANDROID_SDK_ROOT"
elif [[ -n "${ANDROID_HOME:-}" ]]; then
  SDK="$ANDROID_HOME"
else
  SDK="${HOME}/Android/Sdk"
fi
EMULATOR_BIN="${SDK}/emulator/emulator"

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

exec "$EMULATOR_BIN" \
  -avd "$AVD_NAME" \
  -no-audio \
  -no-boot-anim \
  -gpu host \
  -memory 1536 \
  -cores 2 \
  "$@"

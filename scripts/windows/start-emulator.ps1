#Requires -Version 5.1
# Inicia o AVD do laboratório com flags leves (equivalente a start-emulator.sh).
$ErrorActionPreference = 'Stop'

$AvdName = if ($env:AVD_NAME) { $env:AVD_NAME } else { 'SAICC_API36' }
$Sdk = $env:ANDROID_SDK_ROOT
if (-not $Sdk) { $Sdk = $env:ANDROID_HOME }
if (-not $Sdk) { $Sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }

$Emulator = Join-Path $Sdk 'emulator\emulator.exe'
if (-not (Test-Path -LiteralPath $Emulator)) {
  Write-Error "Emulador não encontrado em: $Emulator. Rode install-lab.ps1 primeiro."
}

$avds = & $Emulator -list-avds
if ($avds -notcontains $AvdName) {
  Write-Host "AVD '$AvdName' não existe. Disponíveis:" -ForegroundColor Yellow
  $avds | ForEach-Object { Write-Host "  $_" }
  exit 1
}

& $Emulator -avd $AvdName -no-audio -no-boot-anim -gpu host -memory 1536 -cores 2 @args
exit $LASTEXITCODE

#Requires -Version 5.1
# Baixa este repositorio e executa o instalador do Windows em modo compartilhado.
$ErrorActionPreference = 'Stop'

$principal = New-Object Security.Principal.WindowsPrincipal(
  [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host 'Abra o PowerShell como Administrador e rode de novo:'
  Write-Host 'iex (irm https://raw.githubusercontent.com/mathyc0de/flutter_intro/main/scripts/windows/install-web.ps1)'
  exit 1
}

$zip = Join-Path $env:TEMP 'flutter_intro.zip'
$root = Join-Path $env:TEMP 'flutter_intro-src'
if (Test-Path $root) { Remove-Item $root -Recurse -Force }
New-Item -ItemType Directory -Path $root | Out-Null

Write-Host 'Baixando flutter_intro (main)...'
Invoke-WebRequest -Uri 'https://github.com/mathyc0de/flutter_intro/archive/refs/heads/main.zip' -OutFile $zip
Expand-Archive -Path $zip -DestinationPath $root -Force

$installer = Join-Path $root 'flutter_intro-main\scripts\windows\install-lab.ps1'
if (-not (Test-Path -LiteralPath $installer)) {
  throw "Instalador nao encontrado em $installer"
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer -System
exit $LASTEXITCODE

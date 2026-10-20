#Requires -Version 5.1
# Verificação rápida pós-instalação (SAICC XVI lab · Windows)
$ErrorActionPreference = 'Continue'
$pass = 0; $fail = 0; $warn = 0

function Refresh-Env {
  $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $user = [Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = "$machine;$user"
  foreach ($name in @('ANDROID_SDK_ROOT', 'ANDROID_HOME', 'JAVA_HOME', 'ANDROID_STUDIO_HOME', 'FLUTTER_HOME')) {
    $value = [Environment]::GetEnvironmentVariable($name, 'Machine')
    if (-not $value) { $value = [Environment]::GetEnvironmentVariable($name, 'User') }
    if ($value) { Set-Item -Path "Env:$name" -Value $value }
  }
}

function Write-Check([string]$Name, [bool]$Ok, [bool]$Soft) {
  if ($Ok) {
    Write-Host "[OK]   $Name" -ForegroundColor Green
    $script:pass++
  } elseif ($Soft) {
    Write-Host "[WARN] $Name" -ForegroundColor Yellow
    $script:warn++
  } else {
    Write-Host "[FAIL] $Name" -ForegroundColor Red
    $script:fail++
  }
}

Refresh-Env
Write-Host '=== SAICC lab verify (Windows) ==='

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
$adb = Get-Command adb -ErrorAction SilentlyContinue
Write-Check 'flutter no PATH' ([bool]$flutter) $false
Write-Check 'adb no PATH' ([bool]$adb) $false

$javaOk = $false
if (Get-Command java -ErrorAction SilentlyContinue) {
  $javaVer = & java -version 2>&1 | Out-String
  $javaOk = $javaVer -match 'version "1[17]|version "21'
}
Write-Check 'Java 17/21' $javaOk $true

$whpxOk = $false
try {
  $whpx = Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -ErrorAction Stop
  $whpxOk = $whpx.State -eq 'Enabled'
} catch {
  $whpxOk = $false
}
Write-Check 'Windows Hypervisor Platform' $whpxOk $true

$studio = Join-Path $env:ANDROID_STUDIO_HOME 'bin\studio64.exe'
Write-Check 'Android Studio' (Test-Path -LiteralPath $studio) $true

$emulator = $null
if ($env:ANDROID_SDK_ROOT) { $emulator = Join-Path $env:ANDROID_SDK_ROOT 'emulator\emulator.exe' }
$avdOk = $false
if ($emulator -and (Test-Path $emulator)) {
  $avds = & $emulator -list-avds 2>$null
  $avdOk = $avds -contains 'SAICC_API36'
}
Write-Check 'AVD SAICC_API36' $avdOk $true
Write-Check 'saicc-emulator' ([bool](Get-Command saicc-emulator -ErrorAction SilentlyContinue)) $true

$code = Get-Command code -ErrorAction SilentlyContinue
Write-Check 'VS Code CLI (code)' ([bool]$code) $true
$extOk = $false
if ($code) {
  $exts = & code --list-extensions 2>$null
  $extOk = $exts -contains 'Dart-Code.flutter'
}
Write-Check 'extensão Flutter no VS Code' $extOk $true

if ($flutter) {
  Write-Host ''
  & flutter doctor
  $doctor = & flutter doctor 2>&1 | Out-String
  if ($doctor -match 'license.*(not accepted|pending|agree)|Android license status unknown') {
    Write-Host '[FAIL] licenças Android ainda pendentes' -ForegroundColor Red
    Write-Host '       Rode: flutter doctor --android-licenses'
    $fail++
  } elseif ($doctor -match 'Flutter requires Android SDK') {
    Write-Host '[FAIL] SDK/BuildTools abaixo do que o Flutter exige' -ForegroundColor Red
    Write-Host '       Esperado: platforms;android-36 e build-tools;28.0.3'
    $fail++
  } else {
    Write-Host '[OK]   licenças Android (sem aviso pendente no doctor)' -ForegroundColor Green
    $pass++
  }
}

Write-Host ''
Write-Host "Resultado: $pass ok · $warn avisos · $fail falhas"
if ($fail -gt 0) { exit 1 }
exit 0

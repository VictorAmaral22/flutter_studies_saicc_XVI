#Requires -Version 5.1
<#
.SYNOPSIS
  SAICC XVI  -  Flutter + Android Studio para laboratório Windows.

.DESCRIPTION
  Equivalente Windows de scripts/lab/install-lab.sh.
  Exige PowerShell como Administrador.

  Instala, de forma idempotente:
    - Git, long paths, Windows Hypervisor Platform (WHPX)
    - Flutter SDK (stable)
    - Android Studio (zip oficial, heap ~1.5 GB)
    - Android SDK: platform-tools, platforms;android-36, build-tools;28.0.3, emulator
    - AVD leve SAICC_API36 (1.5 GB RAM, 2 cores, GPU host)
    - Extensões Dart + Flutter no VS Code
    - Aceite das licenças Android (sdkmanager + flutter doctor)

.EXAMPLE
  # PowerShell como Administrador
  Set-ExecutionPolicy -Scope Process Bypass
  .\scripts\lab\windows\install-lab.ps1              # perfil do usuário atual
  .\scripts\lab\windows\install-lab.ps1 -System      # compartilhado em C:\SAICC

.NOTES
  Variáveis de ambiente (opcionais):
    FLUTTER_VERSION, ANDROID_STUDIO_VERSION, ANDROID_API, BUILD_TOOLS,
    CMDLINE_TOOLS_ZIP, INSTALL_MODE=system,
    SKIP_ANDROID_STUDIO=1, SKIP_EMULATOR=1, SKIP_HYPERVISOR=1, SKIP_VSCODE=1
#>
[CmdletBinding()]
param(
  [switch]$System,
  [switch]$SkipStudio,
  [switch]$SkipEmulator,
  [switch]$SkipHypervisor,
  [switch]$SkipVSCode,
  [switch]$Help
)

$ErrorActionPreference = 'Stop'

function Show-Help {
  Get-Content -LiteralPath $PSCommandPath -TotalCount 32 | ForEach-Object {
    $_ -replace '^<#', '' -replace '^#>', '' -replace '^\s*\.', ''
  }
}

if ($Help) {
  Show-Help
  exit 0
}

function Test-IsAdmin {
  $principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
  )
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
  Write-Host 'Este script precisa ser executado como Administrador.' -ForegroundColor Red
  Write-Host 'Abra o PowerShell com "Executar como administrador" e rode:'
  Write-Host "  powershell -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  if ($System) { Write-Host '  (acrescente -System para instalação em C:\SAICC)' }
  exit 1
}

# ---- Flags (parâmetro ou variável de ambiente, como no script Linux) --------
$InstallSystem = $System.IsPresent -or ($env:INSTALL_MODE -eq 'system')
$DoSkipStudio = $SkipStudio.IsPresent -or ($env:SKIP_ANDROID_STUDIO -eq '1')
$DoSkipEmulator = $SkipEmulator.IsPresent -or ($env:SKIP_EMULATOR -eq '1')
$DoSkipHypervisor = $SkipHypervisor.IsPresent -or ($env:SKIP_HYPERVISOR -eq '1') -or ($env:SKIP_KVM -eq '1')
$DoSkipVSCode = $SkipVSCode.IsPresent -or ($env:SKIP_VSCODE -eq '1')

$FlutterVersion = if ($env:FLUTTER_VERSION) { $env:FLUTTER_VERSION } else { '3.47.7' }
$AndroidStudioVersion = if ($env:ANDROID_STUDIO_VERSION) { $env:ANDROID_STUDIO_VERSION } else { '2024.3.2.14' }
$CmdlineToolsZip = if ($env:CMDLINE_TOOLS_ZIP) { $env:CMDLINE_TOOLS_ZIP } else { 'commandlinetools-win-13114758_latest.zip' }
$AndroidApi = if ($env:ANDROID_API) { $env:ANDROID_API } else { '36' }
$BuildTools = if ($env:BUILD_TOOLS) { $env:BUILD_TOOLS } else { '28.0.3' }
$AvdName = if ($env:AVD_NAME) { $env:AVD_NAME } else { "SAICC_API$AndroidApi" }
$VsCodeFlutterExt = if ($env:VSCODE_FLUTTER_EXT) { $env:VSCODE_FLUTTER_EXT } else { 'Dart-Code.flutter' }
$VsCodeDartExt = if ($env:VSCODE_DART_EXT) { $env:VSCODE_DART_EXT } else { 'Dart-Code.dart' }

$Abi = 'x86_64'
if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
  $Abi = 'arm64-v8a'
}
$SystemImage = if ($env:SYSTEM_IMAGE) {
  $env:SYSTEM_IMAGE
} else {
  "system-images;android-$AndroidApi;google_apis;$Abi"
}

$ScriptDir = Split-Path -Parent $PSCommandPath
$ConfigDir = Join-Path (Split-Path -Parent $ScriptDir) 'configs'
$RebootNeeded = $false

if ($InstallSystem) {
  $OptRoot = 'C:\SAICC'
  $FlutterHome = Join-Path $OptRoot 'flutter'
  $AndroidStudioHome = Join-Path $OptRoot 'android-studio'
  $AndroidSdkRoot = Join-Path $OptRoot 'Android\Sdk'
  $DownloadDir = Join-Path $OptRoot 'cache'
  $LauncherDir = Join-Path $OptRoot 'bin'
  $EnvScope = 'Machine'
} else {
  $OptRoot = Join-Path $env:LOCALAPPDATA 'saicc-dev'
  $FlutterHome = Join-Path $OptRoot 'flutter'
  $AndroidStudioHome = Join-Path $OptRoot 'android-studio'
  $AndroidSdkRoot = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
  $DownloadDir = Join-Path $env:TEMP 'saicc-install'
  $LauncherDir = Join-Path $OptRoot 'bin'
  $EnvScope = 'User'
}

function Write-Log([string]$Message) { Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "OK  $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "!   $Message" -ForegroundColor Yellow }
function Write-Err([string]$Message) { Write-Host "X   $Message" -ForegroundColor Red }

function Refresh-SessionPath {
  $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $user = [Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = "$machine;$user"
}

function Add-PathEntry([string]$Entry, [string]$Scope) {
  if (-not (Test-Path -LiteralPath $Entry)) { return }
  $current = [Environment]::GetEnvironmentVariable('Path', $Scope)
  if (-not $current) { $current = '' }
  $parts = $current -split ';' | Where-Object { $_ -and ($_ -ne $Entry) }
  $updated = (@($Entry) + $parts) -join ';'
  [Environment]::SetEnvironmentVariable('Path', $updated, $Scope)
}

function Set-EnvVar([string]$Name, [string]$Value, [string]$Scope) {
  [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
  Set-Item -Path "Env:$Name" -Value $Value
}

function Publish-EnvChange {
  $signature = @'
using System;
using System.Runtime.InteropServices;
public static class SaiccEnv {
  [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
  public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
'@
  if (-not ('SaiccEnv' -as [type])) { Add-Type -TypeDefinition $signature }
  $result = [UIntPtr]::Zero
  [SaiccEnv]::SendMessageTimeout([IntPtr]0xffff, 0x001A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result) | Out-Null
}

function Save-Download([string]$Url, [string]$Dest) {
  if (Test-Path -LiteralPath $Dest) {
    Write-Ok "Já baixado: $(Split-Path -Leaf $Dest)"
    return
  }
  Write-Log "Baixando $(Split-Path -Leaf $Dest)..."
  $partial = "$Dest.partial"
  & curl.exe -fL --retry 3 --retry-delay 2 -o $partial $Url
  if ($LASTEXITCODE -ne 0) { throw "Falha ao baixar $Url" }
  Move-Item -LiteralPath $partial -Destination $Dest -Force
}

function Invoke-WingetInstall([string]$Id) {
  if ($Id -eq 'Git.Git') {
    $present = Find-Git
    if ($present) {
      Write-Ok "Git ja existe em $present. winget install Git.Git nao sera executado."
      return
    }
  }
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget não encontrado. Instale o 'App Installer' e rode de novo."
  }
  Write-Log "winget install $Id"
  & winget install --id $Id -e --scope machine `
    --accept-package-agreements --accept-source-agreements --disable-interactivity
  $code = $LASTEXITCODE
  # 0 = ok
  # -1978335189 (0x8A15002B) = sem atualizacao aplicavel
  # -1978334975 (0x8A150101) = pacote ja instalado
  $done = @(0, -1978335189, -1978334975)
  if ($done -contains $code) {
    if ($code -ne 0) { Write-Ok "Pacote $Id ja estava instalado. Sem nova instalacao." }
    return
  }
  if ($Id -eq 'Git.Git') {
    throw "winget falhou ao instalar Git (codigo $code)."
  }
  & winget install --id $Id -e --scope machine `
    --accept-package-agreements --accept-source-agreements
  if ($done -notcontains $LASTEXITCODE) {
    throw "winget falhou ao instalar $Id (código $LASTEXITCODE)"
  }
}

function Grant-LabUsers([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return }
  # S-1-5-32-545 = BUILTIN\Users (funciona em Windows pt-BR)
  & icacls.exe $Path /grant '*S-1-5-32-545:(OI)(CI)M' /T /C | Out-Null
}

function Find-Git {
  # Devolve so o caminho, ou $null. Nao escreve mais nada na saida.
  $candidates = @()
  foreach ($root in @(
      "$env:ProgramFiles\Git",
      "$env:LOCALAPPDATA\Programs\Git",
      $(if (${env:ProgramFiles(x86)}) { "${env:ProgramFiles(x86)}\Git" })
    )) {
    if (-not $root) { continue }
    foreach ($rel in @('cmd\git.exe', 'bin\git.exe', 'mingw64\bin\git.exe')) {
      $candidates += (Join-Path $root $rel)
    }
  }

  foreach ($reg in @(
      'HKLM:\SOFTWARE\GitForWindows',
      'HKLM:\SOFTWARE\WOW6432Node\GitForWindows',
      'HKCU:\SOFTWARE\GitForWindows'
    )) {
    try {
      $install = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
      if ($install) {
        $candidates += (Join-Path $install 'cmd\git.exe')
        $candidates += (Join-Path $install 'bin\git.exe')
      }
    } catch {}
  }

  foreach ($uninstallRoot in @(
      'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
      'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
      'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )) {
    if (-not (Test-Path $uninstallRoot)) { continue }
    foreach ($key in (Get-ChildItem $uninstallRoot -ErrorAction SilentlyContinue)) {
      $app = Get-ItemProperty $key.PSPath -ErrorAction SilentlyContinue
      if (-not $app -or ($app.DisplayName -notmatch '^Git( for Windows)?')) { continue }
      if ($app.InstallLocation) {
        $candidates += (Join-Path $app.InstallLocation 'cmd\git.exe')
        $candidates += (Join-Path $app.InstallLocation 'bin\git.exe')
        $candidates += (Join-Path $app.InstallLocation 'mingw64\bin\git.exe')
      }
    }
  }

  foreach ($scope in @('Process', 'Machine', 'User')) {
    $raw = if ($scope -eq 'Process') { $env:Path } else { [Environment]::GetEnvironmentVariable('Path', $scope) }
    if (-not $raw) { continue }
    foreach ($entry in ($raw -split ';')) {
      $dir = $entry.Trim().Trim('"')
      if (-not $dir) { continue }
      try {
        $candidates += (Join-Path $dir 'git.exe')
        $candidates += (Join-Path $dir 'git.cmd')
      } catch {}
    }
  }

  foreach ($item in $candidates) {
    if ($item -and (Test-Path -LiteralPath $item)) { return $item }
  }

  $cmd = Get-Command git -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source -and ($cmd.Source -notmatch 'WindowsApps') -and (Test-Path -LiteralPath $cmd.Source)) {
    return $cmd.Source
  }
  return $null
}

function Install-GitIfMissing {
  $gitExe = Find-Git
  if ($gitExe -and (Test-Path -LiteralPath $gitExe)) {
    Write-Ok "Git ja existe em $gitExe. winget nao sera chamado."
  } else {
    Write-Log 'Git nao encontrado na maquina. Instalando...'
    Invoke-WingetInstall 'Git.Git'
    Refresh-SessionPath
    $gitExe = Find-Git
    if (-not $gitExe) { throw 'Git nao encontrado depois da instalacao.' }
  }
  $gitDir = Split-Path -Parent $gitExe
  $env:Path = $gitDir + ';' + $env:Path
  & $gitExe config --system core.longpaths true
  if ($LASTEXITCODE -ne 0) { Write-Warn 'Nao foi possivel ajustar core.longpaths no Git existente.' }
}

function Install-Prereqs {
  Write-Log 'Dependências (Git, long paths, modo de desenvolvedor)...'
  New-Item -ItemType Directory -Force -Path $DownloadDir, $OptRoot, $LauncherDir | Out-Null

  Install-GitIfMissing

  New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' `
    -Name 'LongPathsEnabled' -PropertyType DWord -Value 1 -Force | Out-Null
  New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' `
    -Name 'AllowDevelopmentWithoutDevLicense' -PropertyType DWord -Value 1 -Force | Out-Null

  if (-not $DoSkipStudio) {
    # JDK só é obrigatório se o Studio (que traz o JBR) for pulado.
  } else {
    Write-Log 'Android Studio ignorado  -  instalando Temurin 17 para o sdkmanager'
    Invoke-WingetInstall 'EclipseAdoptium.Temurin.17.JDK'
  }

  if (-not $DoSkipVSCode) {
    if (-not (Get-Command code -ErrorAction SilentlyContinue) -and -not (Test-Path 'C:\Program Files\Microsoft VS Code\bin\code.cmd')) {
      try {
        Invoke-WingetInstall 'Microsoft.VisualStudioCode'
      } catch {
        Write-Warn "VS Code não instalado via winget: $($_.Exception.Message)"
      }
    }
  }
  Refresh-SessionPath
  Write-Ok 'Dependências OK'
}

function Enable-LabHypervisor {
  if ($DoSkipHypervisor) {
    Write-Warn 'Hypervisor ignorado (-SkipHypervisor).'
    return
  }
  Write-Log 'Habilitando Windows Hypervisor Platform (aceleração do emulador)...'
  foreach ($feature in @('HypervisorPlatform', 'VirtualMachinePlatform')) {
    $current = Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction SilentlyContinue
    if (-not $current) {
      Write-Warn "Recurso opcional não encontrado: $feature"
      continue
    }
    if ($current.State -ne 'Enabled') {
      Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart | Out-Null
      $script:RebootNeeded = $true
      Write-Ok "$feature habilitado (pode exigir reinício)"
    } else {
      Write-Ok "$feature já habilitado"
    }
  }
}

function Install-FlutterSdk {
  Write-Log "Instalando Flutter $FlutterVersion..."
  $flutterBat = Join-Path $FlutterHome 'bin\flutter.bat'
  if (Test-Path -LiteralPath $flutterBat) {
    Write-Ok "Flutter já presente em $FlutterHome"
  } else {
    $archive = "flutter_windows_$FlutterVersion-stable.zip"
    $url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/$archive"
    $zip = Join-Path $DownloadDir $archive
    Save-Download $url $zip
    if (Test-Path -LiteralPath $FlutterHome) { Remove-Item -LiteralPath $FlutterHome -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $OptRoot | Out-Null
    & tar.exe -xf $zip -C $OptRoot
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao extrair o Flutter' }
  }
  Refresh-SessionPath
  $env:Path = "$(Join-Path $FlutterHome 'bin');$env:Path"
  & $flutterBat precache --android
  if ($LASTEXITCODE -ne 0) { Write-Warn 'flutter precache falhou (pode rodar depois)' }
  if ($InstallSystem) { Grant-LabUsers $FlutterHome }
  Write-Ok 'Flutter OK'
}

function Install-AndroidStudio {
  if ($DoSkipStudio) {
    Write-Warn 'Android Studio ignorado.'
    return
  }
  Write-Log "Instalando Android Studio $AndroidStudioVersion..."
  $studioExe = Join-Path $AndroidStudioHome 'bin\studio64.exe'
  if (Test-Path -LiteralPath $studioExe) {
    Write-Ok "Android Studio já presente em $AndroidStudioHome"
  } else {
    $archive = "android-studio-$AndroidStudioVersion-windows.zip"
    $url = "https://redirector.gvt1.com/edgedl/android/studio/ide-zips/$AndroidStudioVersion/$archive"
    $zip = Join-Path $DownloadDir $archive
    Save-Download $url $zip
    $extract = Join-Path $DownloadDir 'studio-extract'
    if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $extract | Out-Null
    & tar.exe -xf $zip -C $extract
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao extrair o Android Studio' }
    if (Test-Path $AndroidStudioHome) { Remove-Item $AndroidStudioHome -Recurse -Force }
    Move-Item (Join-Path $extract 'android-studio') $AndroidStudioHome
    Remove-Item $extract -Recurse -Force
  }

  $vmSrc = Join-Path $ConfigDir 'studio64.vmoptions'
  $vmDst = Join-Path $AndroidStudioHome 'bin\studio64.exe.vmoptions'
  if (Test-Path $vmSrc) {
    Copy-Item $vmSrc $vmDst -Force
    Write-Ok 'studio64.exe.vmoptions (heap ~1.5 GB) aplicado'
  }
  $ideaSrc = Join-Path $ConfigDir 'idea.properties'
  $ideaDst = Join-Path $AndroidStudioHome 'bin\idea.properties'
  if ((Test-Path $ideaSrc) -and (Test-Path $ideaDst)) {
    $existing = Get-Content -Raw -LiteralPath $ideaDst
    if ($existing -notmatch 'SAICC lab properties') {
      Add-Content -LiteralPath $ideaDst -Value "`r`n# SAICC lab properties`r`n$(Get-Content -Raw $ideaSrc)"
    }
    Write-Ok 'idea.properties de laboratório aplicado'
  }

  $plugins = Join-Path $AndroidStudioHome 'plugins'
  foreach ($name in @('android-ndk-support', 'c-plugin', 'hpp', 'cidr-debugger')) {
    $dir = Join-Path $plugins $name
    $disabled = "$dir.disabled"
    if ((Test-Path $dir) -and -not (Test-Path $disabled)) {
      Rename-Item $dir $disabled
    }
  }

  $desktop = if ($InstallSystem) { [Environment]::GetFolderPath('CommonDesktopDirectory') } else { [Environment]::GetFolderPath('Desktop') }
  $shortcutPath = Join-Path $desktop 'Android Studio (SAICC).lnk'
  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut($shortcutPath)
  $shortcut.TargetPath = $studioExe
  $shortcut.WorkingDirectory = Join-Path $AndroidStudioHome 'bin'
  $shortcut.Description = 'Android Studio otimizado para laboratório'
  $shortcut.Save()

  if ($InstallSystem) { Grant-LabUsers $AndroidStudioHome }
  Write-Ok 'Android Studio OK'
}

function Resolve-JavaHome {
  $jbr = Join-Path $AndroidStudioHome 'jbr'
  if (Test-Path (Join-Path $jbr 'bin\java.exe')) { return $jbr }
  $candidates = @(
    'C:\Program Files\Eclipse Adoptium',
    'C:\Program Files\Microsoft',
    'C:\Program Files\Java'
  )
  foreach ($root in $candidates) {
    if (-not (Test-Path $root)) { continue }
    $hit = Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
      Where-Object { Test-Path (Join-Path $_.FullName 'bin\java.exe') } |
      Sort-Object Name -Descending |
      Select-Object -First 1
    if ($hit) { return $hit.FullName }
  }
  return $null
}

function Invoke-AcceptSdkLicenses([string]$SdkManager) {
  $yes = Join-Path $DownloadDir 'yes.txt'
  $lines = 1..120 | ForEach-Object { 'y' }
  Set-Content -LiteralPath $yes -Value $lines -Encoding ascii
  cmd.exe /c "`"$SdkManager`" --sdk_root=`"$AndroidSdkRoot`" --licenses < `"$yes`"" | Out-Null
}

function Install-AndroidSdk {
  Write-Log "Instalando Android SDK (API $AndroidApi, build-tools $BuildTools) em $AndroidSdkRoot..."
  $javaHome = Resolve-JavaHome
  if (-not $javaHome) { throw 'Java não encontrado. Instale o Android Studio ou o Temurin 17.' }
  Set-EnvVar 'JAVA_HOME' $javaHome $EnvScope
  $env:JAVA_HOME = $javaHome

  $latest = Join-Path $AndroidSdkRoot 'cmdline-tools\latest'
  $sdkmanager = Join-Path $latest 'bin\sdkmanager.bat'
  if (-not (Test-Path $sdkmanager)) {
    $url = "https://dl.google.com/android/repository/$CmdlineToolsZip"
    $zip = Join-Path $DownloadDir $CmdlineToolsZip
    Save-Download $url $zip
    $unpack = Join-Path $DownloadDir 'cmdline-unpack'
    if (Test-Path $unpack) { Remove-Item $unpack -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $unpack | Out-Null
    & tar.exe -xf $zip -C $unpack
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao extrair cmdline-tools' }
    New-Item -ItemType Directory -Force -Path (Join-Path $AndroidSdkRoot 'cmdline-tools') | Out-Null
    if (Test-Path $latest) { Remove-Item $latest -Recurse -Force }
    Move-Item (Join-Path $unpack 'cmdline-tools') $latest
    Remove-Item $unpack -Recurse -Force
  }

  $packages = @(
    'cmdline-tools;latest',
    'platform-tools',
    'emulator',
    "platforms;android-$AndroidApi",
    "build-tools;$BuildTools"
  )
  if (-not $DoSkipEmulator) { $packages += $SystemImage }

  Invoke-AcceptSdkLicenses $sdkmanager
  Write-Log "Instalando pacotes SDK: $($packages -join ' ')"
  & $sdkmanager --sdk_root="$AndroidSdkRoot" --install $packages
  if ($LASTEXITCODE -ne 0) { throw "sdkmanager --install falhou (código $LASTEXITCODE)" }
  Invoke-AcceptSdkLicenses $sdkmanager

  if ($InstallSystem) { Grant-LabUsers $AndroidSdkRoot }
  Write-Ok 'Android SDK OK'
}

function Set-AvdIni([string]$Ini, [string]$Key, [string]$Value) {
  $content = @()
  if (Test-Path $Ini) { $content = @(Get-Content -LiteralPath $Ini) }
  $pattern = "^$([regex]::Escape($Key))="
  $found = $false
  $updated = foreach ($line in $content) {
    if ($line -match $pattern) { $found = $true; "$Key=$Value" } else { $line }
  }
  if (-not $found) { $updated += "$Key=$Value" }
  Set-Content -LiteralPath $Ini -Value $updated -Encoding ascii
}

function Install-Avd {
  if ($DoSkipEmulator) {
    Write-Warn 'AVD/emulador ignorado.'
    return
  }
  Write-Log "Criando AVD otimizado '$AvdName'..."
  $env:ANDROID_SDK_ROOT = $AndroidSdkRoot
  $env:ANDROID_HOME = $AndroidSdkRoot
  $avdManager = Join-Path $AndroidSdkRoot 'cmdline-tools\latest\bin\avdmanager.bat'
  $emulator = Join-Path $AndroidSdkRoot 'emulator\emulator.exe'
  if (-not (Test-Path -LiteralPath $emulator)) { throw "Emulador não encontrado em $emulator" }
  $list = @(& $emulator -list-avds 2>$null | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
  if ($list -contains $AvdName) {
    Write-Ok "AVD $AvdName já existe"
  } else {
    $yes = Join-Path $DownloadDir 'no.txt'
    Set-Content -LiteralPath $yes -Value 'no' -Encoding ascii
    cmd.exe /c "`"$avdManager`" create avd --name $AvdName --package `"$SystemImage`" --device pixel_5 --force < `"$yes`""
    if ($LASTEXITCODE -ne 0) {
      Write-Warn 'Criação com device pixel_5 falhou; tentando sem device...'
      cmd.exe /c "`"$avdManager`" create avd --name $AvdName --package `"$SystemImage`" --force < `"$yes`""
      if ($LASTEXITCODE -ne 0) { throw "avdmanager falhou (código $LASTEXITCODE)" }
    }
    Write-Ok 'AVD criado'
  }

  $ini = Join-Path $env:USERPROFILE ".android\avd\$AvdName.avd\config.ini"
  if (Test-Path $ini) {
    Set-AvdIni $ini 'hw.ramSize' '1536'
    Set-AvdIni $ini 'hw.heapSize' '256'
    Set-AvdIni $ini 'hw.cpu.ncore' '2'
    Set-AvdIni $ini 'hw.gpu.enabled' 'yes'
    Set-AvdIni $ini 'hw.gpu.mode' 'host'
    Set-AvdIni $ini 'hw.keyboard' 'yes'
    Set-AvdIni $ini 'hw.sdCard' 'no'
    Set-AvdIni $ini 'disk.dataPartition.size' '2048M'
    Set-AvdIni $ini 'vm.heapSize' '256'
    Set-AvdIni $ini 'fastboot.forceColdBoot' 'no'
    Set-AvdIni $ini 'fastboot.forceFastBoot' 'yes'
    Set-AvdIni $ini 'showDeviceFrame' 'no'
    Write-Ok 'Tweaks de desempenho aplicados ao AVD'
  } else {
    Write-Warn "config.ini não encontrado em $ini"
  }

  $cmdPath = Join-Path $LauncherDir 'saicc-emulator.cmd'
  @"
@echo off
set "ANDROID_SDK_ROOT=$AndroidSdkRoot"
set "ANDROID_HOME=$AndroidSdkRoot"
"%ANDROID_SDK_ROOT%\emulator\emulator.exe" -avd $AvdName -no-audio -no-boot-anim -gpu host -memory 1536 -cores 2 %*
"@ | Set-Content -LiteralPath $cmdPath -Encoding ascii
  Write-Ok "Comando saicc-emulator instalado em $cmdPath"
}

function Accept-AndroidLicenses {
  Write-Log 'Aceitando licenças Android (sdkmanager + flutter doctor)...'
  $flutterBat = Join-Path $FlutterHome 'bin\flutter.bat'
  $sdkmanager = Join-Path $AndroidSdkRoot 'cmdline-tools\latest\bin\sdkmanager.bat'
  $yes = Join-Path $DownloadDir 'yes.txt'
  $lines = 1..160 | ForEach-Object { 'y' }
  Set-Content -LiteralPath $yes -Value $lines -Encoding ascii
  $log = Join-Path $DownloadDir 'android-licenses.log'

  if (Test-Path $sdkmanager) {
    cmd.exe /c "`"$sdkmanager`" --sdk_root=`"$AndroidSdkRoot`" --licenses < `"$yes`" > `"$log`" 2>&1"
  }
  cmd.exe /c "`"$flutterBat`" doctor --android-licenses < `"$yes`" >> `"$log`" 2>&1"

  $doctor = & $flutterBat doctor 2>&1 | Out-String
  if ($doctor -match 'license.*(not accepted|pending|agree)|Android license status unknown') {
    Write-Warn "Ainda há licenças pendentes. Log: $log"
    Write-Warn 'Tente: flutter doctor --android-licenses'
  } elseif ($doctor -match 'Flutter requires Android SDK') {
    Write-Warn 'flutter doctor ainda pede outro SDK/BuildTools. Veja a saída no final.'
  } else {
    Write-Ok 'Licenças Android processadas'
  }
}

function Install-VsCodeExtensions {
  if ($DoSkipVSCode) {
    Write-Warn 'Extensões VS Code ignoradas (-SkipVSCode).'
    return
  }
  Write-Log 'Instalando extensões Flutter/Dart no VS Code...'
  $code = $null
  if (Get-Command code -ErrorAction SilentlyContinue) { $code = (Get-Command code).Source }
  $fallback = 'C:\Program Files\Microsoft VS Code\bin\code.cmd'
  if (-not $code -and (Test-Path $fallback)) { $code = $fallback }
  if (-not $code) {
    Write-Warn 'VS Code (comando code) não encontrado  -  extensões não instaladas.'
    Write-Warn "  code --install-extension $VsCodeDartExt --force"
    Write-Warn "  code --install-extension $VsCodeFlutterExt --force"
    return
  }
  & $code --install-extension $VsCodeDartExt --force
  & $code --install-extension $VsCodeFlutterExt --force
  $listed = & $code --list-extensions 2>$null
  if ($listed -contains $VsCodeFlutterExt) {
    Write-Ok "VS Code: $VsCodeFlutterExt (+ $VsCodeDartExt)"
  } else {
    Write-Warn 'Não confirmei a extensão Flutter em --list-extensions.'
  }
}

function Publish-LabEnv {
  Write-Log "Gravando variáveis de ambiente (escopo $EnvScope)..."
  $javaHome = Resolve-JavaHome
  if ($javaHome) { Set-EnvVar 'JAVA_HOME' $javaHome $EnvScope }
  Set-EnvVar 'FLUTTER_HOME' $FlutterHome $EnvScope
  Set-EnvVar 'ANDROID_STUDIO_HOME' $AndroidStudioHome $EnvScope
  Set-EnvVar 'ANDROID_SDK_ROOT' $AndroidSdkRoot $EnvScope
  Set-EnvVar 'ANDROID_HOME' $AndroidSdkRoot $EnvScope
  foreach ($entry in @(
      (Join-Path $FlutterHome 'bin'),
      (Join-Path $AndroidStudioHome 'bin'),
      (Join-Path $AndroidSdkRoot 'cmdline-tools\latest\bin'),
      (Join-Path $AndroidSdkRoot 'platform-tools'),
      (Join-Path $AndroidSdkRoot 'emulator'),
      $LauncherDir
    )) {
    Add-PathEntry $entry $EnvScope
  }
  Refresh-SessionPath
  Publish-EnvChange
  Write-Ok 'Ambiente configurado'
}

function Show-Summary {
  Write-Host ''
  Write-Host '============================================================'
  Write-Host ' Instalação SAICC (Windows) concluída'
  Write-Host '============================================================'
  Write-Host " Flutter:        $FlutterHome"
  Write-Host " Android Studio: $AndroidStudioHome"
  Write-Host " Android SDK:    $AndroidSdkRoot"
  Write-Host " AVD:            $AvdName  ($SystemImage)"
  Write-Host " Escopo env:     $EnvScope"
  Write-Host " VS Code ext:    $VsCodeFlutterExt (+ $VsCodeDartExt)"
  Write-Host ''
  Write-Host ' Abra um NOVO terminal e rode:'
  Write-Host '   flutter doctor -v'
  Write-Host '   saicc-emulator'
  Write-Host '   flutter run'
  if ($RebootNeeded) {
    Write-Host ''
    Write-Warn 'Reinicie o PC para o Windows Hypervisor Platform valer no emulador.'
  }
  Write-Host '============================================================'
  Write-Host ''
  $flutterBat = Join-Path $FlutterHome 'bin\flutter.bat'
  & $flutterBat doctor
}

Write-Log "Modo: $(if ($InstallSystem) { 'system' } else { 'user' }) | $($env:USERNAME) | Windows setup SAICC XVI (admin)"
Install-Prereqs
Enable-LabHypervisor
Install-FlutterSdk
Install-AndroidStudio
Install-AndroidSdk
Install-Avd
Publish-LabEnv
Accept-AndroidLicenses
Install-VsCodeExtensions
Show-Summary
exit 0

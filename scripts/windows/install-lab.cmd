@echo off
REM Launcher do instalador SAICC (exige Administrador).
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Este script precisa ser executado como Administrador.
  echo Clique com o botao direito no PowerShell ou neste .cmd e escolha "Executar como administrador".
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-lab.ps1" %*
exit /b %errorlevel%

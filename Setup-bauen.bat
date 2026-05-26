@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Smart-OEPNV Planer – Installer bauen
echo.
echo === Erstellt Setup-Smart-OEPNV-Planer-x64.exe in dist\ ===
echo Dauert einige Minuten...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0installer\scripts\Build-Installer.ps1"
echo.
pause

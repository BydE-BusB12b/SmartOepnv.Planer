@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Smart-OEPNV Planer (Schnellstart)
echo.
echo === Smart-OEPNV Planer starten ===

where dotnet >nul 2>&1
if errorlevel 1 (
    echo FEHLER: dotnet SDK nicht gefunden. Bitte .NET 8 SDK installieren.
    pause
    exit /b 1
)

set "EXE=src\SmartOepnv.Planer\bin\Debug\net8.0-windows\Smart-OEPNV-Planer.exe"

echo Beende ggf. laufenden Planer...
taskkill /IM "Smart-OEPNV-Planer.exe" /F >nul 2>&1

echo Baue Debug-Version (immer aktuell)...
dotnet build "src\SmartOepnv.Planer\SmartOepnv.Planer.csproj" -c Debug
if errorlevel 1 (
    echo Build fehlgeschlagen.
    pause
    exit /b 1
)

echo Starte: %EXE%
start "" "%~dp0%EXE%"
echo Planer wurde gestartet.
exit /b 0

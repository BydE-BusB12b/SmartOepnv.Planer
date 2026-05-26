@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Smart-OEPNV Planer – Build + Start
echo.
echo === Baue Release-Version ===
dotnet build "src\SmartOepnv.Planer\SmartOepnv.Planer.csproj" -c Release
if errorlevel 1 (
    echo Build fehlgeschlagen.
    pause
    exit /b 1
)
echo.
echo === Starte EXE ===
start "" "%~dp0src\SmartOepnv.Planer\bin\Release\net8.0-windows\Smart-OEPNV-Planer.exe"
echo Planer gestartet.
timeout /t 3 >nul

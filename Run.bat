@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Smart-OEPNV Planer (Schnellstart)
echo.
echo === Smart-OEPNV Planer starten (dotnet run) ===
echo Kein Installer noetig – ideal zum Testen.
echo.
dotnet run --project "src\SmartOepnv.Planer\SmartOepnv.Planer.csproj"
echo.
if errorlevel 1 (
    echo FEHLER – siehe Meldung oben.
    pause
)

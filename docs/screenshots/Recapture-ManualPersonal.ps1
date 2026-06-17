# Demo-Screenshots fuer Anleitung (Personal, Fahrer- und Fahrzeugdisposition) + PDF.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Capture = Join-Path $PSScriptRoot "Capture-PlanerScreenshots.ps1"
$Demo = Join-Path $PSScriptRoot "Apply-ManualDemoData.ps1"
$Export = Join-Path (Split-Path -Parent $PSScriptRoot) "Export-Anleitung-PDF.ps1"
$Release = Join-Path $Root "tools\ReleasePlanerSession\ReleasePlanerSession.csproj"

cmd /c "taskkill /IM Smart-OEPNV-Planer.exe /F >nul 2>&1"
& $Demo -Action apply
dotnet run --project $Release -c Release -v q | Out-Null
& $Capture -Only @(
    "07-personalverwaltung",
    "08-fahrerdisposition",
    "09-fahrzeugdisposition",
    "10-fahrzeugverwaltung"
)
& $Demo -Action restore
& $Export

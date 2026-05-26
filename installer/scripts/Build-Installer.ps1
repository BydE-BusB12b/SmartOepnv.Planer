# Erstellt Setup-Smart-OEPNV-Planer-x64.exe (klassischer Windows-Installationsassistent)
# Voraussetzung auf dem Entwicklungs-PC: .NET 8 SDK + Inno Setup 6

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$Project = Join-Path $Root "src\SmartOepnv.Planer\SmartOepnv.Planer.csproj"
$PublishDir = Join-Path $Root "publish\win-x64"
$IssFile = Join-Path $Root "installer\SmartOepnv.Planer.iss"
$DistDir = Join-Path $Root "dist"
$PlanerIcon = Join-Path $Root "installer\assets\planer.ico"

Write-Host "=== Smart-OEPNV Planer: Installer-Build ===" -ForegroundColor Cyan

# App-Icon erzeugen (falls fehlt)
if (-not (Test-Path $PlanerIcon)) {
    Write-Host "Erzeuge Planer-Icon aus PNG..." -ForegroundColor Yellow
    $planerPng = Join-Path $Root "installer\assets\planer-512.png"
    if (-not (Test-Path $planerPng)) {
        throw "Planer-Icon fehlt: Bitte planer-512.png nach installer\assets\ legen."
    }
    & (Join-Path $Root "installer\scripts\Convert-PngToIco.ps1") -PngPath $planerPng -IcoPath $PlanerIcon
}

# 1. Self-contained Publish (kein .NET beim Kunden noetig)
Write-Host "1/3 dotnet publish (self-contained win-x64)..." -ForegroundColor Yellow
if (Test-Path $PublishDir) {
    Remove-Item $PublishDir -Recurse -Force
}
dotnet publish $Project `
    -c Release `
    -r win-x64 `
    --self-contained true `
    -p:PublishReadyToRun=true `
    -p:PublishTrimmed=false `
    -o $PublishDir
if ($LASTEXITCODE -ne 0) { throw "dotnet publish fehlgeschlagen" }

# 2. Inno Setup finden
$IsccCandidates = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
    (Join-Path $Root "tools\InnoSetup6\ISCC.exe")
)
$Iscc = $IsccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Iscc) {
    Write-Host ""
    Write-Host "Inno Setup 6 nicht gefunden. Installation in tools\InnoSetup6 ..." -ForegroundColor Yellow
    $innoInstaller = Join-Path $env:TEMP "innosetup-6.7.2.exe"
    if (-not (Test-Path $innoInstaller)) {
        Invoke-WebRequest -Uri "https://github.com/jrsoftware/issrc/releases/download/is-6_7_2/innosetup-6.7.2.exe" -OutFile $innoInstaller -UseBasicParsing
    }
    $toolsInno = Join-Path $Root "tools\InnoSetup6"
    New-Item -ItemType Directory -Path $toolsInno -Force | Out-Null
    Start-Process -FilePath $innoInstaller -ArgumentList "/VERYSILENT","/DIR=$toolsInno","/SUPPRESSMSGBOXES","/NORESTART" -Wait
    $Iscc = Join-Path $toolsInno "ISCC.exe"
}
if (-not $Iscc) {
    throw "Inno Setup 6 fehlt. Bitte installieren: https://jrsoftware.org/isdl.php"
}

# 3. Setup.exe bauen
Write-Host "2/3 Inno Setup kompilieren..." -ForegroundColor Yellow
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir | Out-Null
}
& $Iscc $IssFile
if ($LASTEXITCODE -ne 0) { throw "Inno Setup Build fehlgeschlagen" }

$SetupExe = Get-ChildItem $DistDir -Filter "Setup-Smart-OEPNV-Planer-x64*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Write-Host ""
Write-Host "=== FERTIG ===" -ForegroundColor Green
if ($SetupExe) {
    $sizeMb = [math]::Round($SetupExe.Length / 1MB, 1)
    Write-Host "Setup-Datei: $($SetupExe.FullName)" -ForegroundColor White
    Write-Host "Groesse:     $sizeMb MB" -ForegroundColor White
    Write-Host ""
    Write-Host "Der Kunde fuehrt nur diese Setup.exe aus (Assistent inkl. Desktopsymbol)." -ForegroundColor Cyan
}

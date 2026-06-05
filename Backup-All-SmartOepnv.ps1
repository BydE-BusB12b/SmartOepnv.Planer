#Requires -Version 5.1
param(
    [string]$Message = "",
    [switch]$SkipPush,
    [switch]$SkipDataBackup
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Stamp = Get-Date -Format "yyyy-MM-dd_HHmm"
$DataBackupRoot = Join-Path $Root "_Backups\Smart-OEPNV\AppData"

$Repos = @(
    "GPSAnsagen",
    "SmartOepnv.Shared",
    "SmartOepnv.Planer",
    "SmartOepnv.Leitstelle"
)

function Write-Step([string]$Text) {
    Write-Host ""
    Write-Host "==> $Text" -ForegroundColor Cyan
}

if (-not $SkipDataBackup) {
    Write-Step "Benutzerdaten sichern"
    $AppDataRoot = Join-Path $env:APPDATA "Smart-OEPNV"
    foreach ($Profile in @("Planer", "Leitstelle")) {
        $Source = Join-Path $AppDataRoot "$Profile\workspace"
        if (-not (Test-Path $Source)) {
            Write-Host "  Ueberspringe (nicht vorhanden): $Source" -ForegroundColor DarkYellow
            continue
        }
        $Dest = Join-Path $DataBackupRoot "$Profile\backup_$Stamp"
        New-Item -ItemType Directory -Force -Path $Dest | Out-Null
        Copy-Item -Path (Join-Path $Source "*") -Destination $Dest -Recurse -Force
        Write-Host "  OK: $Dest" -ForegroundColor Green
    }
}

Write-Step "Git-Repositories"
$AnyCommit = $false
foreach ($Name in $Repos) {
    $RepoPath = Join-Path $Root $Name
    if (-not (Test-Path (Join-Path $RepoPath ".git"))) {
        Write-Host "  Ueberspringe (kein Git): $Name" -ForegroundColor DarkYellow
        continue
    }

    Push-Location $RepoPath
    try {
        $Status = git status --porcelain
        if ([string]::IsNullOrWhiteSpace($Status)) {
            Write-Host "  $Name : keine Aenderungen" -ForegroundColor DarkGray
            continue
        }

        git add -A
        $CommitMsg = if ($Message) { $Message } else { "Backup $Stamp - Smart-OEPNV" }
        git commit -m $CommitMsg
        Write-Host "  $Name : commit erstellt" -ForegroundColor Green
        $AnyCommit = $true

        if (-not $SkipPush) {
            git push origin HEAD
            Write-Host "  $Name : nach GitHub gepusht" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  $Name : FEHLER - $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

Write-Step "Fertig"
if ($AnyCommit -and $SkipPush) {
    Write-Host "Commits lokal erstellt (Push uebersprungen)." -ForegroundColor Yellow
}
elseif (-not $AnyCommit) {
    Write-Host "Keine Git-Aenderungen - nur Daten-Backup (falls aktiviert)." -ForegroundColor Yellow
}
else {
    Write-Host "Backup abgeschlossen (Daten + GitHub)." -ForegroundColor Green
}

Write-Host ""
Write-Host "Daten-Backup: $DataBackupRoot"
$OverlayPath = Join-Path $env:APPDATA "Smart-OEPNV\Planer\workspace\planner_local_roster.json"
Write-Host "Overlay Planer: $OverlayPath"
$VersionsPath = Join-Path $env:APPDATA "Smart-OEPNV\Planer\workspace\backups"
Write-Host "Versionen:    $VersionsPath"

# Erzeugt dist\Benutzeranleitung-Smart-OEPNV-Planer.pdf aus docs\BENUTZERANLEITUNG.html
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Html = Join-Path $PSScriptRoot "BENUTZERANLEITUNG.html"
$Dist = Join-Path $Root "dist"
$Pdf = Join-Path $Dist "Benutzeranleitung-Smart-OEPNV-Planer.pdf"

if (-not (Test-Path $Html)) { throw "HTML fehlt: $Html" }
New-Item -ItemType Directory -Path $Dist -Force | Out-Null

$uri = "file:///" + ($Html -replace '\\', '/')
$browsers = @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
)
$browser = $browsers | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $browser) { throw "Weder Edge noch Chrome gefunden." }

Remove-Item $Pdf -ErrorAction SilentlyContinue
& $browser --headless=new --disable-gpu --no-pdf-header-footer --print-to-pdf="$Pdf" $uri
Start-Sleep -Seconds 5

if (-not (Test-Path $Pdf)) { throw "PDF-Erstellung fehlgeschlagen." }
$sizeMb = [math]::Round((Get-Item $Pdf).Length / 1MB, 1)
Write-Host "PDF erstellt: $Pdf ($sizeMb MB)" -ForegroundColor Green

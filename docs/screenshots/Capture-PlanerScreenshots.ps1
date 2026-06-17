# Erstellt Screenshots aller Planer-Navigationsbereiche fuer die Benutzeranleitung.
param(
    [string[]]$Only = @()
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -ReferencedAssemblies System.Drawing @"
using System;
using System.Runtime.InteropServices;
using System.Drawing;
using System.Collections.Generic;
public static class WinCapture {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, int dwExtraInfo);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    public const int SW_MAXIMIZE = 3;
    public const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    public const uint MOUSEEVENTF_LEFTUP = 0x0004;
    public static void Click(int x, int y) {
        SetCursorPos(x, y);
        System.Threading.Thread.Sleep(80);
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
    }
    public static List<IntPtr> GetVisibleWindowsForProcess(int pid) {
        var list = new List<IntPtr>();
        EnumWindows((h, _) => {
            uint wpid;
            GetWindowThreadProcessId(h, out wpid);
            if (wpid == pid && IsWindowVisible(h)) list.Add(h);
            return true;
        }, IntPtr.Zero);
        return list;
    }
    public static string GetTitle(IntPtr h) {
        var sb = new System.Text.StringBuilder(512);
        GetWindowText(h, sb, sb.Capacity);
        return sb.ToString();
    }
    public static void CaptureHwnd(IntPtr hwnd, string path, bool maximize = true) {
        ShowWindow(hwnd, maximize ? SW_MAXIMIZE : 5);
        SetForegroundWindow(hwnd);
        System.Threading.Thread.Sleep(800);
        RECT r;
        if (!GetWindowRect(hwnd, out r)) throw new Exception("GetWindowRect failed");
        int w = r.Right - r.Left;
        int h = r.Bottom - r.Top;
        using (var bmp = new Bitmap(w, h)) {
            using (var g = Graphics.FromImage(bmp)) {
                IntPtr hdc = g.GetHdc();
                bool ok = PrintWindow(hwnd, hdc, 2);
                g.ReleaseHdc(hdc);
                if (!ok) g.CopyFromScreen(new Point(r.Left, r.Top), Point.Empty, new Size(w, h));
            }
            bmp.Save(path, System.Drawing.Imaging.ImageFormat.Png);
        }
    }
    public static void CaptureRect(Rectangle rect, string path) {
        using (var bmp = new Bitmap(rect.Width, rect.Height)) {
            using (var g = Graphics.FromImage(bmp)) {
                g.CopyFromScreen(new Point(rect.Left, rect.Top), Point.Empty, rect.Size);
            }
            bmp.Save(path, System.Drawing.Imaging.ImageFormat.Png);
        }
    }
}
"@

$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$OutDir = $PSScriptRoot
$ExeCandidates = @(
    (Join-Path $Root "publish\win-x64\Smart-OEPNV-Planer.exe"),
    (Join-Path $Root "src\SmartOepnv.Planer\bin\Release\net8.0-windows\Smart-OEPNV-Planer.exe"),
    "${env:ProgramFiles}\Smart-OEPNV\Planer\Smart-OEPNV-Planer.exe"
)
$Exe = $ExeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Exe) { throw "Planer-EXE nicht gefunden." }

function Get-PlannerCredential {
    $rosterPath = Join-Path $env:APPDATA "Smart-OEPNV\Planer\workspace\planner_local_roster.json"
    if (-not (Test-Path $rosterPath)) { return $null }
    $json = Get-Content $rosterPath -Raw | ConvertFrom-Json
    foreach ($e in $json.employees) {
        if ($e.plannerLoginEnabled -and $e.plannerUsername -and $e.plannerPassword) {
            return @{ User = [string]$e.plannerUsername; Pass = [string]$e.plannerPassword }
        }
    }
    return $null
}

function Wait-ForMainHandle([System.Diagnostics.Process]$process, [int]$timeoutSec = 60) {
    $deadline = (Get-Date).AddSeconds($timeoutSec)
    while ((Get-Date) -lt $deadline) {
        $process.Refresh()
        if ($process.MainWindowHandle -ne [IntPtr]::Zero) { return $true }
        Start-Sleep -Milliseconds 250
    }
    return $false
}

function Find-MainWindowElement {
    $root = [System.Windows.Automation.AutomationElement]::RootElement
    foreach ($el in $root.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)) {
        $name = $el.Current.Name
        if ($name -like "*Planer*" -and $name -notlike "*Anmeldung*") { return $el }
    }
    return $null
}

$script:ViewMarkers = @{
    ([string][char]0x00DC + "bersicht") = "Daten importieren / exportieren"
    "Routen" = "Route hinzufügen"
    "Haltestellen" = "Alle aus Routen übernehmen"
    "Ansagen" = "Neue Ansage mit Tondatei"
    "Navidaten" = "Haltestellen laden"
    "Personalverwaltung" = "Mitarbeiter hinzufügen"
    "Fahrerdisposition" = "Neuer Dienst"
    "Fahrzeugdisposition" = "Neue Fahrt"
    "Fahrzeugverwaltung" = "Fahrzeug hinzufügen"
    "Dienstvorlagen" = "Fahrplan-Datei öffnen"
    "Vorlagen-Bibliothek" = "Gespeicherte Dienstvorlagen"
    "Nachrichten" = "KOM-Nachrichtenvorlagen"
    "Anzeigen & Hinweise" = "+ DS021T"
    "SEV-Schilder" = "SEV-Schilderstellung"
    "Zeitwirtschaft" = "CSV exportieren"
    "Versand" = "Nach Dropbox senden"
    "Einstellungen" = "Firmenlogos"
}

function Test-NavViewReady([string]$title) {
    if (-not $script:NavIndex.Contains($title)) { return $true }
    $list = Get-NavListElement
    if (-not $list) { return $false }
    $items = $list.FindAll(
        [System.Windows.Automation.TreeScope]::Descendants,
        (New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
            [System.Windows.Automation.ControlType]::ListItem)))
    $index = $script:NavIndex[$title]
    if ($index -ge $items.Count) { return $false }
    try {
        $sel = $items[$index].GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern)
        return $sel.Current.IsSelected
    } catch {
        return $false
    }
}

$script:NavIndex = [ordered]@{
    ([string][char]0x00DC + "bersicht") = 0
    "Routen" = 1
    "Haltestellen" = 2
    "Ansagen" = 3
    "Navidaten" = 4
    "Personalverwaltung" = 5
    "Fahrerdisposition" = 6
    "Fahrzeugdisposition" = 7
    "Fahrzeugverwaltung" = 8
    "Dienstvorlagen" = 9
    "Vorlagen-Bibliothek" = 10
    "Nachrichten" = 11
    "Anzeigen & Hinweise" = 12
    "SEV-Schilder" = 13
    "Zeitwirtschaft" = 14
    "Versand" = 15
    "Einstellungen" = 16
}

function Get-NavListElement {
    $win = Find-MainWindowElement
    if (-not $win) { return $null }
    return $win.FindFirst(
        [System.Windows.Automation.TreeScope]::Descendants,
        (New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
            [System.Windows.Automation.ControlType]::List)))
}

function Click-NavItem([string]$title) {
    if (-not $script:NavIndex.Contains($title)) { throw "Kein Nav-Index fuer '$title'" }
    $index = $script:NavIndex[$title]
    $list = Get-NavListElement
    if (-not $list) { throw "Navigationsliste nicht gefunden" }
    $rect = $list.Current.BoundingRectangle
    [WinCapture]::Click([int]($rect.X + 40), [int]($rect.Y + 40))
    Start-Sleep -Milliseconds 300
    $list.SetFocus()
    Start-Sleep -Milliseconds 200
    [System.Windows.Forms.SendKeys]::SendWait("{HOME}")
    Start-Sleep -Milliseconds 150
    for ($i = 0; $i -lt $index; $i++) {
        [System.Windows.Forms.SendKeys]::SendWait("{DOWN}")
        Start-Sleep -Milliseconds 80
    }
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Seconds 2
}

function Capture-LoginScreenshot([int]$processId, [IntPtr]$mainHwnd, [string]$path) {
    [WinCapture]::SetForegroundWindow($mainHwnd) | Out-Null
    Start-Sleep -Milliseconds 800
    $windows = [WinCapture]::GetVisibleWindowsForProcess($processId)
    $loginHwnd = [IntPtr]::Zero
    foreach ($h in $windows) {
        $title = [WinCapture]::GetTitle($h)
        if ($title -like "*Anmeldung*") { $loginHwnd = $h; break }
    }
    if ($loginHwnd -ne [IntPtr]::Zero) {
        [WinCapture]::CaptureHwnd($loginHwnd, $path, $false)
        return
    }
    $root = [System.Windows.Automation.AutomationElement]::FromHandle($mainHwnd)
    $btn = $root.FindFirst(
        [System.Windows.Automation.TreeScope]::Descendants,
        (New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::NameProperty, "Anmelden")))
    if ($btn) {
        $r = $btn.Current.BoundingRectangle
        $pad = 40
        $dialog = [System.Drawing.Rectangle]::FromLTRB(
            [int]($r.X - 220), [int]($r.Y - 280),
            [int]($r.Right + 40), [int]($r.Bottom + 60))
        [WinCapture]::CaptureRect($dialog, $path)
        return
    }
    [WinCapture]::CaptureHwnd($mainHwnd, $path, $false)
}

function Invoke-PlanerLogin([IntPtr]$hwnd, [string]$user, [string]$pass) {
    [WinCapture]::SetForegroundWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 500
    $root = [System.Windows.Automation.AutomationElement]::FromHandle($hwnd)
    $edits = $root.FindAll(
        [System.Windows.Automation.TreeScope]::Descendants,
        (New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
            [System.Windows.Automation.ControlType]::Edit)))
    if ($edits.Count -lt 2) { throw "Login-Felder nicht gefunden" }
    ($edits[0].GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)).SetValue($user)
    ($edits[1].GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)).SetValue($pass)
    $btnCond = New-Object System.Windows.Automation.AndCondition(
        (New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
            [System.Windows.Automation.ControlType]::Button)),
        (New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::NameProperty, "Anmelden")))
    $btn = $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $btnCond)
    ($btn.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)).Invoke()
}

$navScreens = [ordered]@{
    "01-login" = $null
    "02-hauptfenster-uebersicht" = [string][char]0x00DC + "bersicht"
    "03-routen" = "Routen"
    "04-haltestellen" = "Haltestellen"
    "05-ansagen" = "Ansagen"
    "06-navidaten" = "Navidaten"
    "07-personalverwaltung" = "Personalverwaltung"
    "08-fahrerdisposition" = "Fahrerdisposition"
    "09-fahrzeugdisposition" = "Fahrzeugdisposition"
    "10-fahrzeugverwaltung" = "Fahrzeugverwaltung"
    "11-dienstvorlagen" = "Dienstvorlagen"
    "12-vorlagen-bibliothek" = "Vorlagen-Bibliothek"
    "13-nachrichten" = "Nachrichten"
    "14-anzeigen-hinweise" = "Anzeigen & Hinweise"
    "15-sev-schilder" = "SEV-Schilder"
    "16-zeitwirtschaft" = "Zeitwirtschaft"
    "17-versand" = "Versand"
    "18-einstellungen" = "Einstellungen"
}

Write-Host "Starte Planer: $Exe" -ForegroundColor Cyan
$proc = Start-Process -FilePath $Exe -PassThru
if (-not (Wait-ForMainHandle $proc 60)) { throw "Planer-Fenster nicht gestartet" }

$cred = Get-PlannerCredential
if (-not $cred) { throw "Kein Planer-Zugang gefunden." }

Start-Sleep -Seconds 3
Capture-LoginScreenshot $proc.Id $proc.MainWindowHandle (Join-Path $OutDir "01-login.png")

try {
    Invoke-PlanerLogin $proc.MainWindowHandle $cred.User $cred.Pass
} catch {
    Write-Warning "UIA-Login fehlgeschlagen: $($_.Exception.Message)"
    [System.Windows.Forms.SendKeys]::SendWait($cred.User + "{TAB}" + $cred.Pass + "{ENTER}")
}

Write-Host "Warte auf Sync..." -ForegroundColor Yellow
Start-Sleep -Seconds 15
$deadline = (Get-Date).AddSeconds(90)
while ((Get-Date) -lt $deadline) {
    $dlg = [WinCapture]::GetVisibleWindowsForProcess($proc.Id) | Where-Object {
        [WinCapture]::GetTitle($_) -eq "Smart-ÖPNV Planer"
    }
    if (-not $dlg) { break }
    Start-Sleep -Seconds 1
}

$proc.Refresh()
if ($proc.MainWindowHandle -eq [IntPtr]::Zero) { throw "Hauptfenster nach Login nicht sichtbar" }
Start-Sleep -Seconds 2

foreach ($entry in $navScreens.GetEnumerator()) {
    $file = Join-Path $OutDir ($entry.Key + ".png")
    if ($Only.Count -gt 0 -and ($entry.Key -notin $Only)) { continue }
    if ($entry.Key -eq "01-login") { continue }
    if ($entry.Value) {
        Write-Host "Screenshot: $($entry.Value)" -ForegroundColor Yellow
        Click-NavItem $entry.Value
    }
    $proc.Refresh()
    [WinCapture]::CaptureHwnd($proc.MainWindowHandle, $file, $true)
}

Write-Host "Fertig: $OutDir" -ForegroundColor Green
Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue

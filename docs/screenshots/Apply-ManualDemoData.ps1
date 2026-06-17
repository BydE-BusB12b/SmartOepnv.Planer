# Anonymisierte Demo-Daten fuer Screenshots in der Benutzeranleitung (wird danach wiederhergestellt).
param(
    [ValidateSet("apply", "restore")]
    [string]$Action = "apply"
)

$WorkspaceDir = Join-Path $env:APPDATA "Smart-OEPNV\Planer\workspace"
$RosterPath = Join-Path $WorkspaceDir "planner_local_roster.json"
$WorkspacePath = Join-Path $WorkspaceDir "planer_workspace.json"
$RoutesPath = Join-Path $WorkspaceDir "routes_export.json"
$BackupDir = Join-Path $PSScriptRoot ".manual-demo-backup"
$DemoPhone = "0123456789"

function Set-DemoEmployees($employees) {
    if (-not $employees) { return }
    $names = @("Fahrer 1", "Fahrer 2", "Fahrer 3")
    for ($i = 0; $i -lt [Math]::Min($names.Count, $employees.Count); $i++) {
        $e = $employees[$i]
        $e.name = $names[$i]
        $e.personnelNumber = "1234"
        $e.password = "1234"
        $e.phoneNumber = ""
        if ($e.PSObject.Properties.Name -contains "plannerLoginEnabled") {
            $e.plannerLoginEnabled = ($i -eq 0)
            $e.plannerPassword = if ($i -eq 0) { "4711" } else { "" }
        }
        if ($e.PSObject.Properties.Name -contains "displayLabel") {
            $e.displayLabel = "$($names[$i]) (PN 1234)"
        }
    }
}

function Set-DemoVehicles($vehicles) {
    if (-not $vehicles -or $vehicles.Count -eq 0) { return @() }
    $demoTypes = @("Bus 12 m", "Bus 12 m", "Bus 18 m", "Bus 18 m")
    $sorted = @($vehicles | Sort-Object { $_.name }, { $_.phoneNumber })
    $result = @()
    for ($i = 0; $i -lt [Math]::Min(4, $sorted.Count); $i++) {
        $v = $sorted[$i]
        $name = "Fahrzeug $($i + 1)"
        $v.name = $name
        $v.phoneNumber = $DemoPhone
        if ($v.PSObject.Properties.Name -contains "loadedPhoneNumber") {
            $v.loadedPhoneNumber = $DemoPhone
        }
        if ($v.plannerDetails) {
            $v.plannerDetails.isActive = $true
            $v.plannerDetails.vehicleType = $demoTypes[$i]
            if ($i -eq 0) { $v.plannerDetails.dispoRowColor = "#FFF9C4" }
        }
        if ($v.PSObject.Properties.Name -contains "displayLabel") {
            $v.displayLabel = "$name - $DemoPhone"
        }
        $result += $v
    }
    return $result
}

function Set-DemoRouteVehicles($routes) {
    if (-not $routes) { return }
    if ($routes.registeredVehicles) {
        $routes.registeredVehicles = @(Set-DemoVehicles $routes.registeredVehicles)
    }
    if ($routes.registeredVehiclesPlannerMeta -and $routes.registeredVehicles) {
        $demoTypes = @("Bus 12 m", "Bus 12 m", "Bus 18 m", "Bus 18 m")
        $meta = @()
        for ($i = 0; $i -lt $routes.registeredVehicles.Count; $i++) {
            $existing = $null
            if ($i -lt $routes.registeredVehiclesPlannerMeta.Count) {
                $existing = $routes.registeredVehiclesPlannerMeta[$i]
            }
            $entry = [ordered]@{
                phoneNumber = $DemoPhone
                isActive = $true
                vehicleType = $demoTypes[$i]
            }
            if ($existing) {
                foreach ($prop in $existing.PSObject.Properties) {
                    if ($prop.Name -notin @("phoneNumber", "isActive", "vehicleType")) {
                        $entry[$prop.Name] = $prop.Value
                    }
                }
            }
            $meta += [pscustomobject]$entry
        }
        $routes.registeredVehiclesPlannerMeta = $meta
    }
}

if ($Action -eq "restore") {
    foreach ($name in @("planner_local_roster.json", "planer_workspace.json", "routes_export.json")) {
        $src = Join-Path $BackupDir $name
        $dst = Join-Path $WorkspaceDir $name
        if (Test-Path $src) {
            Copy-Item $src $dst -Force
        }
    }
    Write-Host "Demo-Daten zurueckgesetzt." -ForegroundColor Green
    exit 0
}

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
foreach ($name in @("planner_local_roster.json", "planer_workspace.json", "routes_export.json")) {
    $src = Join-Path $WorkspaceDir $name
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $BackupDir $name) -Force
    }
}

$now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

if (Test-Path $RosterPath) {
    $roster = Get-Content $RosterPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Set-DemoEmployees $roster.employees
    $roster.vehicles = @(Set-DemoVehicles $roster.vehicles)
    $roster.savedAtUtc = $now
    $roster | ConvertTo-Json -Depth 30 | Set-Content $RosterPath -Encoding UTF8
}

if (Test-Path $RoutesPath) {
    $routes = Get-Content $RoutesPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Set-DemoEmployees $routes.employeeRoster
    Set-DemoRouteVehicles $routes
    $routes.timestamp = $now
    $routes | ConvertTo-Json -Depth 30 -Compress | Set-Content $RoutesPath -Encoding UTF8
}

if (Test-Path $WorkspacePath) {
    $ws = Get-Content $WorkspacePath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($ws.plannerOverlay) {
        if ($ws.plannerOverlay.employees) { Set-DemoEmployees $ws.plannerOverlay.employees }
        if ($ws.plannerOverlay.vehicles) {
            $ws.plannerOverlay.vehicles = @(Set-DemoVehicles $ws.plannerOverlay.vehicles)
        }
    }
    if ($ws.routesPackageJson) {
        $pkg = $ws.routesPackageJson | ConvertFrom-Json
        Set-DemoEmployees $pkg.employeeRoster
        Set-DemoRouteVehicles $pkg
        $pkg.timestamp = $now
        $ws.routesPackageJson = ($pkg | ConvertTo-Json -Depth 30 -Compress)
    }
    $ws.savedAtUtcMs = $now
    $ws | ConvertTo-Json -Depth 30 -Compress | Set-Content $WorkspacePath -Encoding UTF8
}

Write-Host "Demo-Fahrer 1-3 und Fahrzeug 1-4 (Tel. $DemoPhone) gesetzt." -ForegroundColor Green

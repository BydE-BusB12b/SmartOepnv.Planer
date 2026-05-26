param(
    [Parameter(Mandatory = $true)]
    [string]$PngPath,
    [Parameter(Mandatory = $true)]
    [string]$IcoPath,
    [int[]]$Sizes = @(16, 32, 48, 256)
)

Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $PngPath)) {
    throw "PNG nicht gefunden: $PngPath"
}

$source = [System.Drawing.Bitmap]::FromFile((Resolve-Path $PngPath))
$icons = New-Object System.Collections.Generic.List[System.Drawing.Icon]

try {
    foreach ($size in $Sizes) {
        $bmp = New-Object System.Drawing.Bitmap $size, $size
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($source, 0, 0, $size, $size)
        $g.Dispose()
        $icons.Add([System.Drawing.Icon]::FromHandle($bmp.GetHicon()))
        $bmp.Dispose()
    }

    $dir = Split-Path -Parent $IcoPath
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    # Kleinste Größe als Basis-Icon speichern (Windows akzeptiert einzelnes ICO)
    $stream = [System.IO.File]::Open($IcoPath, [System.IO.FileMode]::Create)
    $icons[$icons.Count - 1].Save($stream)
    $stream.Close()
}
finally {
    foreach ($icon in $icons) { $icon.Dispose() }
    $source.Dispose()
}

Write-Host "ICO erstellt: $IcoPath"

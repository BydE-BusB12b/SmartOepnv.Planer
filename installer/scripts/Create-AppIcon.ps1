param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

Add-Type -AssemblyName System.Drawing

$size = 256
$bitmap = New-Object System.Drawing.Bitmap $size, $size
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.Color]::FromArgb(255, 13, 71, 161))

$brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 66, 165, 245))
$graphics.FillEllipse($brush, 48, 48, 160, 160)
$graphics.Dispose()
$brush.Dispose()

$icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
$stream = [System.IO.File]::Open($OutputPath, [System.IO.FileMode]::Create)
$icon.Save($stream)
$stream.Close()
$icon.Dispose()
$bitmap.Dispose()

Write-Host "Icon gespeichert: $OutputPath"

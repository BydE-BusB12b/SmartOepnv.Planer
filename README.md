# Smart-ÖPNV Planer

Eigenständiges Windows-Programm zur Verwaltung von Routen, Haltestellen, Ansagen, Navidaten und Versand an GPSAnsagen-Fahrzeuge.

**Gemeinsamer Code:** `..\SmartOepnv.Shared\`  
**Schwesterprodukt:** `..\SmartOepnv.Leitstelle\` (eigener Projektordner)

## Projektstruktur

```
AndroidStudioProjects/
├── SmartOepnv.Shared/      ← Core + gemeinsame UI
├── SmartOepnv.Planer/      ← dieses Programm
└── SmartOepnv.Leitstelle/  ← separates Programm
```

## Schnell testen (ohne Setup.exe)

| Datei | Zweck |
|-------|--------|
| **`Run.bat`** | Programm direkt starten (empfohlen zum Testen) |
| **`Build-und-Starten.bat`** | Release bauen und EXE starten |
| **`Setup-bauen.bat`** | Installer `dist\Setup-....exe` erzeugen |

Zentral für beide Programme: `..\SmartOepnv-Test.bat` oder `SmartOepnv-Test.py`

## Starten

```powershell
cd C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Planer
dotnet run --project src\SmartOepnv.Planer\SmartOepnv.Planer.csproj
```

EXE nach Build:  
`src\SmartOepnv.Planer\bin\Release\net8.0-windows\Smart-OEPNV-Planer.exe`

## Installer

```powershell
powershell -ExecutionPolicy Bypass -File installer\scripts\Build-Installer.ps1
```

Ergebnis: `dist\Setup-Smart-OEPNV-Planer-x64.exe`

## Technik

- .NET 8 WPF, Material Design, MVVM
- Grundfarbe Planer: Dunkelblau
- GPSAnsagen JSON v1.0 (`exportType: routes`)

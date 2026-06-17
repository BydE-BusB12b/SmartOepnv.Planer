# Dokumentation Smart-ÖPNV Planer

## Benutzeranleitung (mit Screenshots)

Öffnen Sie im Browser:

**[BENUTZERANLEITUNG.html](BENUTZERANLEITUNG.html)**

Die Anleitung enthält alle Navigationsbereiche mit Erklärungen und Screenshots.  
Als PDF: im Browser `Strg+P` → „Als PDF speichern“ – oder fertige Datei:

`dist\Benutzeranleitung-Smart-OEPNV-Planer.pdf`

PDF neu erzeugen:

```powershell
powershell -ExecutionPolicy Bypass -File docs\Export-Anleitung-PDF.ps1
```

## Screenshots neu erzeugen

Voraussetzung: Planer gebaut oder installiert, Planer-Zugang in der Personalverwaltung.

```powershell
powershell -ExecutionPolicy Bypass -File docs\screenshots\Capture-PlanerScreenshots.ps1
```

Ergebnis: PNG-Dateien in `docs\screenshots\`.

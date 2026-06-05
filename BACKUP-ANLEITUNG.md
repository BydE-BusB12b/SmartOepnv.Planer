# Smart-OEPNV – Backup-Anleitung

## Automatisch in den Programmen

### Planer / Leitstelle (Windows)

- **Atomisches Speichern**: `planner_local_roster.json` und `routes_export.json` werden über temporäre Datei geschrieben (kein halbes File bei Absturz).
- **Versions-Backup**: Bei jedem Überschreiben entsteht eine Kopie unter  
  `%AppData%\Smart-OEPNV\Planer\workspace\backups\`
- **Fahrzeugdisposition**: wird beim Speichern, beim Verlassen der Ansicht, vor Dropbox-Export und beim Beenden der App geschrieben und geprüft.
- **App-Ende**: kompletter Workspace-Ordner wird nach  
  `%USERPROFILE%\AndroidStudioProjects\_Backups\Smart-OEPNV\AppData\`  
  kopiert.

### GPSAnsagen (Android)

- Einstellungen und Dropbox-Tokens: SharedPreferences `GPSAnsagen` / `dropbox_prefs`
- Routen: interne App-Daten + optional Dropbox `/Smart ÖPNV` oder `/App/Smart ÖPNV`

---

## Manuelles Gesamt-Backup (empfohlen)

Im Ordner `AndroidStudioProjects`:

```powershell
.\Backup-All-SmartOepnv.ps1
```

Das Skript:

1. sichert **Planer- und Leitstelle-Benutzerdaten** nach `_Backups\Smart-OEPNV\AppData\`
2. **committet und pusht** alle Repos nach GitHub:
   - GPSAnsagen
   - SmartOepnv.Shared
   - SmartOepnv.Planer
   - SmartOepnv.Leitstelle

Nur lokal committen (ohne Push):

```powershell
.\Backup-All-SmartOepnv.ps1 -SkipPush
```

---

## Wichtige Dateipfade (Planer)

| Inhalt | Pfad |
|--------|------|
| Fahrzeuge, Fahrer, **Fahrzeugdisposition** | `%AppData%\Smart-OEPNV\Planer\workspace\planner_local_roster.json` |
| Routen-Paket | `%AppData%\Smart-OEPNV\Planer\workspace\routes_export.json` |
| Datei-Versionen | `%AppData%\Smart-OEPNV\Planer\workspace\backups\` |
| Externe Snapshots | `%USERPROFILE%\AndroidStudioProjects\_Backups\Smart-OEPNV\` |

---

## GitHub-Repositories

| Programm | Repository |
|----------|------------|
| Android App | `BydE-BusB12b/GPSAnsagen` |
| Gemeinsame Bibliothek | `BydE-BusB12b/SmartOepnv.Shared-` |
| Planer | `BydE-BusB12b/SmartOepnv.Planer` |
| Leitstelle | `BydE-BusB12b/SmartOepnv.Leitstelle` |

**Hinweis:** Benutzerdaten (Disposition, Overlay) liegen **nicht** in Git – nur Quellcode. Deshalb lokales Backup + Dropbox für Routen.

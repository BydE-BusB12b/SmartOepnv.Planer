using SmartOepnv.Core;

AppServices.Initialize("Planer");

if (!AppServices.Dropbox.Settings.IsConnected)
{
    Console.Error.WriteLine("Dropbox ist nicht verbunden (Planer-Einstellungen).");
    return 1;
}

try
{
    await AppServices.PlanerSession!.ForceClearLockAsync();
    Console.WriteLine("Planer-Sperre freigegeben (planer_session.json → available).");
    return 0;
}
catch (Exception ex)
{
    Console.Error.WriteLine($"Fehler: {ex.Message}");
    return 1;
}

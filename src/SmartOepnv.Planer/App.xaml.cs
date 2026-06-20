using System.Windows;

using SmartOepnv.AppShared;

namespace SmartOepnv.Planer;

public partial class App : Application
{
    private async void OnStartup(object sender, StartupEventArgs e)
    {
        SmartOepnvAppHost.Initialize(SmartOepnvAppProfile.Planer);
        SmartOepnvAppHost.ApplyApplicationResources(this, SmartOepnvAppProfile.Planer);

        var mainWindow = SmartOepnvAppHost.CreateMainWindow();

        MainWindow = mainWindow;

        mainWindow.Closed += (_, _) => Shutdown();

        mainWindow.SetLoginOverlay(true);

        mainWindow.Show();

        var gate = await SmartOepnvAppHost.RunPlanerLoginGateAsync(mainWindow);
        if (!gate.Success)
        {
            mainWindow.Close();

            Shutdown();

            return;
        }

        mainWindow.BeginPostLoginInitialization(gate);
    }

    protected override void OnExit(ExitEventArgs e)
    {
        SmartOepnvAppHost.SaveAndReleasePlanerSessionSync();
        base.OnExit(e);
    }
}

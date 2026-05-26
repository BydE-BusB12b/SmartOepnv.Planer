using System.Windows;
using SmartOepnv.AppShared;

namespace SmartOepnv.Planer;

public partial class App : Application
{
    private void OnStartup(object sender, StartupEventArgs e)
    {
        SmartOepnvAppHost.Initialize(SmartOepnvAppProfile.Planer);
        SmartOepnvAppHost.ApplyApplicationResources(this, SmartOepnvAppProfile.Planer);
        SmartOepnvAppHost.CreateMainWindow().Show();
    }
}

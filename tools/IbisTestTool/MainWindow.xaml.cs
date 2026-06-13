using System.IO.Ports;
using System.Text;
using System.Windows;

namespace IbisTestTool;

public partial class MainWindow : Window
{
    private readonly IbisSerialSender _sender = new();

    public MainWindow()
    {
        InitializeComponent();
        PortCombo.Text = "COM4";
        RefreshPorts();
        Preview_Click(this, new RoutedEventArgs());
        Log("8N2-Emulation. HSA-Standard: v0+16 Zeichen, 3× senden.");
    }

    private void HsaTypeCombo_SelectionChanged(object sender, System.Windows.Controls.SelectionChangedEventArgs e)
    {
        if (HsaFormatCombo == null) return;
        HsaFormatCombo.IsEnabled = HsaTypeCombo.SelectedIndex != 1;
    }

    private void TestHsa_Click(object sender, RoutedEventArgs e)
    {
        LineCheck.IsChecked = false;
        DestCheck.IsChecked = false;
        RawCheck.IsChecked = false;
        StopCheck.IsChecked = true;
        HsaTypeCombo.SelectedIndex = 0;
        HsaFormatCombo.SelectedIndex = 0;
        Send_Click(sender, e);
    }

    private SerialLinkMode ReadLinkMode() => LinkModeCombo.SelectedIndex switch
    {
        1 => SerialLinkMode.Bluetooth8N2Emulation,
        2 => SerialLinkMode.IvuAscii8N1,
        _ => SerialLinkMode.IbisWandler7E2
    };

    private string ReadPortName()
    {
        var text = (PortCombo.Text ?? "").Trim();
        if (!string.IsNullOrEmpty(text))
            return text;
        return PortCombo.SelectedItem as string ?? "";
    }

    private void RefreshPorts_Click(object sender, RoutedEventArgs e) => RefreshPorts();

    private void RefreshPorts()
    {
        var previous = ReadPortName();
        var ports = SerialPort.GetPortNames().OrderBy(p => p, StringComparer.OrdinalIgnoreCase).ToArray();
        PortCombo.ItemsSource = ports;

        if (ports.Contains("COM4", StringComparer.OrdinalIgnoreCase))
            PortCombo.Text = "COM4";
        else if (!string.IsNullOrEmpty(previous))
            PortCombo.Text = previous;
        else if (ports.Length > 0)
            PortCombo.Text = ports[0];

        Log(ports.Length == 0
            ? "Keine COM-Ports gefunden – COM4 manuell eintragen falls Wandler angeschlossen."
            : $"COM-Ports: {string.Join(", ", ports)}");
    }

    private IbisMessageBuilder ReadBuilder()
    {
        var lenItem = HsaLenCombo.SelectedItem as System.Windows.Controls.ComboBoxItem;
        var len = int.TryParse(lenItem?.Content?.ToString(), out var l) ? l : 16;

        var repeatItem = HsaRepeatCombo.SelectedItem as System.Windows.Controls.ComboBoxItem;
        var repeat = int.TryParse(repeatItem?.Content?.ToString(), out var r) ? r : 3;

        return new IbisMessageBuilder
        {
            SendLine = LineCheck.IsChecked == true,
            LineNumber = LineBox.Text,
            LaType = LaTypeCombo.SelectedIndex == 1 ? LaType.Ds001Neu : LaType.Ds001,
            SendDestination = DestCheck.IsChecked == true,
            DestinationLine1 = DestLine1.Text,
            DestinationLine2 = DestLine2.Text,
            ZaType = ZaTypeCombo.SelectedIndex switch
            {
                1 => ZaType.Ds003aMas,
                2 => ZaType.Ds003aMasCtrl,
                _ => ZaType.Ds003a
            },
            SendStop = StopCheck.IsChecked == true,
            StopText = StopBox.Text,
            HsaType = HsaTypeCombo.SelectedIndex == 1 ? HsaType.Ds003c : HsaType.Ds009,
            HsaLength = len,
            HsaFormat = HsaFormatCombo.SelectedIndex switch
            {
                1 => Ds009Format.IbisUiV,
                2 => Ds009Format.AndroidV17,
                _ => Ds009Format.MatrixV0
            },
            HsaRepeatCount = repeat,
            SendRaw = RawCheck.IsChecked == true,
            RawPayload = RawBox.Text
        };
    }

    private void Preview_Click(object sender, RoutedEventArgs e)
    {
        var mode = ReadLinkMode();
        var sb = new StringBuilder();
        sb.AppendLine($"Modus: {_sender.DescribeSettings(mode)}");
        sb.AppendLine();

        foreach (var payload in ReadBuilder().BuildPayloads())
        {
            var frame = _sender.BuildFrame(payload, mode);
            sb.AppendLine($"Payload: {payload.Replace("\r", "<CR>").Replace("\n", "<LF>")}");
            sb.AppendLine($"Hex:     {IbisUtils.ToHex(frame)}");
            sb.AppendLine();
        }

        PreviewBox.Text = sb.Length == 0 ? "(keine Telegramme ausgewählt)" : sb.ToString().TrimEnd();
    }

    private void TestPort_Click(object sender, RoutedEventArgs e)
    {
        LineCheck.IsChecked = true;
        LineBox.Text = "300";
        StopCheck.IsChecked = false;
        DestCheck.IsChecked = false;
        RawCheck.IsChecked = false;
        Send_Click(sender, e);
    }

    private void Diagnose_Click(object sender, RoutedEventArgs e)
    {
        var port = ReadPortName();
        if (string.IsNullOrWhiteSpace(port))
        {
            Log("Kein COM-Port – bitte COM4 eintragen.");
            return;
        }

        Log($"=== Diagnose {port} – bei jedem Schritt LED am Wandler beobachten ===");
        Log(Com4Probe.Run(port));
    }

    private void Send_Click(object sender, RoutedEventArgs e)
    {
        var port = ReadPortName();
        if (string.IsNullOrWhiteSpace(port))
        {
            Log("Kein COM-Port gewählt – bitte COM4 eintragen oder auswählen.");
            return;
        }

        var mode = ReadLinkMode();
        var payloads = ReadBuilder().BuildPayloads().ToList();
        if (payloads.Count == 0)
        {
            Log("Nichts zum Senden – mindestens ein Telegramm aktivieren.");
            return;
        }

        try
        {
            Log($"Öffne {port} … ({_sender.DescribeSettings(mode)})");
            _sender.EnsureOpen(port, mode);
            Log($"Port geöffnet: {_sender.IsOpen}");

            for (var i = 0; i < payloads.Count; i++)
            {
                var payload = payloads[i];
                var frame = _sender.BuildFrame(payload, mode);
                var written = _sender.SendFrame(frame);
                Log($"→ {port}: {payload.Replace("\r", "<CR>").Replace("\n", "<LF>")}");
                Log($"  Hex: {IbisUtils.ToHex(frame)} ({written} Bytes geschrieben)");
                if (i < payloads.Count - 1)
                    Thread.Sleep(payload.StartsWith("v0") || payload.StartsWith("v") ? 400 : 800);
            }

            Log("Senden abgeschlossen.");
        }
        catch (Exception ex)
        {
            Log($"Fehler: {ex.Message}");
            if (ex.InnerException != null)
                Log($"  Ursache: {ex.InnerException.Message}");
            Log("Tipp: Gerätemanager prüfen, anderen Modus testen, kein anderes Programm auf COM4.");
        }
    }

    private void Log(string message)
    {
        LogBox.AppendText($"[{DateTime.Now:HH:mm:ss}] {message}{Environment.NewLine}");
        LogBox.ScrollToEnd();
    }

    protected override void OnClosed(EventArgs e)
    {
        _sender.Dispose();
        base.OnClosed(e);
    }
}

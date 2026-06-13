using System.IO.Ports;
using System.Text;

namespace IbisTestTool;

/// <summary>Diagnose: testet mehrere serielle Profile auf COM4.</summary>
internal static class Com4Probe
{
    public static string Run(string portName)
    {
        var log = new StringBuilder();
        var port = Normalize(portName);

        log.AppendLine($"=== COM-Probe {port} ===");
        log.AppendLine($"Verfügbar: {string.Join(", ", SerialPort.GetPortNames().OrderBy(p => p))}");
        log.AppendLine();

        TryProfile(log, port, "A: 1200 7E2 + l300 nativ", Open7E2, () => BuildIbisNative("l300"));
        TryProfile(log, port, "B: 1200 8N2 + l300 emuliert", Open8N2, () => IbisUtils.BuildIbisFrame("l300"));
        TryProfile(log, port, "C: 1200 8N1 Roh-ASCII 'TEST\\r\\n'", Open8N1, () => Encoding.ASCII.GetBytes("TEST\r\n"));
        TryProfile(log, port, "D: 1200 8N1 IVU 'DS001;300\\r\\n'", Open8N1, () => Encoding.ASCII.GetBytes("DS001;300\r\n"));
        TryProfile(log, port, "E: 1200 7E2 Block-Write vTest", Open7E2, () => BuildIbisNative("v" + new string(' ', 15) + "Test".PadLeft(10).Trim()));

        return log.ToString();
    }

    private static void TryProfile(StringBuilder log, string port, string label, Action<SerialPort> open, Func<byte[]> build)
    {
        log.AppendLine($"--- {label} ---");
        using var sp = new SerialPort { PortName = port, WriteTimeout = 3000, ReadTimeout = 300 };
        try
        {
            open(sp);
            sp.Open();
            var frame = build();
            sp.Write(frame, 0, frame.Length);
            sp.BaseStream.Flush();
            Thread.Sleep(100);
            log.AppendLine($"OK: {frame.Length} Bytes → {IbisUtils.ToHex(frame)}");
        }
        catch (Exception ex)
        {
            log.AppendLine($"FEHLER: {ex.Message}");
        }
        log.AppendLine();
    }

    private static void Open7E2(SerialPort sp)
    {
        sp.BaudRate = 1200;
        sp.DataBits = 7;
        sp.Parity = Parity.Even;
        sp.StopBits = StopBits.Two;
        sp.Handshake = Handshake.None;
        sp.DtrEnable = false;
        sp.RtsEnable = false;
    }

    private static void Open8N2(SerialPort sp)
    {
        sp.BaudRate = 1200;
        sp.DataBits = 8;
        sp.Parity = Parity.None;
        sp.StopBits = StopBits.Two;
        sp.Handshake = Handshake.None;
        sp.DtrEnable = false;
        sp.RtsEnable = false;
    }

    private static void Open8N1(SerialPort sp)
    {
        sp.BaudRate = 1200;
        sp.DataBits = 8;
        sp.Parity = Parity.None;
        sp.StopBits = StopBits.One;
        sp.Handshake = Handshake.None;
        sp.DtrEnable = true;
        sp.RtsEnable = true;
    }

    private static byte[] BuildIbisNative(string payload)
    {
        var sc = IbisUtils.ReplaceIbisSpecialChars(payload);
        var msg = Encoding.ASCII.GetBytes(sc + "\r");
        var p = IbisUtils.GetIbisParity(msg);
        var frame = new byte[msg.Length + 1];
        msg.CopyTo(frame, 0);
        frame[^1] = p;
        return frame;
    }

    private static string Normalize(string portName)
    {
        var name = portName.Trim().ToUpperInvariant();
        if (name.StartsWith("COM", StringComparison.Ordinal) && name.Length > 4 && !name.StartsWith(@"\\.\", StringComparison.Ordinal))
            return @"\\.\" + name;
        return name;
    }
}

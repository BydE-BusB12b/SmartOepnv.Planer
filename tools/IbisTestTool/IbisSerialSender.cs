using System.IO.Ports;
using System.Text;

namespace IbisTestTool;

internal enum SerialLinkMode
{
    IbisWandler7E2,
    Bluetooth8N2Emulation,
    IvuAscii8N1
}

internal sealed class IbisSerialSender : IDisposable
{
    private readonly SerialPort _port = new();
    private string? _openPortName;
    private SerialLinkMode? _openMode;

    public bool IsOpen => _port.IsOpen;

    public string DescribeSettings(SerialLinkMode mode) => mode switch
    {
        SerialLinkMode.IbisWandler7E2 => "1200 Baud, 7E2, Roh-IBIS (Android/CH340)",
        SerialLinkMode.Bluetooth8N2Emulation => "1200 Baud, 8N2, Even-Parity in Bit 8 (IBISui)",
        SerialLinkMode.IvuAscii8N1 => "1200 Baud, 8N1, Klartext IVU (DS001;300)",
        _ => "unbekannt"
    };

    public void EnsureOpen(string portName, SerialLinkMode mode)
    {
        if (_port.IsOpen && _openPortName == portName && _openMode == mode)
            return;

        Close();

        _port.PortName = NormalizePortName(portName);
        _port.WriteTimeout = 5000;
        _port.ReadTimeout = 500;
        _port.Handshake = Handshake.None;

        switch (mode)
        {
            case SerialLinkMode.IbisWandler7E2:
                ApplyPortSettings(1200, 7, Parity.Even, StopBits.Two);
                _port.DtrEnable = false;
                _port.RtsEnable = false;
                break;
            case SerialLinkMode.Bluetooth8N2Emulation:
                ApplyPortSettings(1200, 8, Parity.None, StopBits.Two);
                _port.DtrEnable = false;
                _port.RtsEnable = false;
                break;
            case SerialLinkMode.IvuAscii8N1:
                ApplyPortSettings(1200, 8, Parity.None, StopBits.One);
                _port.DtrEnable = true;
                _port.RtsEnable = true;
                break;
        }

        _port.Open();
        Thread.Sleep(300);
        _openPortName = _port.PortName;
        _openMode = mode;
    }

    private void ApplyPortSettings(int baud, int dataBits, Parity parity, StopBits stopBits)
    {
        if (_port.IsOpen)
            _port.Close();

        _port.BaudRate = baud;
        _port.DataBits = dataBits;
        _port.Parity = parity;
        _port.StopBits = stopBits;
    }

    private static string NormalizePortName(string portName)
    {
        var name = portName.Trim().ToUpperInvariant();
        if (name.StartsWith("COM", StringComparison.Ordinal) && name.Length > 4 && !name.StartsWith(@"\\.\", StringComparison.Ordinal))
            return @"\\.\" + name;
        return name;
    }

    public byte[] BuildFrame(string payload, SerialLinkMode mode) => mode switch
    {
        SerialLinkMode.Bluetooth8N2Emulation => IbisUtils.BuildIbisFrame(payload),
        SerialLinkMode.IvuAscii8N1 => BuildIvuAsciiFrame(payload),
        _ => BuildNative7E2Frame(payload)
    };

    private static byte[] BuildIvuAsciiFrame(string payload)
    {
        var ivu = payload switch
        {
            _ when payload.StartsWith("l", StringComparison.Ordinal) => "DS001;" + payload[1..],
            _ when payload.StartsWith("v", StringComparison.Ordinal) => "DS009;" + payload[1..].Trim(),
            _ when payload.StartsWith("q", StringComparison.Ordinal) => "DS001;" + payload[1..],
            _ => payload
        };
        return Encoding.ASCII.GetBytes(ivu + "\r\n");
    }

    public int SendFrame(byte[] frame)
    {
        if (!_port.IsOpen)
            throw new InvalidOperationException("COM-Port ist nicht geöffnet.");

        _port.Write(frame, 0, frame.Length);
        _port.BaseStream.Flush();
        Thread.Sleep(50);
        return frame.Length;
    }

    private static byte[] BuildNative7E2Frame(string payload)
    {
        var sc = IbisUtils.ReplaceIbisSpecialChars(payload);
        var message = Encoding.ASCII.GetBytes(sc + "\r");
        var parity = IbisUtils.GetIbisParity(message);
        var frame = new byte[message.Length + 1];
        message.CopyTo(frame, 0);
        frame[^1] = parity;
        return frame;
    }

    public void Close()
    {
        if (_port.IsOpen)
            _port.Close();
        _openPortName = null;
        _openMode = null;
    }

    public void Dispose()
    {
        Close();
        _port.Dispose();
    }
}

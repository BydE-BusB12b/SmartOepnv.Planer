using System.IO.Ports;
using System.Text;

var portArg = args.FirstOrDefault(a => a.StartsWith("COM", StringComparison.OrdinalIgnoreCase)) ?? "COM4";
Console.WriteLine($"IBIS COM-Probe auf {portArg}");
Console.WriteLine($"Ports: {string.Join(", ", SerialPort.GetPortNames().OrderBy(p => p))}");
Console.WriteLine();

Run(portArg, "7E2 l300", Open7E2, BuildNative("l300"));
Run(portArg, "8N2 emuliert l300", Open8N2, BuildEmulated("l300"));
Run(portArg, "8N1 IVU DS001;300", Open8N1, Encoding.ASCII.GetBytes("DS001;300\r\n"));
Run(portArg, "8N1 IVU DS009;Test", Open8N1, Encoding.ASCII.GetBytes("DS009;Test\r\n"));
Run(portArg, "8N1 ASCII blink", Open8N1, Encoding.ASCII.GetBytes("UUUUUUUUUU\r\n"));

static void Run(string portName, string label, Action<SerialPort> cfg, byte[] data)
{
    Console.WriteLine($"--- {label} ---");
    var port = Normalize(portName);
    using var sp = new SerialPort { PortName = port, WriteTimeout = 5000 };
    try
    {
        cfg(sp);
        sp.Open();
        sp.Write(data, 0, data.Length);
        sp.BaseStream.Flush();
        Thread.Sleep(300);
        Console.WriteLine($"OK  {data.Length} B  {ToHex(data)}");
        Console.WriteLine("    → Blaue LED am Wandler kurz aufgeleuchtet?");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"ERR {ex.Message}");
    }
    Console.WriteLine();
}

static void Open7E2(SerialPort sp)
{
    sp.BaudRate = 1200;
    sp.DataBits = 7;
    sp.Parity = Parity.Even;
    sp.StopBits = StopBits.Two;
    sp.DtrEnable = false;
    sp.RtsEnable = false;
}

static void Open8N2(SerialPort sp)
{
    sp.BaudRate = 1200;
    sp.DataBits = 8;
    sp.Parity = Parity.None;
    sp.StopBits = StopBits.Two;
    sp.DtrEnable = false;
    sp.RtsEnable = false;
}

static void Open8N1(SerialPort sp)
{
    sp.BaudRate = 1200;
    sp.DataBits = 8;
    sp.Parity = Parity.None;
    sp.StopBits = StopBits.One;
    sp.DtrEnable = true;
    sp.RtsEnable = true;
}

static byte[] BuildNative(string payload)
{
    var msg = Encoding.ASCII.GetBytes(payload + "\r");
    byte p = 0x7F;
    foreach (var b in msg) p ^= b;
    var frame = new byte[msg.Length + 1];
    msg.CopyTo(frame, 0);
    frame[^1] = p;
    return frame;
}

static byte[] BuildEmulated(string payload)
{
    var native = BuildNative(payload);
    var outBuf = new byte[native.Length];
    for (var i = 0; i < native.Length; i++)
    {
        var b = native[i] & 0x7F;
        var bits = 0;
        for (var j = 0; j < 7; j++)
            if ((b & (1 << j)) != 0) bits++;
        outBuf[i] = bits % 2 == 1 ? (byte)(b | 0x80) : (byte)b;
    }
    return outBuf;
}

static string Normalize(string name)
{
    name = name.Trim().ToUpperInvariant();
    if (name.StartsWith("COM") && name.Length > 4 && !name.StartsWith(@"\\.\"))
        return @"\\.\" + name;
    return name;
}

static string ToHex(byte[] bytes) =>
    string.Join(" ", bytes.Select(b => b.ToString("X2")));

using System.Text;

namespace IbisTestTool;

/// <summary>
/// IBIS-Hilfsfunktionen – portiert aus robotfreak/IBIStools (IBISutils.cs).
/// </summary>
internal static class IbisUtils
{
    public static string ReplaceIbisSpecialChars(string input)
    {
        ArgumentNullException.ThrowIfNull(input);
        var chars = input.ToCharArray();
        for (var i = 0; i < chars.Length; i++)
        {
            chars[i] = chars[i] switch
            {
                'ä' => '{',
                'ö' => '|',
                'ü' => '}',
                'Ä' => '[',
                'Ö' => '\\',
                'Ü' => ']',
                'ß' => '~',
                _ => chars[i]
            };
        }
        return new string(chars);
    }

    public static byte GetIbisParity(ReadOnlySpan<byte> messageWithCr)
    {
        byte p = 0x7F;
        foreach (var b in messageWithCr)
            p ^= b;
        return p;
    }

    public static byte[] BuildIbisFrame(string payload)
    {
        var sc = ReplaceIbisSpecialChars(payload);
        var message = Encoding.ASCII.GetBytes(sc + "\r");
        var parity = GetIbisParity(message);
        var withParity = new byte[message.Length + 1];
        message.CopyTo(withParity, 0);
        withParity[^1] = parity;
        return EmulateEvenParity(withParity);
    }

    public static byte[] EmulateEvenParity(ReadOnlySpan<byte> input)
    {
        var bytes = input.ToArray();
        for (var i = 0; i < bytes.Length; i++)
        {
            var cnt = GetBitCount((byte)(bytes[i] & 0x7F));
            bytes[i] = cnt % 2 == 1
                ? (byte)(bytes[i] | 0x80)
                : (byte)(bytes[i] & 0x7F);
        }
        return bytes;
    }

    private static int GetBitCount(byte input)
    {
        var cnt = 0;
        for (var i = 0; i < 7; i++)
        {
            if ((input & (byte)(1 << i)) > 0)
                cnt++;
        }
        return cnt;
    }

    public static string FillDecimalString(string s, int desiredLength)
    {
        ArgumentNullException.ThrowIfNull(s);
        return s.Length >= desiredLength ? s : s.PadLeft(desiredLength, '0');
    }

    public static string LeftAlignedString(string s, int desiredLength)
    {
        ArgumentNullException.ThrowIfNull(s);
        return s.Length >= desiredLength ? s : s.PadRight(desiredLength);
    }

    public static string CenterString(string s, int desiredLength)
    {
        ArgumentNullException.ThrowIfNull(s);
        if (s.Length >= desiredLength)
            return s;
        var firstPad = (s.Length + desiredLength) / 2;
        return s.PadLeft(firstPad).PadRight(desiredLength);
    }

    public static string ReplaceChar(string input, char source, char destination)
    {
        ArgumentNullException.ThrowIfNull(input);
        return input.Replace(source, destination);
    }

    public static string Dec2HexString(string s)
    {
        ArgumentNullException.ThrowIfNull(s);
        if (!int.TryParse(s, out var x))
            x = 0;
        var chars = x.ToString("X4").ToCharArray();
        for (var i = 0; i < chars.Length; i++)
        {
            chars[i] = chars[i] switch
            {
                'A' => ':',
                'B' => ';',
                'C' => '<',
                'D' => '=',
                'E' => '>',
                'F' => '?',
                _ => chars[i]
            };
        }
        return new string(chars);
    }

    public static string ToHex(byte[] bytes) =>
        string.Join(" ", bytes.Select(b => b.ToString("X2")));
}

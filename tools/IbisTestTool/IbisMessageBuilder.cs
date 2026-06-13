namespace IbisTestTool;

internal enum HsaType { Ds009, Ds003c }

/// <summary>ds009-Varianten – viele Matrix-Innenanzeigen nutzen v0, nicht v (IBISui).</summary>
internal enum Ds009Format
{
    /// <summary>IBISui: "v" + zentriert (16/48 Zeichen).</summary>
    IbisUiV,
    /// <summary>Android: "v" + Text links auf 17 Zeichen.</summary>
    AndroidV17,
    /// <summary>Originalsoftware/GPSAnsagen: "v0" + Text links auf 16 Zeichen.</summary>
    MatrixV0
}

internal enum ZaType { Ds003a, Ds003aMas, Ds003aMasCtrl }

internal enum LaType { Ds001, Ds001Neu }

internal sealed class IbisMessageBuilder
{
    public LaType LaType { get; set; } = LaType.Ds001;
    public ZaType ZaType { get; set; } = ZaType.Ds003a;
    public HsaType HsaType { get; set; } = HsaType.Ds009;
    public int HsaLength { get; set; } = 16;
    public Ds009Format HsaFormat { get; set; } = Ds009Format.MatrixV0;
    public int HsaRepeatCount { get; set; } = 3;

    public bool SendLine { get; set; }
    public string LineNumber { get; set; } = "300";

    public bool SendSpecial { get; set; }
    public string SpecialCode { get; set; } = "00";

    public bool SendDestination { get; set; }
    public string DestinationLine1 { get; set; } = "";
    public string DestinationLine2 { get; set; } = "";
    public string DestinationLine3 { get; set; } = "";
    public string DestinationLine4 { get; set; } = "";

    public bool SendStop { get; set; }
    public string StopText { get; set; } = "Test";

    public bool SendRaw { get; set; }
    public string RawPayload { get; set; } = "";

    public IEnumerable<string> BuildPayloads()
    {
        if (SendLine)
        {
            yield return LaType == LaType.Ds001
                ? "l" + IbisUtils.FillDecimalString(LineNumber, 3)
                : "q" + IbisUtils.FillDecimalString(LineNumber, 4);
        }

        if (SendSpecial)
        {
            var code = SpecialCode == "00" ? "94" : IbisUtils.FillDecimalString(SpecialCode, 2);
            yield return LaType == LaType.Ds001 ? "lE" + code : "qE" + code;
        }

        if (SendDestination)
        {
            if (!SendLine && !SendSpecial)
                yield return "lE94";

            yield return ZaType switch
            {
                ZaType.Ds003a => "zA2"
                    + IbisUtils.CenterString(DestinationLine1, 16)
                    + IbisUtils.CenterString(DestinationLine2, 16),
                ZaType.Ds003aMas => "zA4"
                    + IbisUtils.CenterString(DestinationLine1, 16)
                    + IbisUtils.CenterString(DestinationLine2, 16)
                    + IbisUtils.CenterString(DestinationLine3, 16)
                    + IbisUtils.CenterString(DestinationLine4, 16),
                ZaType.Ds003aMasCtrl => "zA5"
                    + IbisUtils.LeftAlignedString(DestinationLine1, 16)
                    + IbisUtils.LeftAlignedString(DestinationLine2, 16)
                    + IbisUtils.LeftAlignedString(DestinationLine3, 16)
                    + IbisUtils.LeftAlignedString(DestinationLine4, 16)
                    + "\n.BI@MBI@M      ",
                _ => throw new InvalidOperationException()
            };
        }

        if (SendStop)
        {
            if (HsaType == HsaType.Ds003c)
            {
                foreach (var payload in BuildDs003cPayload(StopText, HsaLength))
                    yield return payload;
            }
            else
            {
                var payload = BuildDs009Payload(StopText, HsaFormat, HsaLength);
                for (var r = 0; r < Math.Max(1, HsaRepeatCount); r++)
                    yield return payload;
            }
        }

        if (SendRaw && !string.IsNullOrEmpty(RawPayload))
            yield return RawPayload;
    }

    /// <summary>Android: "vTest             " (17 Zeichen).</summary>
    private static string BuildDs009LeftPadded17(string text)
    {
        var payload = "v" + text;
        return payload.Length >= 17 ? payload[..17] : payload.PadRight(17, ' ');
    }

    private static string BuildDs009Payload(string text, Ds009Format format, int length) => format switch
    {
        Ds009Format.MatrixV0 => "v0" + (text.Length >= 16 ? text[..16] : text.PadRight(16, ' ')),
        Ds009Format.AndroidV17 => BuildDs009LeftPadded17(text),
        _ => "v" + IbisUtils.CenterString(text, length)
    };

    private static IEnumerable<string> BuildDs003cPayload(string text, int length)
    {
        var cmd = length switch
        {
            16 => "zI4",
            20 => "zI5",
            24 => "zI6",
            28 => "zI7",
            32 => "zI8",
            36 => "zI9",
            40 => "zI:",
            44 => "zI;",
            48 => "zI<",
            _ => "zI<"
        };
        var normalized = IbisUtils.ReplaceChar(text, '@', '\n');
        yield return cmd + IbisUtils.LeftAlignedString(normalized, length);
    }
}

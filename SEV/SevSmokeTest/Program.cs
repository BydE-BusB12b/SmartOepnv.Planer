using SmartOepnv.AppShared.Sev;
using SmartOepnv.Core.Sev;

var assets = Path.Combine(AppContext.BaseDirectory, "Assets", "sev");
var outputDir = AppContext.BaseDirectory;

SevSignPdfGenerator.Generate(
    new SevSignData
    {
        Line = "RE 13",
        Destination = "Venlo, (Nederland)",
        Stops = ["Kaldenkirchen (D)", "Venlo (Nederland)"],
        Operators = [SevOperatorKind.DeutscheBahn]
    },
    Path.Combine(outputDir, "_layout_re13.pdf"),
    assets);

SevSignPdfGenerator.Generate(
    new SevSignData
    {
        Line = "S 28",
        Destination = "Test",
        Stops = ["Haltestelle A", "Haltestelle B"],
        Operators = [SevOperatorKind.RegioBahn, SevOperatorKind.GoRheinland, SevOperatorKind.Vrr]
    },
    Path.Combine(outputDir, "_layout_s28.pdf"),
    assets);

SevSignPdfGenerator.Generate(
    new SevSignData
    {
        Line = "RE 1",
        Destination = "Test vier Logos",
        Stops = ["A", "B"],
        Operators =
        [
            SevOperatorKind.RegioBahn,
            SevOperatorKind.GoRheinland,
            SevOperatorKind.NationalExpress,
            SevOperatorKind.RheinRuhrBahn
        ]
    },
    Path.Combine(outputDir, "_layout_4logos.pdf"),
    assets);

Console.WriteLine("Generated RE13 + S28 + 4-logos layout PDFs in " + outputDir);

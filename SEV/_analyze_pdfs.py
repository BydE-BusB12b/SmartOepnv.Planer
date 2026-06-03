import fitz
from pathlib import Path

sev = Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Planer\SEV")
for path in sorted(sev.glob("*.pdf")):
    doc = fitz.open(path)
    page = doc[0]
    print("===", path.name, "===")
    w_mm = page.rect.width * 25.4 / 72
    h_mm = page.rect.height * 25.4 / 72
    print(f"size_mm: {w_mm:.1f} x {h_mm:.1f}")
    print("images:", len(page.get_images(full=True)))
    for block in page.get_text("dict")["blocks"]:
        if block.get("type") == 0:
            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    t = span.get("text", "").strip()
                    if t:
                        bb = [round(x, 1) for x in span["bbox"]]
                        print(f"  TEXT {span['size']:.1f}pt {bb}: {t!r}")
        elif block.get("type") == 1:
            print("  IMG", [round(x, 1) for x in block["bbox"]])
    doc.close()
    print()

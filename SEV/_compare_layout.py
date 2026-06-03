import fitz
from pathlib import Path

files = [
    ("GEN", Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Planer\SEV\SevSmokeTest\bin\Release\net8.0-windows\_layout_test.pdf")),
    ("ORIG", Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Planer\SEV\RE13 Münchengladbach-Venlo Express.pdf")),
]

def pt_mm(y):
    return y * 25.4 / 72

for label, pdf in files:
    if not pdf.exists():
        print(label, "missing", pdf)
        continue
    doc = fitz.open(pdf)
    p = doc[0]
    print("===", label, pdf.name, "===")
    for b in p.get_text("dict")["blocks"]:
        if b.get("type") == 0:
            for l in b["lines"]:
                for s in l["spans"]:
                    t = s["text"].strip()
                    if not t:
                        continue
                    if any(k in t for k in (">", "RE", "Ersatz", "Venlo", "Haupt", "Nicht", "Express")):
                        bb = s["bbox"]
                        print(
                            f"  {t[:45]!r} size={s['size']:.0f} "
                            f"top_mm={pt_mm(bb[1]):.1f} bot_mm={pt_mm(bb[3]):.1f}"
                        )
    doc.close()
    print()

import fitz
from pathlib import Path


def pt_mm(v):
    return v * 25.4 / 72


def analyze(path, label):
    doc = fitz.open(path)
    print("===", label, "pages=", doc.page_count, "===")
    for pi in range(doc.page_count):
        p = doc[pi]
        print(f"--- page {pi} ---")
        for b in p.get_text("dict")["blocks"]:
            if b.get("type") == 0:
                for l in b["lines"]:
                    for s in l["spans"]:
                        t = s["text"].strip()
                        if not t:
                            continue
                        bb = s["bbox"]
                        print(
                            f"  {t[:50]!r} size={s['size']:.0f} "
                            f"top={pt_mm(bb[1]):.1f} bot={pt_mm(bb[3]):.1f} "
                            f"font={s.get('font')}"
                        )
    p0 = doc[0]
    print("drawings page0:", len(p0.get_drawings()))
    for d in p0.get_drawings()[:8]:
        r = d.get("rect")
        if r:
            print(
                f"  rect x={pt_mm(r.x0):.1f}-{pt_mm(r.x1):.1f} "
                f"y={pt_mm(r.y0):.1f}-{pt_mm(r.y1):.1f} "
                f"w={d.get('width')} dashes={d.get('dashes')}"
            )
    doc.close()
    print()


gen = Path(
    r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Planer\SEV\SevSmokeTest\bin\Release\net8.0-windows\_layout_test.pdf"
)
orig_dir = Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Planer\SEV")
orig = next(orig_dir.glob("RE13 *Venlo*.pdf"))

analyze(gen, "GEN")
analyze(orig, "ORIG RE13 Venlo")

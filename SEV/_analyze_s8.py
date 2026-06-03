import fitz
from pathlib import Path

pdf = Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Planer\SEV\S8 Neuss-Mönchengladbach.pdf")
doc = fitz.open(pdf)
p = doc[0]
pw, ph = p.rect.width, p.rect.height
print(f"page pt: {pw:.1f} x {ph:.1f}")
print(f"page mm: {pw*25.4/72:.1f} x {ph*25.4/72:.1f}")
for b in p.get_text("dict")["blocks"]:
    if b.get("type") != 0:
        continue
    for l in b["lines"]:
        for s in l["spans"]:
            t = s["text"].strip()
            if not t:
                continue
            x0, y0, x1, y1 = s["bbox"]
            print(f"TEXT {s['size']:5.1f}pt y={y0:6.1f}-{y1:6.1f} x={x0:6.1f}-{x1:6.1f}: {t[:50]}")
for img in p.get_images(full=True):
    xref = img[0]
    for r in p.get_image_rects(xref):
        print(f"IMG [{r.x0:.1f},{r.y0:.1f},{r.x1:.1f},{r.y1:.1f}]")
doc.close()

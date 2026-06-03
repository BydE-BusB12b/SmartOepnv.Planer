import fitz
from pathlib import Path


def pt_mm(v):
    return v * 25.4 / 72


orig = next(Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Planer\SEV").glob("RE13 *Venlo*.pdf"))
doc = fitz.open(orig)
p = doc[0]
print("page rect pt:", p.rect)
print("page rect mm:", pt_mm(p.rect.width), pt_mm(p.rect.height))
print("\nAll drawings:")
for i, d in enumerate(p.get_drawings()):
    r = d.get("rect")
    if not r:
        continue
    print(
        f"{i:2d} rect pt x0={r.x0:.1f} y0={r.y0:.1f} x1={r.x1:.1f} y1={r.y1:.1f} "
        f"| mm x0={pt_mm(r.x0):.1f} y0={pt_mm(r.y0):.1f} x1={pt_mm(r.x1):.1f} y1={pt_mm(r.y1):.1f} "
        f"w={d.get('width')} dashes={d.get('dashes')}"
    )

# filled rects (header background?)
print("\nBlocks type 1 (images):")
for b in p.get_text("dict")["blocks"]:
    if b.get("type") == 1:
        bb = b["bbox"]
        print(f"  img mm: {pt_mm(bb[0]):.1f},{pt_mm(bb[1]):.1f} - {pt_mm(bb[2]):.1f},{pt_mm(bb[3]):.1f}")

doc.close()

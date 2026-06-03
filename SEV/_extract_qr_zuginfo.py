import fitz
from pathlib import Path

PDF = next(Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Planer\SEV").glob("RE13*Venlo*.pdf"))
OUT = Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Shared\src\SmartOepnv.AppShared\Assets\sev")


def pt_mm(v):
    return v * 25.4 / 72


doc = fitz.open(PDF)
page = doc[0]
for xref in {img[0] for img in page.get_images(full=True)}:
    base = doc.extract_image(xref)
    for rect in page.get_image_rects(xref):
        x0 = pt_mm(rect.x0)
        y0 = pt_mm(rect.y0)
        w = pt_mm(rect.width)
        h = pt_mm(rect.height)
        if 295 <= x0 <= 305 and 248 <= y0 <= 252 and w > 45:
            target = OUT / f"qr_zuginfo.{base['ext']}"
            target.write_bytes(base["image"])
            print(f"saved {target.name} at mm {x0:.1f},{y0:.1f} size {w:.1f}x{h:.1f}")
doc.close()

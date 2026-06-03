"""Extract operator logos from all SEV sample PDFs."""
import fitz
from pathlib import Path

PDF_DIR = Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Planer\SEV")
OUT = Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Shared\src\SmartOepnv.AppShared\Assets\sev\_extracted")
OUT.mkdir(parents=True, exist_ok=True)

for pdf_path in sorted(PDF_DIR.glob("*.pdf")):
    doc = fitz.open(pdf_path)
    page = doc[0]
    print(f"\n=== {pdf_path.name} ===")
    seen = set()
    for img in page.get_images(full=True):
        xref = img[0]
        for rect in page.get_image_rects(xref):
            if rect.y0 < 650 or rect.x0 > 600:
                continue
            base = doc.extract_image(xref)
            key = (base["width"], base["height"], len(base["image"]))
            if key in seen:
                continue
            seen.add(key)
            ext = base["ext"]
            name = f"{pdf_path.stem.replace(' ', '_')}_{base['width']}x{base['height']}.{ext}"
            path = OUT / name
            path.write_bytes(base["image"])
            print(f"  {name} @ y={rect.y0:.0f}")
    doc.close()

"""Extract embedded images from SEV sample PDFs into AppShared assets."""
import fitz
from pathlib import Path

PDF_DIR = Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Planer\SEV")
OUT = Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Shared\src\SmartOepnv.AppShared\Assets\sev")
OUT.mkdir(parents=True, exist_ok=True)

# Use RE10 as reference for common footer assets
ref = fitz.open(PDF_DIR / "RE10 Kleve-Krefeld.pdf")
page = ref[0]
imgs = page.get_images(full=True)
print(f"RE10: {len(imgs)} images")
for i, img in enumerate(imgs):
    xref = img[0]
    base = ref.extract_image(xref)
    ext = base["ext"]
    w, h = base["width"], base["height"]
    data = base["image"]
    name = f"re10_img{i}_{w}x{h}.{ext}"
    (OUT / name).write_bytes(data)
    print(f"  {i}: {name}")

# Extract operator logos from different PDFs (large logo bottom-left, not footer VRR/mobil)
samples = {
    "S28 Wuppertal-Düsseldorf.pdf": "regiobahn",
    "RE7 Neuss-Dormagen.pdf": "re7_neuss",
    "RE13 Düsseldorf-Mönchengladbach.pdf": "re13_db",
}
for pdf_name, prefix in samples.items():
    p = PDF_DIR / pdf_name
    if not p.exists():
        continue
    doc = fitz.open(p)
    pg = doc[0]
    for i, img in enumerate(pg.get_images(full=True)):
        base = doc.extract_image(img[0])
        ext = base["ext"]
        w, h = base["width"], base["height"]
        rects = pg.get_image_rects(img[0])
        for ri, r in enumerate(rects):
            # Großes Betreiberlogo links unten; Footer-Logos (VRR, mobil.nrw) weiter rechts / kleiner
            if r.y0 <= 650 or r.x0 >= 250 or w < 120 or h < 40:
                continue
            if w > 180 and h > 90 and prefix == "re13_db":
                # RE13-DB-Logo ist breiter als hoch; VRR-Footer ist eher quadratisch/klein
                name = f"operator_{prefix}_{w}x{h}.{ext}"
                (OUT / name).write_bytes(base["image"])
                print(f"operator from {pdf_name}: {name} at {r}")
            elif prefix != "re13_db":
                name = f"operator_{prefix}_{w}x{h}.{ext}"
                (OUT / name).write_bytes(base["image"])
                print(f"operator from {pdf_name}: {name} at {r}")
    doc.close()

ref.close()
print("done ->", OUT)

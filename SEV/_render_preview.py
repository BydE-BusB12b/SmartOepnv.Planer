import fitz
from pathlib import Path

out = Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Planer\SEV\_preview")
out.mkdir(exist_ok=True)
for name in ["S28 Wuppertal-Düsseldorf.pdf", "RE7 Neuss-Dormagen.pdf", "RE10 Kleve-Krefeld.pdf"]:
    doc = fitz.open(Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Planer\SEV") / name)
    page = doc[0]
    pix = page.get_pixmap(matrix=fitz.Matrix(0.35, 0.35))
    pix.save(str(out / (name.replace(".pdf", ".png"))))
    doc.close()
print("saved to", out)

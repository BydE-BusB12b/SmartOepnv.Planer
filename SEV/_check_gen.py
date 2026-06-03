import fitz
from pathlib import Path

pdf = Path(r"C:\Users\hkx18\AndroidStudioProjects\SmartOepnv.Planer\SEV\SevSmokeTest\bin\Release\net8.0-windows\_layout_test.pdf")
doc = fitz.open(pdf)
p = doc[0]
pix = p.get_pixmap(matrix=fitz.Matrix(0.35, 0.35))
out = pdf.with_suffix(".png")
pix.save(str(out))
print("saved", out)
for b in p.get_text("dict")["blocks"]:
    if b.get("type") == 0:
        for l in b["lines"]:
            for s in l["spans"]:
                t = s["text"].strip()
                if t:
                    print("TEXT", round(s["size"], 1), s["bbox"], t[:50])
print("images", len(p.get_images(full=True)))
doc.close()

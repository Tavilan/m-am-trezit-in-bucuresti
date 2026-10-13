#!/usr/bin/env python3
"""Conturul obiectelor de pe un fundal, pentru evidențierea la hover / butonul „?” (în loc de chenare).

  python3 tools/art/outlines.py <fundal.png> <ieșire.json> "Eticheta=x,y,w,h" ["Eticheta2=x,y,w,h;x,y" ...]

Pentru fiecare zonă de atins: tăiem zona (cu puțină margine), un model de segmentare (rembg, isnet)
găsește obiectul din ea, păstrăm cea mai mare pată, o simplificăm și scriem poligonul (pixeli de scenă, 640×360).
Opțional, după „;” un punct sigur din obiect (x,y): se păstrează pata care îl conține.
Moduri, la sfârșit după „|”: „|hull” = învelișul tuturor petelor (obiecte din mai multe bucăți, ex. două cizme);
„|rect” = chiar dreptunghiul (obiecte dreptunghiulare: icoană, ușă, ramă).
Contur dat de mână: "Eticheta=poly:x,y x,y x,y ..." (când modelul nu prinde forma, ex. o față de masă).
Ieșire: {"Eticheta": [[x,y], ...], ...}
"""
import json
import sys

import cv2
import numpy as np

from PIL import Image
from rembg import new_session, remove

S = 4   # lucrăm pe imaginea mărită (contur mai precis), apoi revenim la grila jocului
session = new_session("isnet-general-use")

src, out = sys.argv[1], sys.argv[2]
base = Image.open(src).convert("RGB")
big = base.resize((base.width * S, base.height * S), Image.LANCZOS)
res = {}
for spec in sys.argv[3:]:
    label, rest = spec.split("=", 1)
    mode = ""
    if "|" in rest:
        rest, mode = rest.split("|", 1)
    if rest.startswith("poly:"):
        res[label] = [[float(v) for v in q.split(",")] for q in rest[5:].split()]
        print(f"{label}: contur dat de mână")
        continue
    parts = rest.split(";")
    if mode == "rect":
        x, y, w, h = [int(v) for v in parts[0].split(",")]
        res[label] = [[x, y], [x + w, y], [x + w, y + h], [x, y + h]]
        print(f"{label}: dreptunghi")
        continue
    x, y, w, h = [int(v) for v in parts[0].split(",")]
    pad = int(max(w, h) * 0.15)
    x0, y0 = max(0, x - pad), max(0, y - pad)
    x1, y1 = min(base.width, x + w + pad), min(base.height, y + h + pad)
    crop = big.crop((x0 * S, y0 * S, x1 * S, y1 * S))
    m = np.asarray(remove(crop, session=session, only_mask=True))
    fg = (m > 128).astype(np.uint8) * 255
    # doar în zona de atins (puțin lărgită)
    keep = np.zeros_like(fg)
    keep[max(0, (y - y0 - 3) * S):(y - y0 + h + 3) * S, max(0, (x - x0 - 3) * S):(x - x0 + w + 3) * S] = 255
    fg = cv2.bitwise_and(fg, keep)
    fg = cv2.morphologyEx(fg, cv2.MORPH_OPEN, np.ones((2 * S, 2 * S), np.uint8))
    cs, _ = cv2.findContours(fg, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    if not cs:
        print("fără contur:", label)
        continue
    c = max(cs, key=cv2.contourArea)
    if mode == "hull":
        c = cv2.convexHull(np.vstack([k for k in cs if cv2.contourArea(k) > 40 * S * S]))
    if len(parts) > 1:
        px, py = [int(v) for v in parts[1].split(",")]
        inside = [k for k in cs if cv2.pointPolygonTest(k, ((px - x0) * S, (py - y0) * S), False) >= 0]
        if inside:
            c = inside[0]
    c = cv2.approxPolyDP(c, 1.0 * S, True)
    pts = [[round(p[0][0] / S + x0, 1), round(p[0][1] / S + y0, 1)] for p in c]
    area = cv2.contourArea(c) / (S * S)
    print(f"{label}: {len(pts)} puncte, arie {area:.0f} din {w * h}")
    res[label] = pts
json.dump(res, open(out, "w"), ensure_ascii=False)
print("ok:", out)

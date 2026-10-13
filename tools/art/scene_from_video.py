#!/usr/bin/env python3
"""Transformă un video generat (Veo) al unui fundal întreg (fără personaje, cameră fixă) într-o animație
de fundal pixel-art, pe grila jocului (640×360).

  python3 tools/art/scene_from_video.py <video.mp4> <nume> [--fps 12] [--min-loop 3] [--max-frames 60] [--stab 40] [--region x y w h]

Pași:
 1. extrage cadrele (ffmpeg), le taie la 16:9 și le pixelizează pe aceeași grilă ca fundalurile;
 2. stabilizare temporală: pixelii care se schimbă foarte puțin rămân ca în cadrul anterior
    (taie tremuratul de compresie; rămâne doar mișcarea reală: foc, fum, lumină);
 3. alege bucla cu primul și ultimul cadru cât mai apropiate.
Ieșire: art/anim/<nume>/sheet.png (grilă, max 4096 px lățime), anim.json; cadrele separate nu se păstrează
(ar ocupa mult). Procesează pe rând, fără să țină toate cadrele mari în memorie.
"""
import argparse
import glob
import json
import os
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from pixelize import pixelize  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
W, H = 640, 360

ap = argparse.ArgumentParser()
ap.add_argument("video")
ap.add_argument("name")
ap.add_argument("--fps", type=int, default=12)
ap.add_argument("--min-loop", type=float, default=3.0)
ap.add_argument("--max-frames", type=int, default=60)
ap.add_argument("--stab", type=int, default=40)
ap.add_argument("--blend", type=int, default=6, help="cadre de topire la capătul buclei")
ap.add_argument("--region", type=int, nargs=4, default=None, help="x y w h: păstrează doar zona care se mișcă (restul rămâne fundalul static)")
a = ap.parse_args()

tmp = tempfile.mkdtemp()
subprocess.run(["ffmpeg", "-v", "error", "-i", a.video, "-vf", f"fps={a.fps}", os.path.join(tmp, "f_%04d.png")], check=True)
srcs = sorted(glob.glob(os.path.join(tmp, "f_*.png")))
print("cadre:", len(srcs))

frames = []
prev = None
for i, s in enumerate(srcs):
    im = Image.open(s).convert("RGB")
    w, h = im.size
    nh = int(w * 9 / 16)
    if nh <= h:
        y0 = (h - nh) // 2
        im = im.crop((0, y0, w, y0 + nh))
    else:
        nw = int(h * 16 / 9)
        x0 = (w - nw) // 2
        im = im.crop((x0, 0, x0 + nw, h))
    cp = os.path.join(tmp, f"c_{i:04d}.png")
    im.save(cp)
    op = os.path.join(tmp, f"p_{i:04d}.png")
    pixelize(cp, op, width=W, height=H)
    px = np.asarray(Image.open(op).convert("RGB")).astype(np.int16)
    if prev is not None:
        diff = np.abs(px - prev).sum(axis=2)
        px = np.where((diff < a.stab)[..., None], prev, px)
    prev = px
    frames.append(px.astype(np.uint8))

# bucla: cel mai bun capăt după min-loop, primul cadru fix
n = len(frames)
lo = int(a.min_loop * a.fps)
# caută și începutul (video-urile pornesc des „mai calm” și cresc), nu doar sfârșitul
small = [f[::4, ::4].astype(np.int32) for f in frames]
best_s, best_e, best_d = 0, n, None
for st in range(0, n - lo, 2):
    for e in range(st + lo, min(n, st + a.max_frames) + 1):
        d = np.abs(small[e - 1] - small[st]).mean()
        if best_d is None or d < best_d:
            best_s, best_e, best_d = st, e, d
frames = frames[best_s:best_e]
# capătul se topește în început pe câteva cadre, ca bucla să nu sară
F = min(a.blend, len(frames) // 3)
for k in range(F):
    t = (k + 1) / (F + 1)
    i = len(frames) - F + k
    frames[i] = (frames[i].astype(np.float32) * (1 - t) + frames[0].astype(np.float32) * t).round().astype(np.uint8)
print("început:", best_s)
out = os.path.join(ROOT, "art", "anim", a.name)
os.makedirs(out, exist_ok=True)
if a.region:   # fundalul static = primul cadru întreg, ca zona animată să se lege fără cusături
    Image.fromarray(frames[0]).save(os.path.join(out, "bg.png"))
    x, y, rw, rh = a.region
    frames = [f[y:y + rh, x:x + rw] for f in frames]
    W, H = rw, rh
print("buclă:", len(frames), "cadre, diferență capăt-început", round(float(best_d or 0), 2))

cols = max(1, 4096 // W)
rows = (len(frames) + cols - 1) // cols
sheet = Image.new("RGB", (cols * W, rows * H))
for k, f in enumerate(frames):
    sheet.paste(Image.fromarray(f), ((k % cols) * W, (k // cols) * H))
sheet.save(os.path.join(out, "sheet.png"))
json.dump({"frames": len(frames), "fps": a.fps, "cols": cols, "w": W, "h": H, "region": a.region}, open(os.path.join(out, "anim.json"), "w"))
print("ok:", out, sheet.size)

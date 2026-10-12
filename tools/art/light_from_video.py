#!/usr/bin/env python3
"""Din video-ul Veo al unei lumini care pâlpâie (cameră fixă) scoate:
  1) varianta „stinsă” a fundalului: fundalul original + diferența (stins − aprins) din video,
     deci culorile și desenul rămân cele ale fundalului, iar lumina dispare exact cum a arătat-o Veo;
  2) curba de intensitate în timp (0 = stins, 1 = aprins), cadru cu cadru, ca jocul să pâlpâie
     în ritmul filmat de Veo.

  python3 tools/art/light_from_video.py <video> <id_fundal> <nume> --region x0 y0 x1 y1 [--fps 24]

--region = zona (în pixelii video-ului) luminată de bec, folosită pentru măsurarea intensității.
Ieșiri: art/raw/<id_fundal>_<nume>_stins.png, art/final/<id_fundal>_<nume>_stins.png,
        art/anim/<nume>/curve.json
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
ap = argparse.ArgumentParser()
ap.add_argument("video")
ap.add_argument("bg")
ap.add_argument("name")
ap.add_argument("--region", type=int, nargs=4, required=True)
ap.add_argument("--fps", type=int, default=24)
a = ap.parse_args()

tmp = tempfile.mkdtemp()
subprocess.check_call(["ffmpeg", "-v", "error", "-i", a.video, "-vf", f"fps={a.fps}", os.path.join(tmp, "f%04d.png")])
files = sorted(glob.glob(os.path.join(tmp, "*.png")))
x0, y0, x1, y1 = a.region
lvl = np.array([np.asarray(Image.open(f).convert("L"))[y0:y1, x0:x1].mean() / 255 for f in files])
lo, hi = np.percentile(lvl, 5), np.percentile(lvl, 90)


def median_of(sel):
    sel = sel[:: max(1, len(sel) // 24)]   # cel mult ~24 de cadre, ca să încapă în memorie
    return np.median(np.stack([np.asarray(Image.open(f).convert("RGB")) for f in sel]), axis=0).astype(np.float32) / 255


on = median_of([f for f, l in zip(files, lvl) if l > lo + 0.8 * (hi - lo)])
off = median_of([f for f, l in zip(files, lvl) if l < lo + 0.15 * (hi - lo)])
curve = np.clip((lvl - lo) / (hi - lo), 0, 1.05)

bg = Image.open(os.path.join(ROOT, "art", "raw", a.bg + ".png")).convert("RGB")
H, W = on.shape[:2]
delta = Image.fromarray(np.clip((off - on) * 0.5 + 0.5, 0, 1).__mul__(255).astype(np.uint8)).resize(bg.size, Image.LANCZOS)
delta = (np.asarray(delta).astype(np.float32) / 255 - 0.5) * 2
out = np.clip(np.asarray(bg).astype(np.float32) / 255 + np.minimum(delta, 0), 0, 1)
raw = os.path.join(ROOT, "art", "raw", f"{a.bg}_{a.name}_stins.png")
Image.fromarray((out * 255).astype(np.uint8)).save(raw)
pixelize(raw, os.path.join(ROOT, "art", "final", f"{a.bg}_{a.name}_stins.png"), 640, 360)
d = os.path.join(ROOT, "art", "anim", a.name)
os.makedirs(d, exist_ok=True)
json.dump({"fps": a.fps, "intensity": [round(float(c), 3) for c in curve], "source_video": os.path.basename(a.video)},
          open(os.path.join(d, "curve.json"), "w"))
print("ok:", len(curve), "cadre; aprins", round(float(hi), 3), "stins", round(float(lo), 3))

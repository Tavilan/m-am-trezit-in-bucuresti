#!/usr/bin/env python3
"""Face varianta „lumină stinsă” a unui fundal, din aceeași imagine (pixelii se potrivesc perfect).

  python3 tools/art/light_off.py <id_fundal> <nume_iesire> <x> <y> <raza> [--reflex x y rx ry]

x, y = poziția becului în imaginea brută; raza = cât de departe ajunge lumina lui.
--reflex = o elipsă în care lumina becului se reflectă (băltoace), tot în coordonate brute.
Unde lumina caldă a becului cade pe pereți, stâlp, gard sau băltoace, imaginea e adusă la lumina
nopții (mai întunecată și mai albastră); becul însuși devine sticlă stinsă. Jocul trece între
cele două imagini când becul pâlpâie, deci se schimbă doar ce lumina becului atinge cu adevărat.
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from pixelize import pixelize  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


ap = argparse.ArgumentParser()
ap.add_argument("id")
ap.add_argument("out")
ap.add_argument("x", type=float)
ap.add_argument("y", type=float)
ap.add_argument("radius", type=float)
ap.add_argument("--reflex", type=float, nargs=4)
a = ap.parse_args()

src = os.path.join(ROOT, "art", "raw", a.id + ".png")
im = np.asarray(Image.open(src).convert("RGB")).astype(np.float32) / 255.0
h, w, _ = im.shape
yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
d = np.hypot(xx - a.x, yy - a.y)
prox = np.clip(1 - d / a.radius, 0, 1) ** 0.8
if a.reflex:
    rx, ry, rw, rh = a.reflex
    e = np.clip(1 - np.hypot((xx - rx) / rw, (yy - ry) / rh), 0, 1)
    prox = np.maximum(prox, e)
r, g, b = im[..., 0], im[..., 1], im[..., 2]
lum = 0.299 * r + 0.587 * g + 0.114 * b
warm = r - b
mask = prox * smooth(-0.02, 0.18, warm) * smooth(0.04, 0.35, lum)
mask = np.clip(mask * 1.7, 0, 1)[..., None]
night = np.clip(im * np.array([0.30, 0.34, 0.48]) + np.array([0.01, 0.015, 0.035]), 0, 1)
out = im * (1 - mask) + night * mask
# aura din jurul becului (ceața luminată) devine cerul de noapte: doar pixelii de cer/ceață,
# nu stâlpul, firele sau corpul lămpii (acelea sunt mai întunecate sau gri neutru)
far = (yy < a.y + a.radius * 0.5) & (d > a.radius * 0.4) & (b > r + 0.08)
sky = np.median(im[far], axis=0) if far.any() else np.array([0.02, 0.09, 0.2])
skyish = smooth(0.12, 0.2, b) * smooth(0.25, 0.1, np.abs(r - g))
halo = (smooth(a.radius * 0.3, a.radius * 0.03, d) * (yy < a.y + a.radius * 0.35) * skyish)[..., None]
glow_free = np.clip(sky + (im - im.mean(axis=(0, 1))) * 0.15, 0, 1)
out = out * (1 - halo) + glow_free * halo
# becul: sticlă stinsă, gri-albăstruie
core = smooth(a.radius * 0.035, 0, d)[..., None] * smooth(0.45, 0.9, lum)[..., None]
glass = np.array([0.13, 0.14, 0.17]) + 0.05 * lum[..., None]
out = out * (1 - core) + glass * core
raw_out = os.path.join(ROOT, "art", "raw", a.out + ".png")
Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8)).save(raw_out)
pixelize(raw_out, os.path.join(ROOT, "art", "final", a.out + ".png"), 640, 360)
print("ok:", f"art/final/{a.out}.png")

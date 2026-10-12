#!/usr/bin/env python3
"""Pune foile de personaj una lângă alta, cu tălpile pe aceeași linie, la scara lor reală.

  python3 tools/art/lineup.py <iesire.png> <id> [<id> ...] [--zoom 2]

Folosește art/final/<id>.png. Bun pentru a verifica dacă personajele se deosebesc între ele
(siluetă, înălțime, față) și pentru testul orb.
"""
import argparse
import os

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

ap = argparse.ArgumentParser()
ap.add_argument("out")
ap.add_argument("ids", nargs="+")
ap.add_argument("--zoom", type=int, default=2)
a = ap.parse_args()

ims = [Image.open(os.path.join(ROOT, "art", "final", i + ".png")).convert("RGBA") for i in a.ids]
gap = 14
w = sum(im.width for im in ims) + gap * (len(ims) + 1)
h = max(im.height for im in ims) + 20
canvas = Image.new("RGBA", (w, h), (42, 42, 51, 255))
x = gap
for im in ims:
    canvas.alpha_composite(im, (x, h - 10 - im.height))
    x += im.width + gap
canvas.convert("RGB").resize((w * a.zoom, h * a.zoom), Image.NEAREST).save(a.out)
print("ok:", a.out, canvas.size)

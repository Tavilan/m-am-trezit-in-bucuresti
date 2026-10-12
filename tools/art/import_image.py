#!/usr/bin/env python3
"""Importă o imagine făcută manual (ChatGPT, Gemini sau o poză proprie) în pipeline.

  python3 tools/art/import_image.py <id> <imagine> <sursa> [--variant nume]

Copiază imaginea în art/raw/<id>[__varianta].png, o pixelizează după art/prompts/<id>.json
în art/final/ și notează sursa în art/LOG.md. Varianta permite comparații (ex. chatgpt vs gemini).
"""
import argparse
import datetime
import json
import os
import shutil
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pixelize import pixelize  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

ap = argparse.ArgumentParser()
ap.add_argument("id")
ap.add_argument("image")
ap.add_argument("source", help="chatgpt / gemini / poza-proprie / altă sursă cu licență")
ap.add_argument("--variant", default="")
a = ap.parse_args()

spec = json.load(open(os.path.join(ROOT, "art", "prompts", a.id + ".json"), encoding="utf-8"))
name = a.id + (f"__{a.variant}" if a.variant else "")
os.makedirs(os.path.join(ROOT, "art", "raw"), exist_ok=True)
os.makedirs(os.path.join(ROOT, "art", "final"), exist_ok=True)
raw = os.path.join(ROOT, "art", "raw", name + ".png")
from PIL import Image
Image.open(a.image).save(raw)
pix = dict(spec.get("pixelize", {"width": 640, "height": 360} if spec.get("type") == "scene" else {"height": 300}))
if spec.get("manual_key"):
    pix["key"] = spec["manual_key"]
pixelize(raw, os.path.join(ROOT, "art", "final", name + ".png"), **pix)
log = os.path.join(ROOT, "art", "LOG.md")
new = not os.path.exists(log)
with open(log, "a", encoding="utf-8") as f:
    if new:
        f.write("# Jurnal de generare a artei\n\n| Data | ID | Sursă | Detalii | Cost |\n|---|---|---|---|---|\n")
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    f.write(f"| {stamp} | {name} | {a.source} | import manual | 0 |\n")
print("ok:", "art/final/" + name + ".png")

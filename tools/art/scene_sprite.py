#!/usr/bin/env python3
"""Face varianta unui personaj/obiect la mărimea exactă din scenă, direct din imaginea brută.

  python3 tools/art/scene_sprite.py <id> <inaltime_px> <nume_iesire>

Așa pixelii rămân pe aceeași grilă cu fundalul (nu scalăm în joc un sprite deja pixelizat).
Ieșire: art/final/<nume_iesire>.png
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pixelize import pixelize, pixelize_args  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
asset_id, height, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
spec = json.load(open(os.path.join(ROOT, "art", "prompts", asset_id + ".json"), encoding="utf-8"))
pix = pixelize_args(spec)
pix.pop("width", None)
pix["height"] = height
pixelize(os.path.join(ROOT, "art", "raw", asset_id + ".png"), os.path.join(ROOT, "art", "final", out + ".png"), **pix)
print("ok:", f"art/final/{out}.png", height)

#!/usr/bin/env python3
"""Importă tot ce a apărut în art/inbox/ (imagini puse de ChatGPT/Codex sau urcate manual).

Numele fișierului dă ID-ul: art/inbox/<id>.png sau art/inbox/<id>__<varianta>.png.
Fiecare imagine e pixelizată după art/prompts/<id>.json și apoi scoasă din inbox.
"""
import glob
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
src = os.environ.get("SOURCE", "chatgpt")
done = 0
for path in sorted(glob.glob(os.path.join(ROOT, "art", "inbox", "*"))):
    name, ext = os.path.splitext(os.path.basename(path))
    if ext.lower() not in (".png", ".jpg", ".jpeg", ".webp"):
        continue
    asset_id, _, variant = name.partition("__")
    if not os.path.exists(os.path.join(ROOT, "art", "prompts", asset_id + ".json")):
        print(f"::warning::{name}: nu există art/prompts/{asset_id}.json, îl las în inbox.")
        continue
    cmd = [sys.executable, os.path.join(ROOT, "tools", "art", "import_image.py"), asset_id, path, src]
    if variant:
        cmd += ["--variant", variant]
    subprocess.check_call(cmd)
    os.remove(path)
    done += 1
print(f"Importate: {done}")

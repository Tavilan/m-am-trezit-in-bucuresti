#!/usr/bin/env python3
"""Generează arta jocului prin API-ul de imagini OpenAI și o aduce la pixel-art pe grilă fixă.

Rulează în GitHub Actions (vezi .github/workflows/art.yml). Cheia API vine DOAR din secretul
OPENAI_API_KEY al repository-ului; nu se scrie niciodată în fișiere.

Fiecare imagine are un fișier în art/prompts/<id>.json:
  {
    "id": "romica_foaie",
    "type": "character" | "scene" | "object",
    "model": "gpt-image-2.5-flare",      (opțional)
    "quality": "high",                   (opțional)
    "size": "1920x1088",                 (opțional)
    "background": "opaque" | "transparent",
    "refs": ["art/raw/romica_foaie.png"],  (opțional: imagini proprii folosite ca referință)
    "pixelize": {"width": 640, "height": 360}  sau  {"height": 300}
    "prompt": "..."
  }
La fiecare prompt se adaugă în față ghidul de stil comun, art/prompts/_style.md.

Ieșiri: art/raw/<id>.png (imaginea brută), art/final/<id>.png (pixel-art), art/LOG.md (cost estimat).
"""
import base64
import datetime
import io
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

sys.path.insert(0, os.path.dirname(__file__))
from pixelize import pixelize  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PROMPTS = os.path.join(ROOT, "art", "prompts")
RAW = os.path.join(ROOT, "art", "raw")
FINAL = os.path.join(ROOT, "art", "final")
LOG = os.path.join(ROOT, "art", "LOG.md")
API = os.environ.get("OPENAI_API_BASE", "https://api.openai.com/v1")
MAX_IMAGES = int(os.environ.get("MAX_IMAGES", "4"))      # plafon pe rulare, ca să nu apară facturi surpriză
DEFAULTS = {"model": "gpt-image-2.5-flare", "quality": "high", "background": "opaque"}
# USD per 1M tokeni (pagina de prețuri OpenAI, oct. 2026). Doar pentru estimare în log.
RATES = {
    "gpt-image-2.5": {"text_in": 5.0, "image_in": 8.0, "image_out": 30.0},
    "gpt-image-2": {"text_in": 2.5, "image_in": 4.0, "image_out": 15.0},
}


def log(msg):
    print(msg, flush=True)


def load_spec(asset_id):
    with open(os.path.join(PROMPTS, asset_id + ".json"), encoding="utf-8") as f:
        spec = json.load(f)
    spec.setdefault("id", asset_id)
    return spec


def style_guide():
    p = os.path.join(PROMPTS, "_style.md")
    return open(p, encoding="utf-8").read().strip() if os.path.exists(p) else ""


def data_url(path):
    with open(path, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def call(endpoint, payload, key):
    req = urllib.request.Request(
        f"{API}/images/{endpoint}",
        data=json.dumps(payload).encode(),
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=900) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")[:1500].replace("\n", " ")
        print(f"::error title=Eroare de la API OpenAI ({e.code})::{body}", flush=True)
        raise SystemExit(1)
    except urllib.error.URLError as e:
        print(f"::error title=Nu pot contacta API-ul OpenAI::{e}", flush=True)
        raise SystemExit(1)


def estimate_cost(model, usage):
    rates = RATES["gpt-image-2.5"] if model.startswith("gpt-image-2.5") else RATES["gpt-image-2"]
    det = usage.get("input_tokens_details", {}) or {}
    text_in = det.get("text_tokens", usage.get("input_tokens", 0))
    image_in = det.get("image_tokens", 0)
    out = usage.get("output_tokens", 0)
    return (text_in * rates["text_in"] + image_in * rates["image_in"] + out * rates["image_out"]) / 1e6


def order_by_refs(ids):
    """Generează întâi imaginile de care depind altele (refs către art/raw/<id>.png din același lot)."""
    ordered, seen = [], set()

    def visit(i):
        if i in seen:
            return
        seen.add(i)
        for r in load_spec(i).get("refs", []):
            dep = os.path.splitext(os.path.basename(r))[0]
            if dep in ids:
                visit(dep)
        ordered.append(i)

    for i in ids:
        visit(i)
    return ordered


def generate(asset_id, key, quality_override=""):
    spec = load_spec(asset_id)
    model = spec.get("model", DEFAULTS["model"])
    quality = quality_override or spec.get("quality", DEFAULTS["quality"])
    size = spec.get("size", "1920x1088" if spec.get("type") == "scene" else "1024x1536")
    background = spec.get("background", DEFAULTS["background"])
    prompt = (style_guide() + "\n\n" + spec["prompt"]).strip()
    payload = {"model": model, "prompt": prompt, "size": size, "quality": quality,
               "background": background, "output_format": "png", "n": 1}
    refs = [os.path.join(ROOT, r) for r in spec.get("refs", [])]
    missing = [r for r in refs if not os.path.exists(r)]
    if missing:
        print(f"::error title=Lipsesc referințe::{asset_id}: {missing}. Generează-le întâi.", flush=True)
        raise SystemExit(1)
    log(f"→ {asset_id}: {model}, {quality}, {size}, {len(refs)} referințe")
    if refs:
        payload["images"] = [{"image_url": data_url(r)} for r in refs]
        res = call("edits", payload, key)
    else:
        res = call("generations", payload, key)
    png = base64.b64decode(res["data"][0]["b64_json"])
    os.makedirs(RAW, exist_ok=True)
    os.makedirs(FINAL, exist_ok=True)
    raw_path = os.path.join(RAW, asset_id + ".png")
    with open(raw_path, "wb") as f:
        f.write(png)
    pix = spec.get("pixelize", {"width": 640, "height": 360} if spec.get("type") == "scene" else {"height": 300})
    final_path = os.path.join(FINAL, asset_id + ".png")
    pixelize(raw_path, final_path, **pix)
    cost = estimate_cost(model, res.get("usage", {}) or {})
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    new = not os.path.exists(LOG)
    with open(LOG, "a", encoding="utf-8") as f:
        if new:
            f.write("# Jurnal de generare a artei\n\n| Data | ID | Model | Calitate | Mărime | Cost estimat |\n|---|---|---|---|---|---|\n")
        f.write(f"| {stamp} | {asset_id} | {model} | {quality} | {size} | ~${cost:.3f} |\n")
    log(f"  ✓ {asset_id}: art/final/{asset_id}.png (cost estimat ~${cost:.3f})")
    return cost


def changed_ids():
    before = os.environ.get("BEFORE", "")
    rng = f"{before}..HEAD" if before and set(before) != {"0"} else "HEAD~1..HEAD"
    try:
        out = subprocess.check_output(["git", "diff", "--name-only", rng, "--", "art/prompts"], cwd=ROOT, text=True)
    except subprocess.CalledProcessError:
        return []
    ids = []
    for line in out.split():
        name = os.path.basename(line)
        if name.endswith(".json") and os.path.exists(os.path.join(ROOT, line)):
            ids.append(name[:-5])
        elif name == "_style.md":
            log("Ghidul de stil s-a schimbat. Nu regenerez automat tot; pornește manual ce vrei refăcut.")
    return ids


def main():
    key = os.environ.get("OPENAI_API_KEY", "")
    ids = [i.strip() for i in os.environ.get("IDS", "").split(",") if i.strip()] or changed_ids()
    if not ids:
        log("Nimic de generat.")
        return
    if not key:
        log("::warning::Lipsește secretul OPENAI_API_KEY în repository (Settings → Secrets and variables → Actions). Nu generez nimic.")
        return
    if len(ids) > MAX_IMAGES:
        raise SystemExit(f"Sunt {len(ids)} imagini, peste plafonul de {MAX_IMAGES} pe rulare. Pornește manual cu mai puține ID-uri.")
    total = 0.0
    for i in order_by_refs(ids):
        total += generate(i, key, os.environ.get("QUALITY", ""))
    log(f"Gata. Cost estimat total: ~${total:.2f}")


if __name__ == "__main__":
    main()

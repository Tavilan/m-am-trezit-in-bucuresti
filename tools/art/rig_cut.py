#!/usr/bin/env python3
"""Taie un personaj pixel-art (vedere din față) în părți pentru animația „decupată” din Godot.

  python3 tools/art/rig_cut.py art/rigs/romica.json

Fișierul de rig spune din ce imagine se taie, unde sunt articulațiile și ochii.
Ieșire: art/rigs/<nume>/<parte>.png + rig.json (pivoți și poziții, în pixeli ai imaginii sursă).

Părți: body (corp + picioare), head (cap, cu „interiorul gurii” pictat sub falcă),
head_blink (ochii închiși), jaw (falca de sub mustață), forearm_l / forearm_r (antebrațe de la cot).
Fiecare parte se suprapune câțiva pixeli cu vecina, ca să nu apară găuri când se mișcă.
"""
import json
import os
import sys

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def main(cfg_path):
    cfg = json.load(open(os.path.join(ROOT, cfg_path), encoding="utf-8"))
    src = Image.open(os.path.join(ROOT, cfg["source"])).convert("RGBA")
    W, H = src.size
    name = os.path.splitext(os.path.basename(cfg_path))[0]
    out = os.path.join(ROOT, "art", "rigs", name)
    os.makedirs(out, exist_ok=True)
    px = src.load()

    neck_y = cfg["neck_y"]                  # sub linia asta e corpul
    overlap = cfg.get("overlap", 4)
    jaw = cfg["jaw_rect"]                   # [x0, y0, x1, y1] inclusiv
    elbow_y = cfg["elbow_y"]
    arm_l_max_x = cfg["forearm_l_max_x"]    # antebrațul stâng (din stânga imaginii) = pixeli cu x <= asta, sub cot
    arm_r_min_x = cfg["forearm_r_min_x"]

    def layer(pred):
        im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        p = im.load()
        for y in range(H):
            for x in range(W):
                if px[x, y][3] and pred(x, y):
                    p[x, y] = px[x, y]
        return im

    in_jaw = lambda x, y: jaw[0] <= x <= jaw[2] and jaw[1] <= y <= jaw[3]
    in_fl = lambda x, y: y >= elbow_y and x <= arm_l_max_x
    in_fr = lambda x, y: y >= elbow_y and x >= arm_r_min_x
    keep_fl = lambda x, y: y >= elbow_y + overlap + 2 and x <= arm_l_max_x   # corpul păstrează puțin din mânecă sub cot
    keep_fr = lambda x, y: y >= elbow_y + overlap + 2 and x >= arm_r_min_x

    parts = {
        "head": layer(lambda x, y: y < neck_y and not in_jaw(x, y)),
        "jaw": layer(in_jaw),
        "body": layer(lambda x, y: y >= neck_y - overlap and not keep_fl(x, y) and not keep_fr(x, y)),
        "forearm_l": layer(in_fl),
        "forearm_r": layer(in_fr),
    }
    # interiorul gurii, sub falcă (se vede când falca coboară)
    mouth = tuple(cfg.get("mouth_color", [42, 18, 14]) + [255])
    hp = parts["head"].load()
    for y in range(jaw[1], min(jaw[3], jaw[1] + 4) + 1):
        for x in range(jaw[0] + 2, jaw[2] - 1):
            hp[x, y] = mouth
    # ochi închiși: culoarea pielii de deasupra ochiului, cu o linie mai închisă jos
    blink = parts["head"].copy()
    bp = blink.load()
    for (x0, y0, x1, y1) in cfg["eyes"]:
        cheek = [px[x, y1 + 2] for x in range(x0, x1 + 1)]          # pielea de sub ochi dă culoarea pleoapei
        lid = tuple(sum(c[i] for c in cheek) // len(cheek) for i in range(3)) + (255,)
        lash = (int(lid[0] * 0.45), int(lid[1] * 0.35), int(lid[2] * 0.35), 255)
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                bp[x, y] = lid
        for x in range(x0 + 1, x1):                                   # linia genelor, ușor curbată
            bp[x, (y0 + y1) // 2 + (1 if x in (x0 + 1, x1 - 1) else 0)] = lash
    parts["head_blink"] = blink

    rig = {"source": cfg["source"], "size": [W, H], "pivots": cfg["pivots"], "parts": {}}
    for k, im in parts.items():
        bbox = im.getbbox()
        im.crop(bbox).save(os.path.join(out, k + ".png"))
        rig["parts"][k] = {"file": f"art/rigs/{name}/{k}.png", "origin": [bbox[0], bbox[1]]}
    json.dump(rig, open(os.path.join(out, "rig.json"), "w"), indent=2)
    print("ok:", out, list(parts))


if __name__ == "__main__":
    main(sys.argv[1])

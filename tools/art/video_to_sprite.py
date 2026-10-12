#!/usr/bin/env python3
"""Transformă un video generat (Veo/Sora) al unui personaj pe fundal verde într-o animație pixel-art.

  python3 tools/art/video_to_sprite.py <video.mp4> <nume> [--height 300] [--fps 12] [--min-loop 3]

Pași:
 1. extrage cadrele (ffmpeg) și scoate fundalul verde;
 2. ancorează tălpile în același loc (personajul nu „alunecă” dacă video-ul se mișcă puțin);
 3. aceeași scară și aceeași pânză pentru toate cadrele, apoi pixelizare pe grilă fixă;
 4. stabilizare temporală: pixelii care se schimbă foarte puțin rămân ca în cadrul anterior
    (taie tremuratul de la compresia video, păstrează mișcarea reală);
 5. alege bucla care se leagă cel mai bine (primul și ultimul cadru aproape identice).
Ieșire: art/anim/<nume>/frame_XX.png, sheet.png (toate cadrele pe un rând), anim.json, preview.gif (×3).
"""
import argparse
import glob
import json
import os
import subprocess
import tempfile

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def key_green(rgb):
    """rgb: HxWx3 uint8 -> alfa (0/255). Verde dominant = fundal."""
    r, g, b = [rgb[..., i].astype(np.int16) for i in range(3)]
    bg = (g > 90) & (g > r * 1.25 + 10) & (g > b * 1.25 + 10)
    alpha = np.where(bg, 0, 255).astype(np.uint8)
    # reflex verde pe contur
    spill = (alpha > 0) & (g > r + 12) & (g > b + 12)
    out = rgb.copy()
    out[..., 1] = np.where(spill, ((r + b) // 2).clip(0, 255), g).astype(np.uint8)
    return out, alpha


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("video")
    ap.add_argument("name")
    ap.add_argument("--height", type=int, default=300)
    ap.add_argument("--fps", type=int, default=12)
    ap.add_argument("--min-loop", type=float, default=3.0, help="secunde")
    ap.add_argument("--stab", type=int, default=55, help="prag stabilizare (suma diferențelor RGB)")
    a = ap.parse_args()

    tmp = tempfile.mkdtemp()
    subprocess.check_call(["ffmpeg", "-v", "error", "-i", a.video, "-vf", f"fps={a.fps}", os.path.join(tmp, "f%04d.png")])
    files = sorted(glob.glob(os.path.join(tmp, "*.png")))
    rgbs, alphas, boxes, feet = [], [], [], []
    for f in files:
        rgb = np.array(Image.open(f).convert("RGB"))
        rgb, al = key_green(rgb)
        ys, xs = np.nonzero(al)
        if len(xs) == 0:
            continue
        y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
        band = al[max(y0, y1 - (y1 - y0) // 14): y1 + 1]          # tălpile: ultima bandă de jos
        fx = np.nonzero(band)[1].mean()
        rgbs.append(rgb)
        alphas.append(al)
        boxes.append((x0, y0, x1, y1))
        feet.append((fx, y1))
    n = len(rgbs)
    heights = [b[3] - b[1] for b in boxes]
    scale = a.height / float(np.median(heights))
    # pânză comună în coordonate relative la tălpi
    rel = [(b[0] - f[0], b[1] - f[1], b[2] - f[0], b[3] - f[1]) for b, f in zip(boxes, feet)]
    L = min(r[0] for r in rel) - 4
    T = min(r[1] for r in rel) - 4
    R = max(r[2] for r in rel) + 4
    B = max(r[3] for r in rel) + 2
    cw, ch = int(round((R - L) * scale)), int(round((B - T) * scale))
    frames = []
    for rgb, al, (fx, fy) in zip(rgbs, alphas, feet):
        x0, y0 = int(round(fx + L)), int(round(fy + T))
        x1, y1 = int(round(fx + R)), int(round(fy + B))
        rgba = np.dstack([rgb, al])
        im = Image.fromarray(rgba, "RGBA")
        pad = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
        pad.alpha_composite(im, (-x0, -y0)) if x0 < 0 or y0 < 0 else pad.alpha_composite(im.crop((x0, y0, x1, y1)))
        col = pad.convert("RGB").resize((cw, ch), Image.LANCZOS)
        alp = pad.getchannel("A").resize((cw, ch), Image.LANCZOS).point(lambda v: 255 if v >= 128 else 0)
        frames.append(np.dstack([np.array(col), np.array(alp)]))
    # bucla: perechea (i, j) cu j - i >= min-loop care se leagă cel mai bine
    small = [np.array(Image.fromarray(f, "RGBA").resize((max(1, cw // 4), max(1, ch // 4)))).astype(np.int16) for f in frames]
    need = int(a.min_loop * a.fps)
    best = (1e18, 0, n - 1)
    for i in range(0, max(1, n - need)):
        for j in range(i + need, n):
            dd = np.abs(small[i] - small[j]).mean()
            if dd < best[0]:
                best = (dd, i, j)
    _, i0, i1 = best
    raw = np.stack(frames[i0:i1]).astype(np.int16)
    # stabilizare temporală față de un cadru de referință (mediana buclei): pixelii aproape
    # neschimbați iau exact valoarea de referință, deci nu tremură și bucla se leagă perfect
    ref = np.median(raw, axis=0).astype(np.int16)
    ref_a = np.where(ref[..., 3] >= 128, 255, 0)
    loop = []
    for fr in raw:
        d = np.abs(fr[..., :3] - ref[..., :3]).sum(-1)
        keep = (d < a.stab) & (fr[..., 3] == ref_a) & (fr[..., 3] > 0)
        out_f = fr.copy()
        out_f[keep, :3] = ref[keep, :3]
        loop.append(out_f.clip(0, 255).astype(np.uint8))
    out = os.path.join(ROOT, "art", "anim", a.name)
    os.makedirs(out, exist_ok=True)
    for f in glob.glob(os.path.join(out, "frame_*.png")):
        os.remove(f)
    for k, f in enumerate(loop):
        Image.fromarray(f, "RGBA").save(os.path.join(out, f"frame_{k:02d}.png"))
    sheet = Image.new("RGBA", (cw * len(loop), ch), (0, 0, 0, 0))
    for k, f in enumerate(loop):
        sheet.alpha_composite(Image.fromarray(f, "RGBA"), (k * cw, 0))
    sheet.save(os.path.join(out, "sheet.png"))
    json.dump({"frames": len(loop), "fps": a.fps, "size": [cw, ch], "feet": [int(round(-L * scale)), int(round(-T * scale))],
               "source_video": os.path.basename(a.video), "loop_from_to": [i0, i1], "loop_error": round(float(best[0]), 2)},
              open(os.path.join(out, "anim.json"), "w"), indent=2)
    bg = (42, 42, 51, 255)
    gif = []
    for f in loop:
        c = Image.new("RGBA", (cw, ch), bg)
        c.alpha_composite(Image.fromarray(f, "RGBA"))
        gif.append(c.convert("RGB").resize((cw * 3, ch * 3), Image.NEAREST))
    gif[0].save(os.path.join(out, "preview.gif"), save_all=True, append_images=gif[1:], duration=int(1000 / a.fps), loop=0)
    print(f"ok: {len(loop)} cadre ({len(loop) / a.fps:.1f}s), {cw}x{ch}, bucla {i0}->{i1}, eroare {best[0]:.1f}")


if __name__ == "__main__":
    main()

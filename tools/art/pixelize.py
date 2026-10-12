#!/usr/bin/env python3
"""Aduce o ilustrație la pixel-art adevărat: grilă fixă, pixeli uniformi, paletă nelimitată.

Scene: decupare centrată la 16:9, apoi 640×360.
Personaje/obiecte (cu transparență): redimensionare la înălțimea cerută, margini curate
(alfa doar 0 sau 255), fără netezire pe contur.
"""
import sys
from PIL import Image, ImageEnhance, ImageFilter

# Foile de personaj au toate aceeași scară, ca înălțimile să fie reale între ele: 195 cm = 300 px.
CHAR_PX_PER_CM = 300 / 195


def pixelize_args(spec):
    """Parametrii de pixelizare pentru un fișier art/prompts/<id>.json."""
    if spec.get("pixelize"):
        pix = dict(spec["pixelize"])
    elif spec.get("type") == "scene":
        pix = {"width": 640, "height": 360}
    elif spec.get("height_cm"):
        pix = {"height": round(spec["height_cm"] * CHAR_PX_PER_CM)}
    else:
        pix = {"height": 300}
    if spec.get("manual_key"):
        pix["key"] = spec["manual_key"]
    return pix


def _crop_to(im, w, h):
    tw, th = im.size
    target = w / h
    if tw / th > target:
        nw = round(th * target)
        x = (tw - nw) // 2
        return im.crop((x, 0, x + nw, th))
    nh = round(tw / target)
    y = (th - nh) // 2
    return im.crop((0, y, tw, y + nh))


def key_out(im, key=(0, 255, 0), tol=110):
    """Fundal de culoare plină (green screen) -> transparent, cu reducerea reflexelor verzi pe contur."""
    im = im.convert("RGBA")
    px = im.load()
    kr, kg, kb = key
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if abs(r - kr) + abs(g - kg) + abs(b - kb) < tol:
                px[x, y] = (0, 0, 0, 0)
            elif g > r + 25 and g > b + 25:          # reflex verde pe margine
                px[x, y] = (r, (r + b) // 2, b, a)
    return im


def pixelize(src, dst, width=None, height=None, sharpen=60, key=None):
    im = Image.open(src)
    if key:
        im = key_out(im, tuple(key))
    has_alpha = im.mode in ("RGBA", "LA") or (im.mode == "P" and "transparency" in im.info)
    if width and height:                    # scenele sunt mereu opace
        has_alpha = False
    im = im.convert("RGBA" if has_alpha else "RGB")
    if width and height:
        im = _crop_to(im, width, height)
        size = (width, height)
    else:
        if has_alpha:                       # taie marginile goale înainte de redimensionare
            bbox = im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
            if bbox:
                im = im.crop(bbox)
        h = height or 300
        size = (max(1, round(im.width * h / im.height)), h)
    if has_alpha:
        rgb = im.convert("RGB").resize(size, Image.LANCZOS)
        a = im.getchannel("A").resize(size, Image.LANCZOS).point(lambda v: 255 if v >= 128 else 0)
    else:
        rgb = im.resize(size, Image.LANCZOS)
        a = None
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=1, percent=sharpen, threshold=2))
    rgb = ImageEnhance.Contrast(rgb).enhance(1.04)
    if a is not None:
        rgb.putalpha(a)
    rgb.save(dst)
    return dst


if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    w = int(sys.argv[3]) if len(sys.argv) > 3 else None
    h = int(sys.argv[4]) if len(sys.argv) > 4 else None
    pixelize(src, dst, w, h)

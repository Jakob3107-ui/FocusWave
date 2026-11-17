#!/usr/bin/env python3
"""Render the FocusWave wallpapers (each with a light and a dark version).

Every wallpaper is a Plasma wallpaper package, so Plasma switches to the dark image
automatically when a dark color scheme is active:

  theme/wallpapers/FocusWave-<Name>/metadata.json
  theme/wallpapers/FocusWave-<Name>/contents/images/2560x1600.jpg
  theme/wallpapers/FocusWave-<Name>/contents/images_dark/2560x1600.jpg
  theme/wallpapers/FocusWave-<Name>/contents/screenshot.png        (light thumbnail)
  theme/wallpapers/FocusWave-<Name>/contents/screenshot_dark.png   (dark thumbnail)

Requires numpy + Pillow (only needed when you want to re-render; the images ship in the repo).
Run:  python3 tools/gen_wallpapers.py
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
W, H = 2560, 1600
RNG = np.random.default_rng(7)


def hexrgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32) / 255.0


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def gradient(c_top, c_bottom, c_side=None, angle_mix=0.25):
    y = np.linspace(0, 1, H, dtype=np.float32)[:, None, None]
    x = np.linspace(0, 1, W, dtype=np.float32)[None, :, None]
    img = hexrgb(c_top) * (1 - y) + hexrgb(c_bottom) * y
    if c_side:
        img = img * (1 - angle_mix * x) + hexrgb(c_side) * (angle_mix * x)
    return np.broadcast_to(img, (H, W, 3)).copy()


def over(img, color, alpha):
    a = alpha[..., None]
    img *= (1 - a)
    img += color * a


def wave_curve(base, amps, freqs, phases):
    x = np.linspace(0, 1, W, dtype=np.float32)
    y = np.full_like(x, base * H)
    for a, f, p in zip(amps, freqs, phases):
        y += a * H * np.sin(2 * np.pi * (f * x + p))
    return y


def band(curve, softness=1.5):
    yy = np.arange(H, dtype=np.float32)[:, None]
    return smoothstep(-softness, softness, yy - curve[None, :])


def glow(curve, width):
    yy = np.arange(H, dtype=np.float32)[:, None]
    d = curve[None, :] - yy
    g = np.exp(-np.clip(d, 0, None) / width) * (d > 0)
    return g.astype(np.float32)


def blob(cx, cy, rx, ry):
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    d = ((xx - cx * W) / (rx * W)) ** 2 + ((yy - cy * H) / (ry * H)) ** 2
    return np.exp(-d * 1.6).astype(np.float32)


def finish(img):
    img = img + RNG.normal(0, 1.2 / 255.0, img.shape).astype(np.float32)  # grain against banding
    return Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB")


# --------------------------------------------------------------------------- designs

def wave(dark):
    if dark:
        img = gradient("#0E0B24", "#1E1033", "#140F3A")
        layers = [("#2B2170", 0.55, 0.85), ("#4A35B8", 0.62, 0.8), ("#6E5BFF", 0.70, 0.75), ("#D9559E", 0.80, 0.7)]
    else:
        img = gradient("#EEEAFF", "#FFEDE6", "#E6F0FF")
        layers = [("#D7CEFF", 0.52, 0.75), ("#B6A8FF", 0.60, 0.7), ("#8E7DFF", 0.69, 0.75), ("#FF9EC8", 0.80, 0.7)]
    specs = [((0.05, 0.02), (0.8, 2.1), (0.10, 0.5)),
             ((0.06, 0.018), (0.9, 1.7), (0.35, 0.2)),
             ((0.045, 0.025), (1.1, 2.4), (0.62, 0.8)),
             ((0.04, 0.02), (0.7, 1.9), (0.85, 0.1))]
    for (color, base, alpha), (amps, freqs, phases) in zip(layers, specs):
        c = wave_curve(base, amps, freqs, phases)
        if dark:
            over(img, hexrgb(color), glow(c, 90) * 0.35)
        shade = np.linspace(1.0, 0.82, H, dtype=np.float32)[:, None]
        over(img, hexrgb(color) * (shade[..., None] if dark else 1.0), band(c) * alpha)
    return img


def aurora(dark):
    if dark:
        img = gradient("#06080E", "#0B0D18")
        blobs = [("#0F766E", 0.22, 0.30, 0.35, 0.40, 0.75), ("#3730A3", 0.70, 0.25, 0.40, 0.45, 0.8),
                 ("#6D28D9", 0.55, 0.75, 0.45, 0.40, 0.7), ("#9D174D", 0.15, 0.85, 0.35, 0.30, 0.55)]
    else:
        img = gradient("#F4F6FB", "#F7F3FB")
        blobs = [("#9FE7D3", 0.20, 0.28, 0.38, 0.42, 0.85), ("#9CC8FF", 0.72, 0.22, 0.42, 0.45, 0.85),
                 ("#C9B5FF", 0.58, 0.78, 0.45, 0.42, 0.8), ("#FFD3B8", 0.12, 0.86, 0.35, 0.32, 0.75)]
    for color, cx, cy, rx, ry, a in blobs:
        over(img, hexrgb(color), blob(cx, cy, rx, ry) * a)
    return img


def dune(dark):
    if dark:
        img = gradient("#120E1A", "#2A1B2E")
        hills = ["#3A2438", "#4E2C45", "#6B3654", "#8E4566"]
        img_star = RNG.random((H, W)).astype(np.float32)
        stars = (img_star > 0.9993).astype(np.float32) * np.linspace(1, 0, H, dtype=np.float32)[:, None] * 0.8
        over(img, np.array([1, 1, 1], dtype=np.float32), stars)
    else:
        img = gradient("#FBF1E9", "#F6D9CB")
        hills = ["#F2C1AE", "#E99F88", "#DA8172", "#BE6165"]
    bases = [0.55, 0.64, 0.74, 0.86]
    for i, (color, base) in enumerate(zip(hills, bases)):
        c = wave_curve(base, (0.06, 0.015), (0.55 + 0.1 * i, 1.6), (0.15 * i + 0.1, 0.3 * i))
        over(img, hexrgb(color), band(c, 2.0))
    return img


DESIGNS = {
    "Wave": (wave, "FocusWave Wave"),
    "Aurora": (aurora, "FocusWave Aurora"),
    "Dune": (dune, "FocusWave Dune"),
}


def main():
    for key, (fn, title) in DESIGNS.items():
        pkg = ROOT / "theme" / "wallpapers" / f"FocusWave-{key}"
        (pkg / "contents" / "images").mkdir(parents=True, exist_ok=True)
        (pkg / "contents" / "images_dark").mkdir(parents=True, exist_ok=True)
        for dark in (False, True):
            im = finish(fn(dark))
            sub = "images_dark" if dark else "images"
            im.save(pkg / "contents" / sub / f"{W}x{H}.jpg", quality=92, subsampling=0, optimize=True)
            thumb = im.resize((400, 250), Image.LANCZOS)
            thumb.save(pkg / "contents" / ("screenshot_dark.png" if dark else "screenshot.png"), optimize=True)
        meta = {
            "KPlugin": {
                "Authors": [{"Name": "FocusWave"}],
                "Id": f"FocusWave-{key}",
                "License": "CC-BY-SA-4.0",
                "Name": title,
            }
        }
        (pkg / "metadata.json").write_text(json.dumps(meta, indent=4) + "\n")
        print("rendered", pkg.name)


if __name__ == "__main__":
    main()
